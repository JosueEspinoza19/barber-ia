import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para un solo registro en el historial de análisis de un cliente.
class AnalysisHistory {
  String id;
  String suggestionText;
  String analysisImageUrl; // URL de la imagen de simulación en Storage
  String? originalImageUrl;
  Timestamp createdAt;

  AnalysisHistory({
    required this.id,
    required this.suggestionText,
    required this.analysisImageUrl,
    this.originalImageUrl,
    required this.createdAt,
  });

  // Convierte un objeto AnalysisHistory en un Map (para Firestore)
  Map<String, dynamic> toJson() {
    return {
      'suggestionText': suggestionText,
      'analysisImageUrl': analysisImageUrl,
      'originalImageUrl': originalImageUrl,
      'createdAt': createdAt,
    };
  }

  // Crea un objeto AnalysisHistory desde un DocumentSnapshot de Firestore
  factory AnalysisHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnalysisHistory(
      id: doc.id,
      suggestionText: data['suggestionText'] ?? '',
      analysisImageUrl: data['analysisImageUrl'] ?? '',
      originalImageUrl: data['originalImageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}