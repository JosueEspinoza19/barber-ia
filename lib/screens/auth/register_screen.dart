import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart'; // <-- ¡NUEVO!
import '../../widgets/logo_widget.dart';

// Type alias para la función de cambio de modo
typedef VoidCallback = void Function();

class RegisterScreen extends StatefulWidget {
  final VoidCallback onGoToLogin;
  final AuthService authService;

  const RegisterScreen({
    super.key,
    required this.onGoToLogin,
    required this.authService,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  // Instancia de Firestore Service
  final FirestoreService _firestoreService = FirestoreService(); // <-- ¡NUEVO!

  String _email = '';
  String _password = '';
  String _name = '';
  bool _isLoading = false;

  final Color _primaryColor = Colors.blue.shade800;
  final Color _textColor = Colors.grey.shade900;
  final Color _hintColor = Colors.grey.shade500;
  final Color _accentColor = const Color(0xFF1579AF);

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    try {
      // Crear usuario en Auth (Authentication)
      await widget.authService.signUp(_email, _password, _name);

      // Crear documento inicial en Firestore (Database)
      // Esto asegura que el usuario tenga el plan Gratuito asignado
      await _firestoreService.createInitialBarberData(
          name: _name,
          email: _email
      );

      // El stream de Firebase en main.dart navegará automáticamente al Home
    } on FirebaseAuthException catch (e) {
      String message = widget.authService.getFriendlyErrorMessage(e.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Captura errores de Firestore u otros
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al crear perfil: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const LogoWidget(),
            const SizedBox(height: 40),
            Text(
              'Registrarse',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 25),

            _buildTextField(
              label: 'Nombre',
              hint: 'Tu nombre completo',
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 4) {
                  return 'Ingresa un nombre válido (mín. 4 caracteres).';
                }
                return null;
              },
              onSaved: (value) => _name = value ?? '',
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'Correo Electrónico',
              hint: 'correo@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Ingresa un correo válido.';
                }
                return null;
              },
              onSaved: (value) => _email = value ?? '',
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'Contraseña',
              hint: 'Contraseña segura',
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'La contraseña debe tener mínimo 6 caracteres.';
                }
                return null;
              },
              onSaved: (value) => _password = value ?? '',
            ),
            const SizedBox(height: 15),

            _buildTextField(
              label: 'Confirmar Contraseña',
              hint: 'Repite tu contraseña',
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }
                return null;
              },
              onSaved: (_) {},
            ),
            const SizedBox(height: 25),

            _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: _submitRegister,
              child: const Text(
                'Crear Cuenta',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 25),

            _buildLink(
              text: '¿Ya tienes una cuenta? ',
              linkText: 'Iniciar Sesión',
              onTap: widget.onGoToLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _hintColor),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: _accentColor, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildLink({
    required String text,
    required String linkText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: text,
          style: TextStyle(color: _textColor, fontSize: 14),
          children: [
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}