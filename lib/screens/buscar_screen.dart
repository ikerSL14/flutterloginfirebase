import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'evento_detalle_screen.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              hintText: 'Buscar eventos, talleres...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.shade800
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'],
                            size: 20,
                            color:
                            isSelected ? Colors.white : Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          cat['nombre'],
                          style: TextStyle(
                              color:
                              isSelected ? Colors.white : Colors.green.shade800,
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

        // Resultados de búsqueda
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Resultados de la búsqueda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final docs = snapshot.data!.docs;

              List<Map<String, dynamic>> eventos = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).where((e) {
                // Solo eventos futuros o de hoy
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
                      'No se encontraron eventos',
                      style: TextStyle(color: Colors.grey),
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

    Widget _placeholderIcon(String categoria) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconoCategoria(categoria),
          color: Colors.green.shade800,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // 🔹 Navegar a la pantalla de detalle enviando el evento completo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventoDetalleScreen(evento: e),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  Text(
                    e['titulo'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Badge categoría
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconoCategoria(categoria),
                          size: 14,
                          color: Colors.green.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          categoria,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(fecha),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$horaInicio - $horaFin'),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(child: Text(ubicacion)),
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


  Widget _placeholderIcon(String categoria) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconoCategoria(categoria),
        color: Colors.green.shade800,
      ),
    );
  }

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
}
