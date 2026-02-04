import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final Color _primaryColor = const Color(0xFF1565C0);
  final Color _textColor = const Color(0xFF212121);
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Función para cambiar el plan
  Future<void> _selectPlan(String planName, BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.updateSubscriptionPlan(planName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Te has cambiado al plan $planName exitosamente!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver al perfil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar de plan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Elige tu Plan', style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.w700, color: _textColor)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Descubre el plan perfecto para ti y lleva tu barbería al siguiente nivel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 30),

            _buildPlanCard(
              title: 'Gratuito',
              price: '\$0',
              features: ['5 imágenes de análisis', ' Sin Gestión de Clientes', 'Soporte básico'],
              isPopular: false,
              onTap: () => _selectPlan('Gratuito', context),
            ),
            const SizedBox(height: 20),

            _buildPlanCard(
              title: 'Básico',
              price: '\$19',
              features: ['50 imágenes de análisis', 'Gestión estándar', 'Soporte básico'],
              isPopular: false,
              onTap: () => _selectPlan('Básico', context),
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              title: 'Pro',
              price: '\$39',
              features: ['200 imágenes de análisis', 'Gestión ilimitada', 'Soporte prioritario'],
              isPopular: true,
              onTap: () => _selectPlan('Pro', context),
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              title: 'Premium',
              price: '\$79',
              features: ['Imágenes ilimitadas', 'Gestión ilimitada', 'Soporte 24/7'],
              isPopular: false,
              onTap: () => _selectPlan('Premium', context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? Border.all(color: _primaryColor, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(20)),
              child: const Text('Más Popular', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor)),
              RichText(
                text: TextSpan(
                  text: price,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _primaryColor),
                  children: [TextSpan(text: '/mes', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.normal))],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [Icon(Icons.check_circle, color: _primaryColor, size: 20), const SizedBox(width: 10), Expanded(child: Text(feature, style: TextStyle(color: Colors.grey[700])))]),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? _primaryColor : Colors.white,
                foregroundColor: isPopular ? Colors.white : _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                elevation: isPopular ? 2 : 0,
              ),
              child: const Text('Seleccionar Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}