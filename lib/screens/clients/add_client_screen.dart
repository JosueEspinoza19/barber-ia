import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/client_model.dart';
import '../../services/firestore_service.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  // Paleta de colores
  final Color _primaryColor = Colors.blue.shade800;
  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = Colors.grey.shade900;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

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
        imageQuality: 80, // Comprime la imagen
        maxWidth: 600, // Redimensiona para ahorrar espacio
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
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

  // Llama al servicio para guardar el cliente en Firestore.
  Future<void> _saveClient() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hace nada.
    }

    setState(() => _isLoading = true);

    try {
      // Crear el objeto Cliente con los datos del formulario
      Client newClient = Client(
        id: '', // Firestore la genera, FirestoreService la ignora
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        notes: [], // Lista vacía al crear
        // imageUrl se añadirá en el servicio si _profileImage no es nulo
      );

      // Llamar al servicio
      await _firestoreService.addClient(newClient, _profileImage);

      // Mostrar éxito y regresar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente guardado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Regresa a la lista de clientes
      }
    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el cliente: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // Detener la carga
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
        iconTheme: IconThemeData(color: _textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Añadir Nuevo Cliente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 24),

              // Selector de Imagen
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

              // Botón de Guardar
              ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Guardar Cliente',
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
                // Deshabilita el botón si está cargando
                onPressed: _isLoading ? null : _saveClient,
              ),
              // Muestra un indicador de carga si está guardando
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

  // Widget para el selector de foto
  Widget _buildImagePicker() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          // Muestra la imagen seleccionada
          backgroundImage:
          _profileImage != null ? FileImage(_profileImage!) : null,
          // Muestra un ícono si no hay imagen
          child: _profileImage == null
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