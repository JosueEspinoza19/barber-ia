import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instancia de Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inicia sesión con correo y contraseña.
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Registra un nuevo usuario con correo, contraseña y nombre.
  Future<void> signUp(String email, String password, String name) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    // Actualizar el nombre
    await userCredential.user?.updateDisplayName(name);
  }

  // Envía un correo electrónico para restablecer la contraseña.
  Future<void> recoverPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Traduce los códigos de error comunes de Firebase a mensajes legibles.
  String getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'email-already-in-use':
        return 'El correo ya está registrado. Intenta iniciar sesión.';
      case 'user-not-found':
        return 'Usuario no encontrado. Verifica tu correo.';
      case 'user-disabled':
        return 'Esta cuenta de usuario ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Se ha bloqueado el acceso por actividad inusual. Intenta más tarde.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu acceso a internet.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos. Por favor, verifica tus datos.';
      default:
        return 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.';
    }
  }

  // Stream para escuchar cambios en el estado de autenticación (opcional, pero útil)
  Stream<User?> get userChanges => _auth.authStateChanges();
}
