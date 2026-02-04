import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'results_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../../services/firestore_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String? clientId;

  AnalysisScreen({super.key, this.clientId});

  final Color _primaryColor = Colors.blue.shade800;
  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = Colors.grey.shade900;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with WidgetsBindingObserver {
  final Color _primaryColor = Colors.blue.shade800;
  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = Colors.grey.shade900;
  //Variables de Cámara
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  //Variables de Estado
  bool _isLoading = false;
  File? _previewImage;
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Buscar frontal por defecto
        int newCameraIndex = _cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        if (newCameraIndex != -1) _selectedCameraIndex = newCameraIndex;
        _startCamera(_cameras![_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint("Error al inicializar cámara: $e");
    }
  }

  Future<void> _startCamera(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );
    _cameraController = cameraController;
    try {
      await cameraController.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Error al iniciar controlador: $e");
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    int newIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _selectedCameraIndex = newIndex;
    _startCamera(_cameras![newIndex]);
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      final XFile picture = await _cameraController!.takePicture();
      setState(() => _previewImage = File(picture.path));
      _checkQuotaAndAlert();
    } catch (e) {
      debugPrint("Error al tomar foto: $e");
    }
  }

  static Future<Uint8List> _resizeImageTask(Uint8List imageBytes) async {
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return imageBytes;
    img.Image resizedImage;
    if (originalImage.width > 1024) {
      resizedImage = img.copyResize(originalImage, width: 1024, interpolation: img.Interpolation.average);
    } else {
      resizedImage = originalImage;
    }
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  // ANÁLISIS
  Future<Map<String, dynamic>> _getRealAnalysis(File imageFile) async {
    final functions = FirebaseFunctions.instanceFor(region: "us-central1");
    final callable = functions.httpsCallable(
      'analyzeFace',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    // Preparamos la imagen
    final Uint8List originalImageBytes = await imageFile.readAsBytes();
    final Uint8List resizedImageBytes = await compute(_resizeImageTask, originalImageBytes);
    final String imageBase64 = base64Encode(resizedImageBytes);

    int attempts = 0;
    while (attempts < 19) {
      try {
        attempts++;
        final response = await callable.call<Map<String, dynamic>>({'image': imageBase64});
        return response.data;
      } on FirebaseFunctionsException catch (e) {
        if (attempts == 20) throw Exception("Error de la nube: ${e.message}");
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        if (attempts == 20) throw Exception("Error al procesar.");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("Error desconocido.");
  }

  Future<bool> _checkQuotaAndAlert() async {
    final barberStream = _firestoreService.getBarberStream();
    final barber = await barberStream.first;
    if (barber == null) return false;

    int remaining = barber.imageLimit - barber.imagesUsed;
    if (remaining <= 0) {
      if (mounted) _showNoQuotaDialog();
      return false;
    }
    double percentageLeft = remaining / barber.imageLimit;
    if (percentageLeft <= 0.1 || remaining == 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Atención: Te quedan solo $remaining análisis.'), backgroundColor: Colors.orange[800], duration: const Duration(seconds: 5),),
        );
      }
    }
    return true;
  }

  void _showNoQuotaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Límite Alcanzado!'),
        content: const Text('Has usado todos los análisis de tu plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget._primaryColor),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ver Planes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startAnalysis() async {
    if (_previewImage == null) return;
    bool canProceed = await _checkQuotaAndAlert();
    if (!canProceed) return;

    setState(() => _isLoading = true);

    try {
      final results = await _getRealAnalysis(_previewImage!);
      if (!mounted) return;

      final String simulatedBase64 = results['simulatedImageBase64'];
      final Uint8List simulatedImageBytes = base64Decode(simulatedBase64);

      await _firestoreService.incrementImageUsage();

      final dynamic result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            originalImage: _previewImage!,
            simulatedImageBytes: simulatedImageBytes,
            suggestionText: results['suggestionText'],
            clientId: widget.clientId,
          ),
        ),
      );

      if (result == true) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _startAnalysis();
      } else if (result == 'saved' && widget.clientId != null) {
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _previewImage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
        setState(() => _isLoading = false);
      }
    }
  }

  void _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _previewImage = File(pickedFile.path));
      _checkQuotaAndAlert();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isClientAnalysis = widget.clientId != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: 'Barber',
            style: GoogleFonts.leagueSpartan(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'IA',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : (_previewImage != null ? _buildCapturedPreviewState() : _buildLiveCameraState(isClientAnalysis)),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[50],
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget._primaryColor),
          const SizedBox(height: 25),
          Text(
            'Analizando y generando...\nEsto puede tardar unos segundos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: widget._textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCameraState(bool isClientAnalysis) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // 1. CALCULAR ESCALA PARA CUBRIR PANTALLA (SOLUCIÓN ZOOM)
    // La cámara tiene un aspect ratio (ej 4:3), la pantalla otro (ej 20:9).
    // Para que se vea "full screen" sin bordes negros, tenemos que escalar.
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cámara con Transform para corregir el "zoom"
        Transform.scale(
          scale: scale,
          child: Center(
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Óvalo Guía
        Container(decoration: ShapeDecoration(shape: _OvalOverlayBorder())),

        const Positioned(
          top: 20, left: 0, right: 0,
          child: Text("Centra el rostro en el óvalo", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black)])),
        ),

        Positioned(
          bottom: 30, left: 0, right: 0,
          child: Column(
            children: [
              if (!isClientAnalysis)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text("Análisis Rápido (No se guarda)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.photo_library, color: Colors.white, size: 30), onPressed: _pickImageFromGallery),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: widget._accentColor, width: 4)),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30), onPressed: _switchCamera),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedPreviewState() {
    // 2. CORREGIR EL EFECTO ESPEJO
    // Si es cámara frontal, invertimos la imagen horizontalmente para que se vea natural.
    final bool isFrontCamera = _cameras != null &&
        _cameras!.isNotEmpty &&
        _cameras![_selectedCameraIndex].lensDirection == CameraLensDirection.front;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Aplicamos la transformación aquí
                Transform(
                  alignment: Alignment.center,
                  transform: isFrontCamera
                      ? Matrix4.rotationY(math.pi) // Voltear horizontalmente
                      : Matrix4.identity(),        // Dejar normal
                  child: Image.file(_previewImage!, fit: BoxFit.contain),
                ),
                Container(decoration: ShapeDecoration(shape: _OvalOverlayBorder(borderColor: Colors.white.withOpacity(0.3)))),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _previewImage = null),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50),side: const BorderSide(color: Colors.black, width: 2))),
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: const Text("Repetir", style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton.icon(
                  onPressed: _startAnalysis,
                  style: ElevatedButton.styleFrom(backgroundColor: widget._accentColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Analizar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OvalOverlayBorder extends ShapeBorder {
  final Color borderColor;
  _OvalOverlayBorder({this.borderColor = Colors.white});
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect)..addOval(Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.55))..fillType = PathFillType.evenOdd;
  }
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawPath(getOuterPath(rect), paint);
    final Paint borderPaint = Paint()..color = borderColor.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawOval(Rect.fromCenter(center: rect.center, width: rect.width * 0.75, height: rect.height * 0.55), borderPaint);
  }
  @override
  ShapeBorder scale(double t) => this;
}