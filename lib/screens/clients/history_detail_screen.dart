import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/analysis_history_model.dart';
import '../analysis/full_screen_image_screen.dart';

/// Esta pantalla muestra el detalle de un solo registro del historial.
class HistoryDetailScreen extends StatelessWidget {
  final AnalysisHistory historyItem;

  const HistoryDetailScreen({
    super.key,
    required this.historyItem,
  });

  final Color _textColor = const Color(0xFF212121);
  final Color _accentColor = const Color(0xFF1579AF);

  @override
  Widget build(BuildContext context) {
    // Formateamos la fecha
    final date = historyItem.createdAt.toDate();
    final String dateStr = '${date.day}/${date.month}/${date.year}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Análisis del $dateStr',
          style: GoogleFonts.leagueSpartan(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de Imágenes
            Row(
              children: [
                // 1. Imagen Original
                Expanded(
                  child: _buildImageCard(
                    context,
                    label: 'Original',
                    imageUrl: historyItem.originalImageUrl, // Puede ser nulo en registros viejos
                    heroTag: 'history-original-${historyItem.id}',
                  ),
                ),
                const SizedBox(width: 16),
                // 2. Imagen Simulada (Sugerencia)
                Expanded(
                  child: _buildImageCard(
                    context,
                    label: 'Sugerencia',
                    imageUrl: historyItem.analysisImageUrl,
                    heroTag: 'history-simulated-${historyItem.id}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Tarjeta de Sugerencia (Texto)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: _accentColor, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Detalle de la Sugerencia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    historyItem.suggestionText,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir las tarjetas de imagen
  Widget _buildImageCard(BuildContext context,
      {required String label, String? imageUrl, required String heroTag}) {

    // Si no hay URL, mostramos un placeholder
    final Widget imageWidget = (imageUrl != null && imageUrl.isNotEmpty)
        ? CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      height: 200,
      width: double.infinity,
      placeholder: (context, url) => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    )
        : Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text("No disponible", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageScreen(
                    imageUrl: imageUrl,
                    heroTag: heroTag,
                  ),
                ),
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Hero(
              tag: heroTag,
              child: imageWidget,
            ),
          ),
        ),
      ],
    );
  }
}