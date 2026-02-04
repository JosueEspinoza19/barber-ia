import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  String id;
  String name;
  String phone;
  String email;
  String? imageUrl;
  DateTime? lastAnalysis;
  List<String> notes;

  Client({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.imageUrl,
    this.lastAnalysis,
    this.notes = const [],
  });

  // Convierte un objeto Client a un mapa JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'lastAnalysis': lastAnalysis != null
          ? Timestamp.fromDate(lastAnalysis!)
          : null,
      'notes': notes,
    };
  }

  // Crea un objeto Client desde un DocumentSnapshot de Firestore
  factory Client.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageUrl: data['imageUrl'], // <-- ¡NUEVO!
      lastAnalysis: (data['lastAnalysis'] as Timestamp?)?.toDate(),
      notes: List<String>.from(data['notes'] ?? []),
    );
  }
}