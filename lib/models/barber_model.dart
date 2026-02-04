class BarberModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String plan;
  final int imagesUsed;
  final int imageLimit;
  final bool isNewUser;

  BarberModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.plan,
    required this.imagesUsed,
    required this.imageLimit,
    this.isNewUser = false,
  });

  // Convierte un documento de Firestore en un objeto BarberModel
  factory BarberModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BarberModel(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Usuario Face IA',
      photoUrl: data['photoUrl'],
      plan: data['plan'] ?? 'Gratuito',
      imagesUsed: (data['images_used'] ?? 0) as int,
      imageLimit: (data['image_limit'] ?? 5) as int,
      isNewUser: data['is_new_user'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'plan': plan,
      'images_used': imagesUsed,
      'image_limit': imageLimit,
      'is_new_user': isNewUser,
    };
  }

  BarberModel copyWith({
    String? name,
    String? photoUrl,
    String? plan,
    int? imagesUsed,
    int? imageLimit,
    bool? isNewUser,
  }) {
    return BarberModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      plan: plan ?? this.plan,
      imagesUsed: imagesUsed ?? this.imagesUsed,
      imageLimit: imageLimit ?? this.imageLimit,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}