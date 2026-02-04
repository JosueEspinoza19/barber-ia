import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/client_model.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';
import '../../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {

  final Color _primaryColor = Colors.blue.shade800;
  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = Colors.grey.shade900;

  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Client>> _clientsStream;
  List<Client> _allClients = []; // Almacena la lista completa
  // Esta lista ahora SÓLO se actualiza por el listener del buscador
  List<Client> _filteredClients = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Obtenemos el stream de clientes desde el servicio
    _clientsStream = _firestoreService.getClients();
    // El listener SÍ debe llamar a _filterClients (que tiene setState)
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterClients);
    _searchController.dispose();
    super.dispose();
  }

  // Filtra la lista de clientes basado en el texto de búsqueda.
  // Esta función SÍ usa setState() porque la llama el usuario (al teclear).
  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _allClients
          .where((client) => client.name.toLowerCase().contains(query))
          .toList();
    });
  }

  // Navega a la pantalla de "Añadir Cliente"
  void _navigateToAddClient() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddClientScreen()),
    );
  }

  // Navega a la pantalla de "Detalle de Cliente"
  void _navigateToClientDetail(Client client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: 'Barber',
            style: GoogleFonts.leagueSpartan(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'IA',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16.0),
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: Text(
                    'Mis Clientes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
                _buildSearchBar(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Añadir Cliente',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 99.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onPressed: _navigateToAddClient,
                  ),
                ),
              ],
            ),
          ),
          // Lista de Clientes (con fondo gris)
          Expanded(
            child: StreamBuilder<List<Client>>(
              stream: _clientsStream,
              builder: (context, snapshot) {
                // Estado 1: Cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: _accentColor));
                }
                // Estado 2: Error
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error al cargar clientes: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)));
                }
                // Estado 3: Sin datos (lista vacía)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _allClients = [];
                  _filteredClients = [];
                  return const Center(
                    child: Text(
                      'No tienes clientes registrados.\n¡Añade uno para empezar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Estado 4: Datos recibidos
                // Siempre actualizamos la lista completa
                _allClients = snapshot.data!;

                // Aplicamos el filtro aquí mismo, a una variable LOCAL,
                // Sin llamar a setState() o _filterClients().
                final query = _searchController.text.toLowerCase();
                final List<Client> clientsToShow;
                if (query.isEmpty) {
                  clientsToShow = _allClients;
                } else {
                  // Refiltramos la lista completa con la query actual
                  clientsToShow = _allClients
                      .where(
                          (client) => client.name.toLowerCase().contains(query))
                      .toList();
                }
                // (La variable de estado _filteredClients solo se actualiza
                // cuando el usuario escribe, gracias al listener).

                if (clientsToShow.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron clientes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  // Usamos la variable local 'clientsToShow'
                  itemCount: clientsToShow.length,
                  itemBuilder: (context, index) {
                    // Usamos la variable local 'clientsToShow'
                    final client = clientsToShow[index];

                    ImageProvider? backgroundImage;
                    Widget? avatarChild;
                    if (client.imageUrl != null &&
                        client.imageUrl!.isNotEmpty) {
                      backgroundImage =
                          CachedNetworkImageProvider(client.imageUrl!);
                    } else {
                      avatarChild = Text(
                        client.name.isNotEmpty ? client.name[0] : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      );
                    }

                    final String lastAnalysisDate = client.lastAnalysis != null
                        ? "Último análisis: ${client.lastAnalysis!.day}/${client.lastAnalysis!.month}/${client.lastAnalysis!.year}"
                        : "Último análisis: N/A";

                    return Card(
                      color: Colors.white,
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: _accentColor,
                          backgroundImage: backgroundImage,
                          child: avatarChild,
                        ),
                        title: Text(
                          client.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(lastAnalysisDate),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateToClientDetail(client),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para la barra de búsqueda
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50.0),
            borderSide: BorderSide(color: _accentColor, width: 2),
          ),
        ),
      ),
    );
  }
}