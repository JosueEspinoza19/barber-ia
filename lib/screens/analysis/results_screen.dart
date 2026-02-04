import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'full_screen_image_screen.dart';
import '../../services/firestore_service.dart';

class ResultsScreen extends StatefulWidget {
  final File originalImage;
  final Uint8List simulatedImageBytes;
  final String suggestionText;

  // Si es nulo, es un análisis rápido.
  // Si tiene valor, es un análisis de cliente.
  final String? clientId;

  final Color _primaryColor = Colors.blue.shade800;
  final Color _textColor = Colors.grey.shade900;
  final Color _accentColor = const Color(0xFF1579AF);

  ResultsScreen({
    super.key,
    required this.originalImage,
    required this.simulatedImageBytes,
    required this.suggestionText,
    this.clientId, // <-- Constructor actualizado
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {

  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  // Llama al servicio para guardar el análisis en el historial
  Future<void> _saveAnalysis() async {
    // Esta función solo debería ser llamada si clientId no es nulo
    if (widget.clientId == null) return;

    setState(() => _isSaving = true);

    try {
      await _firestoreService.saveAnalysisToHistory(
        clientId: widget.clientId!,
        suggestionText: widget.suggestionText,
        imageBytes: widget.simulatedImageBytes,
        originalImageFile: widget.originalImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Análisis guardado en el historial del cliente.'),
            backgroundColor: Colors.green,
          ),
        );
        // Regresa a la pantalla de análisis (con 'false' para no regenerar)
        Navigator.of(context).pop('saved');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el análisis: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    // Determina si es un análisis de cliente (para mostrar el botón de guardar)
    final bool isClientAnalysis = widget.clientId != null;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: 'Barber',
            style: GoogleFonts.leagueSpartan(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'IA',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: widget._accentColor,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        // Oculta la flecha de "atrás" si está guardando
        automaticallyImplyLeading: !_isSaving,
        iconTheme: IconThemeData(color: widget._textColor),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resultado del Análisis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget._textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageCard(
                    context,
                    label: 'Original',
                    imageFile: widget.originalImage,
                    heroTag: 'original-image',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageCard(
                    context,
                    label: 'Sugerencia',
                    imageBytes: widget.simulatedImageBytes,
                    heroTag: 'simulated-image',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildSuggestionCard(),
            const SizedBox(height: 25),

            if (_isSaving)
            // Muestra un spinner si está guardando
              const Center(child: CircularProgressIndicator())
            else ...[
              // Si es análisis de cliente, muestra el botón "Guardar"
              if (isClientAnalysis)
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar y Añadir al Perfil',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget._primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _saveAnalysis,
                ),

              // Si es análisis rapido, muestra un botón para "Salir"
              if (!isClientAnalysis)
                ElevatedButton(
                  child: const Text(
                    'Finalizar Análisis Rápido',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget._primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () {
                    // Regresa a la pantalla de análisis (con 'false' para no regenerar)
                    Navigator.of(context).pop(false);
                  },
                ),

              const SizedBox(height: 15),
              // Botón de "Generar nuevo estilo"
              OutlinedButton.icon(
                icon: Icon(Icons.auto_awesome, color: widget._accentColor),
                label: Text(
                  'Generar nuevo estilo',
                  style: TextStyle(
                      fontSize: 16,
                      color: widget._accentColor,
                      fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: widget._accentColor, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: () {
                  // Regresa 'true' para que analysis_screen sepa que debe regenerar
                  Navigator.of(context).pop(true);
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Widget para mostrar la tarjeta de imagen
  Widget _buildImageCard(
      BuildContext context, {
        required String label,
        File? imageFile,
        Uint8List? imageBytes,
        required String heroTag,
      }) {
    final Widget imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(
        imageFile,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
      );
    } else if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
      );
    } else {
      imageWidget = Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: widget._textColor),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageScreen(
                    imageFile: imageFile,
                    imageBytes: imageBytes,
                    heroTag: heroTag,
                  ),
                ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Hero(
              tag: heroTag,
              child: imageWidget,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para la tarjeta de sugerencia
  Widget _buildSuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: widget._accentColor, size: 28),
              const SizedBox(width: 10),
              Text(
                'Sugerencia de la IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget._textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.suggestionText,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }
}