import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_actividad_edit_screen.dart';
// 🚨 Importar la nueva pantalla de detalle
import 'admin_actividad_detalle_screen.dart';

// 💡 Colores reutilizados del AdminScreen
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores
const Color _adminLabelColor = Color(0xFF668C98); // Color de las etiquetas secundarias
const Color _adminPrimaryColor = Color(0xFF07303B);

class AdminActividadesScreen extends StatefulWidget {
  const AdminActividadesScreen({super.key});

  @override
  State<AdminActividadesScreen> createState() => _AdminActividadesScreenState();
}

class _AdminActividadesScreenState extends State<AdminActividadesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedFilters = ['Todos'];

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
  // Lógica de Navegación
  // ----------------------------------------------------

  // Navegar a la pantalla de creación
  void _createActivity() async {
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminActividadEditScreen(actividad: null), // actividad: null para CREAR
      ),
    );
    if (shouldRefresh == true) setState(() {});
  }

  // Navegar a la pantalla de edición
  void _editActivity(Map<String, dynamic> actividad) async {
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminActividadEditScreen(actividad: actividad), // actividad: 'e' para EDITAR
      ),
    );
    if (shouldRefresh == true) setState(() {});
  }

  // 💡 ACTUALIZADO: Navegar a la pantalla de detalle (con integrantes)
  void _viewActivityDetails(Map<String, dynamic> actividad) async {
    final String actividadId = actividad['id'];

    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminActividadDetalleScreen(
          actividadData: actividad, // Pasamos los datos iniciales
          actividadId: actividadId, // Pasamos el ID para el Stream
        ),
      ),
    );
    // Si se realiza una acción (eliminar/finalizar), la lista se refrescará automáticamente.
    if (shouldRefresh == true) setState(() {});
  }

  // ----------------------------------------------------
  // Card de Actividad (Diseño Admin)
  // ----------------------------------------------------

  // Card de Actividad (Adaptado al Tema Oscuro Admin)
  Widget _actividadCard(Map<String, dynamic> e) {
    final nombre = e['nombre'] ?? 'Actividad sin nombre';
    final categoria = e['categoria'] ?? '';
    final ubicacion = e['ubicacion'] ?? '';
    final foto = e['foto'] ?? '';
    final horaInicio = e['hora_inicio'] ?? '';
    final horaFin = e['hora_fin'] ?? '';
    final estado = (e['estado'] ?? 'en_curso').toString().toUpperCase(); // Para mostrar el estado

    final fechaInicio = e['fecha_inicio'] != null
        ? DateFormat('dd/MM/yyyy').format(
        (e['fecha_inicio'] is Timestamp) ? (e['fecha_inicio'] as Timestamp).toDate() : e['fecha_inicio'])
        : '';

    // Placeholder para ícono/imagen
    Widget _placeholderIcon(String cat) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _adminAccentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconoCategoria(cat),
          color: _adminAccentColor,
        ),
      );
    }

    return GestureDetector(
      // Navegación del TAP PRINCIPAL al detalle de la actividad (integrantes)
      onTap: () => _viewActivityDetails(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _adminCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen o ícono
            foto.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                foto,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderIcon(categoria),
              ),
            )
                : _placeholderIcon(categoria),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre (Título)
                  Text(
                    nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Badge categoría y estado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _adminAccentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconoCategoria(categoria),
                              size: 14,
                              color: _adminAccentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              categoria,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _adminAccentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _adminLabelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          estado,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _adminLabelColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Fecha de Inicio
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: _adminLabelColor),
                      const SizedBox(width: 4),
                      Text(fechaInicio, style: const TextStyle(color: _adminLabelColor)),
                    ],
                  ),

                  // Horas
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: _adminLabelColor),
                      const SizedBox(width: 4),
                      Text('$horaInicio - $horaFin', style: const TextStyle(color: _adminLabelColor)),
                    ],
                  ),

                  // Ubicación
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: _adminLabelColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text(ubicacion, style: const TextStyle(color: _adminLabelColor))),
                    ],
                  ),
                ],
              ),
            ),

            // Botones de Acción (Ojo y Lápiz)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón Editar
                IconButton(
                  icon: const Icon(Icons.edit, color: _adminAccentColor),
                  tooltip: 'Editar Actividad',
                  onPressed: () => _editActivity(e), // Navega a edición
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 10),
                // Botón Detalle (Ojo)
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: _adminLabelColor),
                  tooltip: 'Ver Integrantes',
                  onPressed: () => _viewActivityDetails(e), // Navega a detalle de admin
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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
          // Barra de búsqueda + Botón Crear
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Input de Búsqueda
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: _adminAccentColor),
                      hintText: 'Buscar actividades...',
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

                const SizedBox(width: 10),

                // Botón Circular "Crear Actividad"
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: _adminAccentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _adminAccentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                    onPressed: _createActivity, // Navega a creación
                  ),
                ),
              ],
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
                'Gestión de Actividades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lista de actividades
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('actividades')
                  .orderBy('fecha_inicio', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _adminAccentColor));
                }

                final docs = snapshot.data!.docs;

                List<Map<String, dynamic>> actividades = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                // Aplicar filtros
                if (!_selectedFilters.contains('Todos')) {
                  actividades = actividades
                      .where((e) => _selectedFilters.contains(e['categoria']))
                      .toList();
                }

                // Aplicar búsqueda
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  actividades = actividades.where((e) {
                    return (e['nombre'] ?? '').toString().toLowerCase().contains(query) ||
                        (e['descripcion'] ?? '').toString().toLowerCase().contains(query) ||
                        (e['ubicacion'] ?? '').toString().toLowerCase().contains(query);
                  }).toList();
                }

                if (actividades.isEmpty) {
                  return const Center(
                      child: Text(
                        'No se encontraron actividades.',
                        style: TextStyle(color: _adminLabelColor),
                      ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: actividades.length,
                  itemBuilder: (context, index) {
                    final e = actividades[index];
                    return _actividadCard(e);
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