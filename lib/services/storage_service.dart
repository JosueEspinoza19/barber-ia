import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

/// Servicio para manejar la subida de archivos a Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;


  // Funciones de foto de perfil

  Future<String> uploadProfileImage(
      File imageFile, String barberId, String clientId) async {
    try {
      // Esta ruta debe coincidir con tus storage.rules
      final String filePath = 'barbers/$barberId/clients/$clientId/profile.jpg';
      final Reference storageRef = _storage.ref().child(filePath);

      UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Error al subir imagen (StorageService): ${e.message}");
      }
      throw Exception('Error al subir la foto de perfil: ${e.message}');
    }
  }

  Future<void> deleteProfileImage(String barberId, String clientId) async {
    try {
      final String filePath = 'barbers/$barberId/clients/$clientId/profile.jpg';
      final Reference storageRef = _storage.ref().child(filePath);
      await storageRef.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        if (kDebugMode) {
          print("No se encontró imagen de perfil para borrar (normal).");
        }
        return;
      }
      if (kDebugMode) {
        print("Error al borrar imagen de Storage: ${e.message}");
      }
      throw Exception('Error al borrar la foto de perfil: ${e.message}');
    }
  }

  // Sube la imagen de simulación (del historial) y devuelve la URL.
  // La ruta será: barbers/{barberId}/clients/{clientId}/history/{analysisId}.jpg
  Future<String> uploadAnalysisImage({
    required Uint8List imageBytes, // La imagen de la IA viene en bytes
    required String barberId,
    required String clientId,
    required String analysisId, // ID del registro de historial
  }) async {
    try {
      final String filePath =
          'barbers/$barberId/clients/$clientId/history/$analysisId.jpg';
      final Reference storageRef = _storage.ref().child(filePath);

      // Usamos .putData() para subir bytes (Uint8List)
      UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Error al subir imagen de análisis: ${e.message}");
      }
      throw Exception('Error al subir la simulación: ${e.message}');
    }
  }

  // Borra una imagen de simulación del historial.
  Future<void> deleteAnalysisImage({
    required String barberId,
    required String clientId,
    required String analysisId,
  }) async {
    try {
      final String filePath =
          'barbers/$barberId/clients/$clientId/history/$analysisId.jpg';
      final Reference storageRef = _storage.ref().child(filePath);
      await storageRef.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        if (kDebugMode) {
          print("No se encontró imagen de análisis para borrar (normal).");
        }
        return;
      }
      if (kDebugMode) {
        print("Error al borrar imagen de análisis: ${e.message}");
      }
      throw Exception('Error al borrar la simulación: ${e.message}');
    }
  }
}