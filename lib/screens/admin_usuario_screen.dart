import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_usuario_detalle_screen.dart';

// 💡 Colores reutilizados del AdminScreen
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores
const Color _adminLabelColor = Color(0xFF668C98); // Color de las etiquetas secundarias
const Color _adminPrimaryColor = Color(0xFF07303B);
const Color _adminErrorColor = Color(0xFFE57373); // Rojo suave para errores

class AdminUsuarioScreen extends StatefulWidget {
  const AdminUsuarioScreen({super.key});

  @override
  State<AdminUsuarioScreen> createState() => _AdminUsuarioScreenState();
}

class _AdminUsuarioScreenState extends State<AdminUsuarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // Lógica de Eliminación de Usuario
  // ----------------------------------------------------

  Future<void> _handleDeleteUser(String uid, String nombreCompleto) async {
    final bool confirm = await _showConfirmationDialog(context, nombreCompleto);
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      // 1. Eliminar el documento de usuario
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // 2. Opcional: Si el usuario estaba inscrito en actividades, limpiarlo de ellas.
      // Esto previene datos huérfanos y asegura consistencia.
      final actividadesSnapshot = await FirebaseFirestore.instance
          .collection('actividades')
          .where('inscritos', arrayContains: {'uid': uid}) // Busca actividades que lo tengan
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in actividadesSnapshot.docs) {
        List<dynamic> inscritos = doc.data()['inscritos'] ?? [];
        // Filtramos para quitar al usuario por su UID
        List<Map<String, dynamic>> nuevaLista = inscritos
            .cast<Map<String, dynamic>>()
            .where((item) => item['uid'] != uid)
            .toList();

        // Actualizamos la lista de inscritos en la actividad
        batch.update(doc.reference, {'inscritos': nuevaLista});
      }

      await batch.commit();


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario $nombreCompleto eliminado con éxito y limpiado de actividades.',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // ⚠️ NOTA: Eliminar el usuario de Firebase Auth requeriría una Cloud Function,
      // aquí solo eliminamos el registro de la base de datos Firestore.
      print('Error al eliminar usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el usuario: $e',
              style: TextStyle(color: _adminErrorColor)),
          backgroundColor: _adminCardColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Diálogo de confirmación para la eliminación
  Future<bool> _showConfirmationDialog(BuildContext context, String nombre) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _adminCardColor,
          title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
          content: Text('¿Estás seguro de que deseas eliminar permanentemente al usuario "$nombre"?',
              style: const TextStyle(color: _adminLabelColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: _adminLabelColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: _adminErrorColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // ----------------------------------------------------
  // Card de Usuario
  // ----------------------------------------------------

  Widget _userCard(String uid, Map<String, dynamic> userData) {
    final nombre = userData['nombre'] ?? '';
    final apellidoPaterno = userData['apellido_paterno'] ?? '';
    final apellidoMaterno = userData['apellido_materno'] ?? '';
    final matricula = userData['matricula'] ?? 'Sin matrícula';
    final email = userData['email'] ?? 'Sin email';
    final nombreCompleto = '$nombre $apellidoPaterno $apellidoMaterno'.trim();
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalle del usuario
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUsuarioDetalleScreen(
              userId: uid,
              userName: nombreCompleto,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _adminCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _adminAccentColor.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar con Inicial
            CircleAvatar(
              radius: 20,
              backgroundColor: _adminAccentColor.withOpacity(0.2),
              child: Text(
                inicial,
                style: const TextStyle(
                    fontSize: 18, color: _adminAccentColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre completo
                  Text(
                    nombreCompleto,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Matrícula y Email
                  Text(
                    'Matrícula: $matricula',
                    style: const TextStyle(color: _adminLabelColor, fontSize: 13),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: _adminLabelColor, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Botón de Eliminar
            IconButton(
              icon: const Icon(Icons.delete_forever, color: _adminErrorColor),
              tooltip: 'Eliminar usuario',
              onPressed: () => _handleDeleteUser(uid, nombreCompleto),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _adminBackgroundColor, // Aplicar fondo oscuro
      child: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: _adminAccentColor),
                hintText: 'Buscar por nombre, matrícula o email...',
                hintStyle: const TextStyle(color: _adminLabelColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _adminCardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Título de Resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Usuarios Registrados (Rol: "usuario")',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Indicador de Carga
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: _adminAccentColor),
            ),

          // Lista de Usuarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ⚠️ Importante: Filtramos solo por rol 'usuario'
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'usuario')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _adminAccentColor));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: _adminErrorColor)));
                }

                final docs = snapshot.data!.docs;

                List<Map<String, dynamic>> users = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id; // Almacenamos el UID
                  return data;
                }).toList();

                // Aplicar búsqueda
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  users = users.where((u) {
                    final nombreCompleto =
                    '${u['nombre'] ?? ''} ${u['apellido_paterno'] ?? ''} ${u['apellido_materno'] ?? ''}'.toLowerCase();

                    return nombreCompleto.contains(query) ||
                        (u['matricula'] ?? '').toString().toLowerCase().contains(query) ||
                        (u['email'] ?? '').toString().toLowerCase().contains(query);
                  }).toList();
                }

                if (users.isEmpty && _searchController.text.isEmpty) {
                  return const Center(
                      child: Text(
                        'No se encontraron usuarios con el rol "usuario".',
                        style: TextStyle(color: _adminLabelColor),
                      ));
                } else if (users.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(
                      child: Text(
                        'No se encontraron resultados para la búsqueda.',
                        style: TextStyle(color: _adminLabelColor),
                      ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _userCard(user['id'] as String, user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}