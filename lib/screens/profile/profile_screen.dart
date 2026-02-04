import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'plans_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/barber_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color _primaryColor = const Color(0xFF1565C0);
  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = const Color(0xFF212121);

  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Lógica para subir imagen de perfil
  Future<void> _uploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      await _firestoreService.updateBarberProfile(photoFile: File(image.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Lógica para editar nombre
  Future<void> _editName(String currentName) async {
    final TextEditingController _nameController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modificar Nombre'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nombre del Barbero'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await _firestoreService.updateBarberProfile(name: _nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Lógica para Cambiar Correo
  Future<void> _changeEmail() async {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por seguridad, ingresa tu nuevo correo y tu contraseña actual.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Nuevo Correo', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña Actual', border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                final newEmail = _emailController.text.trim();
                final password = _passwordController.text;

                Navigator.pop(context);

                try {
                  await _firestoreService.updateBarberEmail(newEmail, password);

                  // Usamos la variable capturada 'scaffoldMessenger'
                  scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Se ha enviado un correo a $newEmail para verificar el cambio de correo.'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 5),
                      )
                  );
                } catch (e) {
                  // Usamos la variable capturada
                  scaffoldMessenger.showSnackBar(
                      SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red
                      )
                  );
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // Lógica para cambiar contraseña
  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se ha enviado un correo a $email para restablecer tu contraseña.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar correo.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Cerrar Sesión
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BarberModel?>(
      stream: _firestoreService.getBarberStream(),
      builder: (context, snapshot) {

        String userName = 'Cargando...';
        String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
        String? photoUrl;
        String planName = 'Gratuito';
        int imagesUsed = 0;
        int imagesLimit = 5;

        if (snapshot.hasData && snapshot.data != null) {
          final barber = snapshot.data!;
          userName = barber.name;
          photoUrl = barber.photoUrl;
          planName = barber.plan;
          imagesUsed = barber.imagesUsed;
          imagesLimit = barber.imageLimit;
          if (barber.email.isNotEmpty) userEmail = barber.email;
        } else if (snapshot.connectionState == ConnectionState.active && snapshot.data == null) {
          userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Usuario';
        }

        final int imagesRemaining = imagesLimit - imagesUsed;
        double progress = (imagesLimit > 0) ? (imagesUsed / imagesLimit) : 1.0;
        if (progress > 1.0) progress = 1.0;
        final bool isLimitReached = imagesRemaining <= 0;

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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _primaryColor),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadProfileImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: _accentColor,
                          child: _isUploading
                              ? const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
                ),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _editName(userName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    side: BorderSide(color: _primaryColor),
                  ),
                  child: const Text('Modificar Nombre'),
                ),

                const SizedBox(height: 32),

                // Tarjeta de Plan y Consumo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plan Actual: $planName',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLimitReached ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isLimitReached ? 'Agotado' : 'Activo',
                              style: TextStyle(
                                color: isLimitReached ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Imágenes usadas', style: TextStyle(color: Colors.grey[600])),
                          Text(
                            '$imagesUsed / $imagesLimit',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: isLimitReached ? Colors.redAccent : _accentColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isLimitReached
                            ? '¡Has alcanzado el límite de tu plan!'
                            : 'Te quedan $imagesRemaining análisis disponibles.',
                        style: TextStyle(
                          color: isLimitReached ? Colors.redAccent : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: isLimitReached ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PlansScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLimitReached ? Colors.redAccent : _accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isLimitReached ? 'Adquirir más imágenes' : 'Cambiar mi plan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                //Opciones de Cuenta
                _buildOptionItem(
                  icon: Icons.email_outlined,
                  title: 'Cambiar Correo Electrónico',
                  onTap: _changeEmail, // <-- ¡CONECTADO!
                ),
                _buildOptionItem(
                  icon: Icons.lock_outline,
                  title: 'Cambiar Contraseña',
                  onTap: () => _resetPassword(userEmail),
                ),
                _buildOptionItem(
                  icon: Icons.help_outline,
                  title: 'Ayuda y Soporte',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacta a soporte@barberia.com')));
                  },
                ),

                const SizedBox(height: 24),

                // Cerrar Sesión
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _signOut(),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: _textColor),
      title: Text(title, style: TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}