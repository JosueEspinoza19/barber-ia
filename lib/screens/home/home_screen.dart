import 'dart:async';
import 'package:flutter/material.dart';
import '../analysis/analysis_screen.dart';
import '../clients/client_list_screen.dart';
import 'package:faceia/models/barber_model.dart';
import '../profile/profile_screen.dart';
import '../profile/plans_screen.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Empezar en Analizar por defecto

  final Color _accentColor = const Color(0xFF1579AF);
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _barberSubscription;
  BarberModel? _currentBarber;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  @override
  void dispose() {
    _barberSubscription?.cancel(); // Limpiamos la suscripción
    super.dispose();
  }

  // Verifica si el usuario es nuevo y lo redirige a Planes
  void _checkUserStatus() {
    _barberSubscription = _firestoreService.getBarberStream().listen((barber) {
      if (mounted) {
        setState(() {
          _currentBarber = barber;
        });
      }
      // Redirección de usuario nuevo
      if (barber != null && barber.isNewUser && mounted) {
        _firestoreService.completeOnboarding();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlansScreen()),
        );
      }
    });
  }

  // Lista de pantallas conectadas
  static final List<Widget> _widgetOptions = <Widget>[
    const ClientListScreen(),     // Índice 0: Gestión de Clientes
    AnalysisScreen(),             // Índice 1: Análisis (Cámara/IA)
    const ProfileScreen(),        // Índice 2: Perfil (Cuotas/Planes)
  ];

  void _onItemTapped(int index) {
    if (_currentBarber == null) return;

    final isFreePlan = _currentBarber!.plan == 'Gratuito';
    final isQuotaZero = (_currentBarber!.imageLimit - _currentBarber!.imagesUsed) <= 0;

    // Usuario nuevo (Plan Gratuito) SIN gestión de clientes.
    if (index == 0 && isFreePlan) {
      _showUpgradeDialog('La gestión de clientes está disponible a partir del Plan Básico.');
      return;
    }

    // Deshabilitar clientes si la cuota es cero (aunque tenga plan Pro).
    if (index == 0 && isQuotaZero) {
      _showUpgradeDialog('Tu cuota se ha agotado. Recarga para acceder a tus clientes.');
      return;
    }

    // Deshabilitar generación si cuota cero.
    if (index == 1 && isQuotaZero) {
      _showUpgradeDialog('Has alcanzado tu límite de imágenes. Actualiza tu plan para continuar.');
      return;
    }

    setState(() => _selectedIndex = index);
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acceso Restringido'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlansScreen()));
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Analizar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8.0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}