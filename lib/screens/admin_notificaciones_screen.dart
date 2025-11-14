import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 💡 Colores reutilizados del AdminScreen
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores
const Color _adminLabelColor = Color(0xFF668C98); // Color de las etiquetas secundarias
const Color _adminPrimaryColor = Color(0xFF07303B);
const Color _adminErrorColor = Color(0xFFE57373); // Rojo suave para errores

class AdminNotificacionesScreen extends StatefulWidget {
  const AdminNotificacionesScreen({super.key});

  @override
  State<AdminNotificacionesScreen> createState() => _AdminNotificacionesScreenState();
}

class _AdminNotificacionesScreenState extends State<AdminNotificacionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedFilters = ['Todos'];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Todos', 'icon': Icons.list_alt},
    {'nombre': 'Académico', 'icon': Icons.school},
    {'nombre': 'Deportivo', 'icon': Icons.sports_soccer},
    {'nombre': 'Social', 'icon': Icons.people},
    {'nombre': 'Cultural', 'icon': Icons.palette},
    {'nombre': 'Otro', 'icon': Icons.more_horiz},
  ];

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

  // Lógica para alternar filtros
  void _toggleFilter(String nombre) {
    setState(() {
      if (nombre == 'Todos') {
        _selectedFilters = ['Todos'];
      } else {
        _selectedFilters.remove('Todos');
        if (_selectedFilters.contains(nombre)) {
          _selectedFilters.remove(nombre);
        } else {
          _selectedFilters.add(nombre);
        }
      }
    });
  }

  // Función auxiliar para obtener el ícono según el tipo de notificación
  IconData _iconoNotificacion(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'evento':
        return Icons.event;
      case 'actividad':
        return Icons.local_activity;
      default:
        return Icons.notifications;
    }
  }

  // Función auxiliar para obtener el ícono según la categoría
  IconData _iconoCategoria(String cat) {
    switch (cat) {
      case 'Académico':
        return Icons.school;
      case 'Deportivo':
        return Icons.sports_soccer;
      case 'Social':
        return Icons.people;
      case 'Cultural':
        return Icons.palette;
      default:
        return Icons.more_horiz;
    }
  }

  // ----------------------------------------------------
  // Lógica de Eliminación
  // ----------------------------------------------------

  Future<void> _handleDelete(String docId, String titulo) async {
    final bool confirm = await _showConfirmationDialog(context, titulo);
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('notificaciones').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación eliminada con éxito.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('Error al eliminar notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la notificación: $e', style: TextStyle(color: _adminErrorColor))),
      );
    } finally {
      // No necesitamos forzar setState si estamos dentro de un StreamBuilder,
      // pero si el indicador de carga está activo, lo apagamos.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Diálogo de confirmación para la eliminación
  Future<bool> _showConfirmationDialog(BuildContext context, String titulo) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _adminCardColor,
          title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
          content: Text('¿Estás seguro de que deseas eliminar la notificación "$titulo"?', style: const TextStyle(color: _adminLabelColor)),
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
  // Card de Notificación (Diseño Admin)
  // ----------------------------------------------------

  Widget _notificacionCard(Map<String, dynamic> n) {
    final docId = n['id'] as String;
    final titulo = n['titulo'] ?? 'Sin título';
    final descripcion = n['descripcion'] ?? 'Sin descripción';
    final categoria = n['categoria'] ?? 'Otro';
    final tipo = n['tipo'] ?? 'evento';
    final ubicacion = n['ubicacion'] ?? 'No especificada';

    final fecha = n['fecha'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(
      (n['fecha'] as Timestamp).toDate(),
    )
        : 'Fecha desconocida';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _adminAccentColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono Principal (Tipo: Evento/Actividad)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _adminAccentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconoNotificacion(tipo), color: _adminAccentColor, size: 28),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                // Descripción
                Text(
                  descripcion,
                  style: const TextStyle(color: _adminLabelColor, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // 💡 INICIO DE CAMBIOS DE ESTRUCTURA 💡

                // Badge de Categoría
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _adminPrimaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Ajusta el tamaño al contenido
                    children: [
                      Icon(_iconoCategoria(categoria), size: 14, color: _adminAccentColor),
                      const SizedBox(width: 4),
                      Text(categoria,
                          style: const TextStyle(
                              fontSize: 12, color: _adminAccentColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // Espacio después del badge

                // Fecha (Debajo del badge)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: _adminLabelColor),
                    const SizedBox(width: 4),
                    Text(fecha,
                        style: const TextStyle(fontSize: 12, color: _adminLabelColor)),
                  ],
                ),
                const SizedBox(height: 4), // Espacio después de la fecha

                // Ubicación (Debajo de la fecha)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: _adminLabelColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(ubicacion,
                          style: const TextStyle(fontSize: 12, color: _adminLabelColor),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                // 💡 FIN DE CAMBIOS DE ESTRUCTURA 💡
              ],
            ),
          ),

          // Botón de Eliminar
          IconButton(
            icon: const Icon(Icons.delete_forever, color: _adminErrorColor),
            onPressed: () => _handleDelete(docId, titulo),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: _adminBackgroundColor, // Aplicar fondo oscuro
      child: Column(
        children: [
          // Barra de búsqueda (sin botón de crear)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: _adminAccentColor),
                hintText: 'Buscar notificaciones...',
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

          // Filtros horizontales
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final isSelected = _selectedFilters.contains(cat['nombre']);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _toggleFilter(cat['nombre']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _adminAccentColor : _adminCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? null : Border.all(color: _adminLabelColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'],
                              size: 20,
                              color: isSelected ? Colors.white : _adminLabelColor),
                          const SizedBox(width: 6),
                          Text(
                            cat['nombre'],
                            style: TextStyle(
                                color: isSelected ? Colors.white : _adminLabelColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Título de Resultados
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notificaciones Publicadas',
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

          // Lista de notificaciones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Ordenamos por 'creadaEn' para que las más recientes aparezcan primero
              stream: FirebaseFirestore.instance
                  .collection('notificaciones')
                  .orderBy('creadaEn', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _adminAccentColor));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: _adminErrorColor)));
                }

                final docs = snapshot.data!.docs;

                List<Map<String, dynamic>> notificaciones = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                // Aplicar filtros
                if (!_selectedFilters.contains('Todos')) {
                  notificaciones = notificaciones
                      .where((n) => _selectedFilters.contains(n['categoria']))
                      .toList();
                }

                // Aplicar búsqueda
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  notificaciones = notificaciones.where((n) {
                    return (n['titulo'] ?? '').toString().toLowerCase().contains(query) ||
                        (n['descripcion'] ?? '').toString().toLowerCase().contains(query) ||
                        (n['ubicacion'] ?? '').toString().toLowerCase().contains(query);
                  }).toList();
                }

                if (notificaciones.isEmpty) {
                  return const Center(
                      child: Text(
                        'No se encontraron notificaciones.',
                        style: TextStyle(color: _adminLabelColor),
                      ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notificaciones.length,
                  itemBuilder: (context, index) {
                    final n = notificaciones[index];
                    return _notificacionCard(n);
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