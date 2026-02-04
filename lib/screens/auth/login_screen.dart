import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/logo_widget.dart';

// Type alias para la función de cambio de modo
typedef VoidCallback = void Function();

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleMode;
  final VoidCallback onGoToRegister;
  final AuthService authService;

  const LoginScreen({
    super.key,
    required this.onToggleMode,
    required this.onGoToRegister,
    required this.authService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  //Paleta de Colores
  final Color _primaryColor = Colors.blue.shade800;
  final Color _textColor = Colors.grey.shade900;
  final Color _hintColor = Colors.grey.shade500;
  final Color _accentColor = const Color(0xFF1579AF);

  //Valida y envía el formulario de inicio de sesión.
  void _submitLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    try {
      //El auth_service se encarga de la lógica y el stream navegará a Home
      await widget.authService.signIn(_email, _password);
    } on FirebaseAuthException catch (e) {
      //Obtenemos un mensaje de error para el usuario.
      String message = widget.authService.getFriendlyErrorMessage(e.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //Muestra un diálogo para que el usuario ingrese su correo y recupere su contraseña
  void _recoverPassword() async {
    final recoverEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        title: Text('Recuperar Contraseña', style: TextStyle(color: _textColor)),
        content: TextField(
          controller: recoverEmailController,
          keyboardType: TextInputType.emailAddress,
          cursorColor: _textColor,
          decoration: InputDecoration(
            labelText: 'Correo Electrónico',
            floatingLabelStyle: const TextStyle(color: Colors.black),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: _accentColor, width: 2),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancelar', style: TextStyle(color: _textColor)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final email = recoverEmailController.text.trim();
              if (email.isEmpty) return;

              try {
                await widget.authService.recoverPassword(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Revisa tu correo para restablecer la contraseña.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } on FirebaseAuthException {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: No se pudo enviar el correo de recuperación.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  //Widget que construye el logo de la aplicación.


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
            //Logo de la App
            const LogoWidget(),
            const SizedBox(height: 40),

            //Título de la pantalla
            Text(
              'Iniciar Sesión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),

            //Campo Correo Electrónico
            _buildTextField(
              label: 'Correo Electrónico',
              hint: 'correo@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un correo válido.';
                }
                final RegExp emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value)) {
                  return 'Ingresa un correo válido.';
                }
                return null;
              },
              onSaved: (value) => _email = value ?? '',
            ),
            const SizedBox(height: 20),

            //Campo Contraseña
            _buildTextField(
              label: 'Contraseña',
              hint: 'Contraseña',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'Debe tener mínimo 6 caracteres.';
                }
                return null;
              },
              onSaved: (value) => _password = value ?? '',
            ),
            const SizedBox(height: 25),

            //Botón de Entrar
            _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: _submitLogin,
              child: const Text(
                'Entrar',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 25),

            //Enlace para Recuperar Contraseña
            _buildLink(
              text: '¿Olvidaste tu contraseña? ',
              linkText: 'Recuperar contraseña',
              onTap: _recoverPassword,
            ),
            const SizedBox(height: 20),

            //Enlace para ir a la pantalla de Registro
            _buildLink(
              text: '¿No tienes cuenta? ',
              linkText: 'Regístrate',
              onTap: widget.onGoToRegister,
            ),
          ],
        ),
      ),
    );
  }

  // Widget reutilizable para los campos de texto del formulario
  Widget _buildTextField({
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
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
              borderSide: const BorderSide(color: Colors.grey, width: 1),
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

  // Widget reutilizable para los enlaces de texto
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

