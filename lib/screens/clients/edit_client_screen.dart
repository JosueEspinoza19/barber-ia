import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/client_model.dart';
import '../../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditClientScreen extends StatefulWidget {
  final Client client; // Recibe el cliente a editar

  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {

  final Color _primaryColor = Colors.blue.shade800;
  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = Colors.grey.shade900;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  File? _newProfileImageFile;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Prellenamos los campos con los datos del cliente
    _nameController = TextEditingController(text: widget.client.name);
    _phoneController = TextEditingController(text: widget.client.phone);
    _emailController = TextEditingController(text: widget.client.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Muestra el selector de imagen (Cámara o Galería)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (pickedFile != null) {
        setState(() {
          _newProfileImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al seleccionar la imagen: ${e.toString()}')),
        );
      }
    }
  }

  // Llama al servicio para actualizar el cliente en Firestore.
  Future<void> _updateClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Actualiza el objeto 'client' local con los nuevos datos
      // (Mantenemos el mismo ID y la lista de notas)
      Client updatedClient = Client(
        id: widget.client.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        imageUrl: widget.client.imageUrl, // Mantenemos la URL antigua por defecto
        notes: widget.client.notes,
        lastAnalysis: widget.client.lastAnalysis,
      );

      // Llama al servicio (que subirá la nueva foto si existe)
      await _firestoreService.updateClient(updatedClient, _newProfileImageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        // Regresa a la pantalla de detalle (pasando el cliente actualizado)
        Navigator.of(context).pop(updatedClient);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el cliente: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Editar Cliente',
          style: GoogleFonts.leagueSpartan(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de Imagen (prellenado)
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Campo Nombre (Obligatorio)
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration(
                    label: 'Nombre Completo', icon: Icons.person),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Teléfono (Opcional)
              TextFormField(
                controller: _phoneController,
                decoration: _buildInputDecoration(
                    label: 'Teléfono (Opcional)', icon: Icons.phone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Campo Correo (Opcional)
              TextFormField(
                controller: _emailController,
                decoration: _buildInputDecoration(
                    label: 'Correo (Opcional)', icon: Icons.email),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              // Botón de Guardar Cambios
              ElevatedButton.icon(
                icon: const Icon(Icons.save_as, color: Colors.white),
                label: const Text(
                  'Guardar Cambios',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _isLoading ? null : _updateClient,
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para el selector de foto
  Widget _buildImagePicker() {
    // Determina qué imagen mostrar: la nueva, la antigua, o el placeholder
    ImageProvider? backgroundImage;
    if (_newProfileImageFile != null) {
      backgroundImage = FileImage(_newProfileImageFile!);
    } else if (widget.client.imageUrl != null &&
        widget.client.imageUrl!.isNotEmpty) {
      backgroundImage = CachedNetworkImageProvider(widget.client.imageUrl!);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: backgroundImage,
          child: (backgroundImage == null)
              ? Icon(
            Icons.person,
            size: 60,
            color: Colors.grey[400],
          )
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: Icon(Icons.camera_alt, color: _accentColor),
              label: Text('Cámara', style: TextStyle(color: _accentColor)),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            TextButton.icon(
              icon: Icon(Icons.photo_library, color: _accentColor),
              label: Text('Galería', style: TextStyle(color: _accentColor)),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }

  // Widget reutilizable para la decoración de los inputs
  InputDecoration _buildInputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
    );
  }
}