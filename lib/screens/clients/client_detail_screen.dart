import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/client_model.dart';
import '../analysis/analysis_screen.dart';
import '../../services/firestore_service.dart';
import 'edit_client_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/analysis_history_model.dart';
import 'history_detail_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {

  final Color _accentColor = const Color(0xFF1579AF);
  final Color _textColor = Colors.grey.shade900;

  late Client _client;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSavingNote = false;
  bool _isDeleting = false;

  late Stream<List<AnalysisHistory>> _historyStream;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _historyStream = _firestoreService.getAnalysisHistory(_client.id);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Inicia un análisis (asociado a este cliente)
  void _startClientAnalysis() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(
          clientId: _client.id,
        ),
      ),
    );
  }

  // Llama al servicio para guardar la nota en Firestore
  Future<void> _addNote() async {
    final noteText = _noteController.text.trim();
    if (noteText.isEmpty) return;

    setState(() => _isSavingNote = true);

    try {
      await _firestoreService.addNoteToClient(_client.id, noteText);
      if (mounted) {
        setState(() {
          _client.notes.add(noteText);
          _noteController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la nota: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNote = false);
      }
    }
  }

  // Navega a la pantalla de edición y actualiza la UI al regresar.
  Future<void> _navigateToEditClient() async {
    final dynamic updatedClient = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditClientScreen(client: _client),
      ),
    );

    if (updatedClient != null && updatedClient is Client) {
      setState(() {
        _client = updatedClient;
      });
    }
  }

  // Muestra un diálogo de confirmación y borra al cliente.
  Future<void> _deleteClient() async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Cliente'),
          content: Text(
              '¿Estás seguro de que quieres eliminar a ${_client.name}? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _firestoreService.deleteClient(_client.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente eliminado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar el cliente: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  // Muestra diálogo para confirmar borrado de historial
  Future<void> _deleteHistoryItem(AnalysisHistory historyItem) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Análisis'),
          content: const Text(
              '¿Estás seguro de que quieres eliminar este registro del historial? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      try {
        await _firestoreService.deleteAnalysisFromHistory(
          clientId: _client.id,
          historyItem: historyItem,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Historial eliminado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // Navega a la nueva pantalla de detalle del historial
  void _navigateToHistoryDetail(AnalysisHistory historyItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryDetailScreen(historyItem: historyItem),
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
              fontSize: 32, fontWeight: FontWeight.w700, color: _textColor,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'IA',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 32, fontWeight: FontWeight.w700, color: _accentColor,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: _textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditClient,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Iniciar Análisis',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _startClientAnalysis,
              ),
            ),
            _buildTabs(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isDeleting
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Eliminar Cliente',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                onPressed: _deleteClient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cabecera con la foto y nombre del cliente
  Widget _buildProfileHeader() {
    ImageProvider? backgroundImage;
    Widget? avatarChild;
    if (_client.imageUrl != null && _client.imageUrl!.isNotEmpty) {
      backgroundImage = CachedNetworkImageProvider(_client.imageUrl!);
    } else {
      avatarChild = Text(
        _client.name.isNotEmpty ? _client.name[0] : '?',
        style: const TextStyle(
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: _accentColor,
            backgroundImage: backgroundImage,
            child: avatarChild,
          ),
          const SizedBox(height: 16),
          Text(
            _client.name,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: _textColor),
          ),
          const SizedBox(height: 4),
          Text(
            _client.phone.isEmpty
                ? "Teléfono no registrado"
                : _client.phone,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _client.email.isEmpty
                ? "Correo no registrado"
                : _client.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Construye las pestañas de "Historial de Análisis" y "Notas"
  Widget _buildTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: _accentColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: _accentColor,
              indicatorWeight: 3.0,
              tabs: const [
                Tab(text: 'HISTORIAL'),
                Tab(text: 'NOTAS'),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _buildHistoryGrid(),
                _buildNotesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Muestra una cuadrícula visual del historial de análisis
  Widget _buildHistoryGrid() {
    return StreamBuilder<List<AnalysisHistory>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _accentColor));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar el historial: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No hay análisis guardados.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        final historyList = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          // Muestra 2 columnas
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0, // Cuadrados perfectos
          ),
          itemCount: historyList.length,
          itemBuilder: (context, index) {
            final historyItem = historyList[index];
            final String date =
                '${historyItem.createdAt.toDate().day}/${historyItem.createdAt.toDate().month}/${historyItem.createdAt.toDate().year}';

            return Material(
              elevation: 2.0,
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: () => _navigateToHistoryDetail(historyItem),
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. La Imagen
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: CachedNetworkImage(
                        imageUrl: historyItem.analysisImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                    // 2. Gradiente oscuro para que el texto se lea
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    // 3. El Texto (Fecha)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // 4. El Botón de Borrar
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          onPressed: () => _deleteHistoryItem(historyItem),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Muestra las notas reales del cliente y permite añadir nuevas
  Widget _buildNotesList() {
    return Column(
      children: [
        Expanded(
          child: (_client.notes.isEmpty)
              ? const Center(
            child: Text(
              'No hay notas para este cliente.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.builder(
            itemCount: _client.notes.length,
            itemBuilder: (context, index) {
              final note =
              _client.notes[_client.notes.length - 1 - index];
              return ListTile(
                leading: const Icon(Icons.note, color: Colors.grey),
                title: Text(note),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Añadir nueva nota...',
              suffixIcon: _isSavingNote
                  ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : IconButton(
                icon: Icon(Icons.send, color: _accentColor),
                onPressed: _addNote,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        )
      ],
    );
  }
}