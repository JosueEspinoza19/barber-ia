import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faceia/models/client_model.dart';
import 'package:faceia/models/analysis_history_model.dart';
import 'package:faceia/models/barber_model.dart';
import 'storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  String? get _userId => _auth.currentUser?.uid;

  // Seccion 1: funciones del barbero / usuario

  Future<void> createInitialBarberData({required String name, required String email}) async {
    final userId = _userId;
    if (userId == null) return;

    await _db.collection('users').doc(userId).set({
      'name': name,
      'email': email,
      'plan': 'Gratuito',
      'image_limit': 5,
      'images_used': 0,
      'photoUrl': null,
      'is_new_user': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeOnboarding() async {
    final userId = _userId;
    if (userId == null) return;
    await _db.collection('users').doc(userId).update({
      'is_new_user': false,
    });
  }

  Stream<BarberModel?> getBarberStream() {
    final userId = _userId;
    if (userId == null) return Stream.value(null);

    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return BarberModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
    });
  }

  Future<void> updateBarberProfile({String? name, File? photoFile}) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");

    Map<String, dynamic> updates = {};

    if (name != null && name.isNotEmpty) {
      updates['name'] = name;
      await _auth.currentUser?.updateDisplayName(name);
    }

    if (photoFile != null) {
      final photoUrl = await _storageService.uploadProfileImage(photoFile, userId, 'profile');
      updates['photoUrl'] = photoUrl;
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).set(updates, SetOptions(merge: true));
    }
  }

  // Actualizar Correo Electrónico
  Future<void> updateBarberEmail(String newEmail, String currentPassword) async {
    final userId = _userId;
    final user = _auth.currentUser;
    if (userId == null || user == null || user.email == null) {
      throw Exception("Usuario no autenticado.");
    }

    try {
      // Reautenticar (Obligatorio para cambios sensibles)
      AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword
      );
      await user.reauthenticateWithCredential(credential);

      // Actualizar en Firebase Auth
      // Usamos updateEmail para cambio inmediato.
      // verifyBeforeUpdateEmail requiere clic en correo.
      await user.verifyBeforeUpdateEmail(newEmail);

      // Actualizar en Firestore para mantener sincronía
      await _db.collection('users').doc(userId).update({'email': newEmail});

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('La contraseña actual es incorrecta.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Este correo ya está en uso por otra cuenta.');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Por seguridad, cierra sesión e inicia de nuevo.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo no es válido.');
      }
      throw Exception('Error al actualizar correo: ${e.message}');
    } catch (e) {
      throw Exception('Error desconocido al actualizar el correo.');
    }
  }

  Future<void> updateSubscriptionPlan(String newPlan) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");

    int newLimit = 5;
    switch (newPlan) {
      case 'Básico': newLimit = 50; break;
      case 'Pro': newLimit = 200; break;
      case 'Premium': newLimit = 999999; break;
      default: newLimit = 5;
    }

    await _db.collection('users').doc(userId).set({
      'plan': newPlan,
      'image_limit': newLimit,
      'images_used': 0,
    }, SetOptions(merge: true));
  }

  Future<bool> checkQuota() async {
    final userId = _userId;
    if (userId == null) return false;

    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return true;

    final data = doc.data() as Map<String, dynamic>;
    final int used = data['images_used'] ?? 0;
    final int limit = data['image_limit'] ?? 5;

    return used < limit;
  }

  Future<void> incrementImageUsage() async {
    final userId = _userId;
    if (userId == null) return;

    await _db.collection('users').doc(userId).set({
      'images_used': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Seccion 2: funciones de clientes

  CollectionReference get _clientsCollection {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    return _db.collection('barbers').doc(userId).collection('clients');
  }

  Future<void> addClient(Client client, File? imageFile) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    try {
      final clientDocRef = _clientsCollection.doc();
      client.id = clientDocRef.id;
      if (imageFile != null) {
        final imageUrl = await _storageService.uploadProfileImage(imageFile, userId, client.id);
        client.imageUrl = imageUrl;
      }
      await clientDocRef.set(client.toJson());
    } catch (e) {
      throw Exception("No se pudo guardar el cliente.");
    }
  }

  Stream<List<Client>> getClients() {
    return _clientsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
    });
  }

  Future<void> addNoteToClient(String clientId, String newNote) async {
    if (newNote.isEmpty) return;
    await _clientsCollection.doc(clientId).update({
      'notes': FieldValue.arrayUnion([newNote])
    });
  }

  Future<void> updateClient(Client client, File? newImageFile) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    if (newImageFile != null) {
      final imageUrl = await _storageService.uploadProfileImage(newImageFile, userId, client.id);
      client.imageUrl = imageUrl;
    }
    await _clientsCollection.doc(client.id).update(client.toJson());
  }

  Future<void> deleteClient(String clientId) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    try {
      await _storageService.deleteProfileImage(userId, clientId);
    } catch (e) { print("Error borrar imagen storage: $e"); }
    await _clientsCollection.doc(clientId).delete();
  }

  // Seccion 3: historial y analisis

  Future<void> saveAnalysisToHistory({required String clientId, required String suggestionText, required Uint8List imageBytes, required File originalImageFile,}) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    try {
      final historyDocRef = _clientsCollection.doc(clientId).collection('history').doc();
      final analysisId = historyDocRef.id;
      final String imageUrl = await _storageService.uploadAnalysisImage(
        imageBytes: imageBytes, barberId: userId, clientId: clientId, analysisId: analysisId,
      );
      // Subir imagen Original
      final String originalImageUrl = await _storageService.uploadProfileImage(
          originalImageFile, userId, '${clientId}_history_${analysisId}_original'
      );
      AnalysisHistory historyItem = AnalysisHistory(
        id: analysisId, suggestionText: suggestionText, analysisImageUrl: imageUrl, originalImageUrl: originalImageUrl, createdAt: Timestamp.now(),
      );
      await historyDocRef.set(historyItem.toJson());
      await _clientsCollection.doc(clientId).update({'lastAnalysis': Timestamp.now()});
    } catch (e) {
      throw Exception("No se pudo guardar el análisis.");
    }
  }

  Stream<List<AnalysisHistory>> getAnalysisHistory(String clientId) {
    if (_userId == null) return Stream.value([]);
    return _clientsCollection.doc(clientId).collection('history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AnalysisHistory.fromFirestore(doc)).toList());
  }

  Future<void> deleteAnalysisFromHistory({required String clientId, required AnalysisHistory historyItem}) async {
    final userId = _userId;
    if (userId == null) throw Exception("Usuario no autenticado.");
    try {
      await _storageService.deleteAnalysisImage(barberId: userId, clientId: clientId, analysisId: historyItem.id);
    } catch (e) { print("Error al borrar imagen de historial: $e"); }
    try {
      await _clientsCollection.doc(clientId).collection('history').doc(historyItem.id).delete();
    } catch (e) {
      throw Exception("No se pudo borrar el historial.");
    }
  }
}