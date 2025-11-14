import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// 🚨 Importar la nueva pantalla de detalle de ADMIN para edición/creación
import 'admin_evento_detalle_screen.dart';

// 💡 Colores reutilizados del AdminScreen
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores
const Color _adminLabelColor = Color(0xFF668C98); // Color de las etiquetas secundarias
const Color _adminPrimaryColor = Color(0xFF07303B);

class AdminEventosScreen extends StatefulWidget {
  const AdminEventosScreen({super.key});

  @override
  State<AdminEventosScreen> createState() => _AdminEventosScreenState();
}

class _AdminEventosScreenState extends State<AdminEventosScreen> {
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

  // 💡 NAVEGACIÓN ACTUALIZADA: Navegar a la pantalla de creación
  void _createEvent() async {
    final bool? shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminEventoDetalleScreen(evento: null), // evento: null para CREAR
      ),
    );
    // Opcional: si la pantalla de detalle devuelve 'true', puedes forzar un setState para refrescar.
    if (shouldRefresh == true) {
      setState(() {
        // Esto fuerza a reconstruir el StreamBuilder si es necesario, aunque onSnapshot lo hace automáticamente.
      });
    }
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
                // Input de Búsqueda (Adaptado al tema oscuro)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white), // Texto del input en blanco
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: _adminAccentColor),
                      hintText: 'Buscar eventos...',
                      hintStyle: const TextStyle(color: _adminLabelColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _adminCardColor, // Fondo del input oscuro
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Botón Circular "Crear Evento"
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: _adminAccentColor, // Verde brillante
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
                    onPressed: _createEvent, // 💡 Usa el método actualizado
                  ),
                ),
              ],
            ),
          ),

          // Filtros horizontales (Adaptados al tema oscuro)
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
                        // Seleccionado: Verde brillante
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
                              // No seleccionado: Gris azulado
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
                'Gestión de Eventos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Título en blanco
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lista de eventos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('eventos')
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _adminAccentColor));
                }

                final now = DateTime.now();
                final docs = snapshot.data!.docs;

                List<Map<String, dynamic>> eventos = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).where((e) {
                  // Mantener la lógica de solo eventos futuros o de hoy
                  final fechaEvento = (e['fecha'] as Timestamp).toDate();
                  return !fechaEvento.isBefore(DateTime(now.year, now.month, now.day));
                }).toList();

                // Aplicar filtros
                if (!_selectedFilters.contains('Todos')) {
                  eventos = eventos
                      .where((e) => _selectedFilters.contains(e['categoria']))
                      .toList();
                }

                // Aplicar búsqueda
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  eventos = eventos
                      .where((e) => (e['titulo'] ?? '').toString().toLowerCase().contains(query))
                      .toList();
                }

                if (eventos.isEmpty) {
                  return const Center(
                      child: Text(
                        'No se encontraron eventos futuros.',
                        style: TextStyle(color: _adminLabelColor),
                      ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final e = eventos[index];
                    return _eventoCard(e);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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

  // Card de Evento (Adaptado al Tema Oscuro Admin)
  Widget _eventoCard(Map<String, dynamic> e) {
    final fecha = e['fecha'] != null
        ? DateFormat('dd/MM/yyyy').format(
        (e['fecha'] is Timestamp) ? (e['fecha'] as Timestamp).toDate() : e['fecha'])
        : '';
    final horaInicio = e['horaInicio'] ?? '';
    final horaFin = e['horaFin'] ?? '';
    final categoria = e['categoria'] ?? '';
    final ubicacion = e['ubicacion'] ?? '';
    final foto = e['foto'] ?? '';

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

    // Placeholder para ícono/imagen
    Widget _placeholderIcon(String categoria) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _adminAccentColor.withOpacity(0.1), // Fondo muy tenue
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconoCategoria(categoria),
          color: _adminAccentColor, // Ícono verde brillante
        ),
      );
    }

    return GestureDetector(
      // 💡 NAVEGACIÓN ACTUALIZADA: Navegar a la pantalla de EDICIÓN
      onTap: () async {
        final bool? shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminEventoDetalleScreen(evento: e), // evento: e para EDITAR
          ),
        );
        if (shouldRefresh == true) {
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _adminCardColor, // Fondo oscuro de la tarjeta
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
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
                  // Título
                  Text(
                    e['titulo'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Badge categoría (Adaptado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _adminAccentColor.withOpacity(0.2), // Fondo más oscuro
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconoCategoria(categoria),
                          size: 14,
                          color: _adminAccentColor, // Ícono verde
                        ),
                        const SizedBox(width: 4),
                        Text(
                          categoria,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _adminAccentColor, // Texto verde
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Fecha
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: _adminLabelColor),
                      const SizedBox(width: 4),
                      Text(fecha, style: const TextStyle(color: _adminLabelColor)),
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
          ],
        ),
      ),
    );
  }
}