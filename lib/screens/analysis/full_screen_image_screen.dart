import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageScreen extends StatelessWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String heroTag;

  const FullScreenImageScreen({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.imageUrl,
    required this.heroTag,
  }) : assert(imageFile != null || imageBytes != null || imageUrl != null); // <-- ¡NUEVO!

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(imageFile!);
    } else if (imageBytes != null) {
      imageWidget = Image.memory(imageBytes!);
    } else if (imageUrl != null) {
      // Muestra la imagen desde la URL (para el historial)
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
        const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
        const Icon(Icons.broken_image, color: Colors.white),
      );
    } else {
      imageWidget =
      const Center(child: Icon(Icons.broken_image, color: Colors.white));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha de "atrás"
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}