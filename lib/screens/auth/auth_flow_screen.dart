import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';

//Enum para manejar el estado de la UI
enum AuthMode { login, register }

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  // Instancia única del servicio de autenticación
  final AuthService _authService = AuthService();

  //Estado para determinar qué formulario mostrar
  AuthMode _authMode = AuthMode.login;

  void _goToLogin() {
    setState(() {
      _authMode = AuthMode.login;
    });
  }

  void _goToRegister() {
    setState(() {
      _authMode = AuthMode.register;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Muestra la pantalla de Login o Registro
                if (_authMode == AuthMode.login)
                  LoginScreen(
                    authService: _authService,
                    onGoToRegister: _goToRegister,
                    onToggleMode: _goToRegister,
                  )
                else
                  RegisterScreen(
                    authService: _authService,
                    onGoToLogin: _goToLogin,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
