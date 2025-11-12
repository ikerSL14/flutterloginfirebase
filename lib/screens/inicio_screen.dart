import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InicioScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const InicioScreen({super.key, required this.onNavigate});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  List<Map<String, dynamic>> actividadesDestacadas = [];
  List<Map<String, dynamic>> proximosEventos = [];

  @override
  void initState() {
    super.initState();
    _cargarActividades();
    _cargarEventos();
  }

  Future<void> _cargarActividades() async {
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('actividades')
        .orderBy('fecha_inicio')
        .get();

    final List<Map<String, dynamic>> proximas = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['fecha_inicio'] != null && data['fecha_inicio'] is Timestamp) {
        final fecha = (data['fecha_inicio'] as Timestamp).toDate();
        if (fecha.isAfter(now)) {
          proximas.add(data);
        }
      }
    }

    proximas.sort((a, b) {
      final fechaA = (a['fecha_inicio'] as Timestamp).toDate();
      final fechaB = (b['fecha_inicio'] as Timestamp).toDate();
      return fechaA.compareTo(fechaB);
    });

    setState(() {
      // solo las 2 primeras
      actividadesDestacadas = proximas.take(2).toList();
    });
  }

  Future<void> _cargarEventos() async {
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .orderBy('fecha')
        .get();

    final List<Map<String, dynamic>> proximos = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['fecha'] != null && data['fecha'] is Timestamp) {
        final fecha = (data['fecha'] as Timestamp).toDate();
        if (fecha.isAfter(now)) {
          proximos.add(data);
        }
      }
    }

    proximos.sort((a, b) {
      final fechaA = (a['fecha'] as Timestamp).toDate();
      final fechaB = (b['fecha'] as Timestamp).toDate();
      return fechaA.compareTo(fechaB);
    });

    setState(() {
      proximosEventos = proximos.take(4).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 🔹 Acceso rápido
            const Text(
              "Acceso rápido",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _accesoRapido(context, "Calendario", Icons.calendar_today, 1),
                _accesoRapido(context, "Registro", Icons.edit_note, 3),
                _accesoRapido(context, "Notificaciones", Icons.notifications, 2),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _accesoRapido(context, "Perfil", Icons.person, 4),
                const SizedBox(width: 40),
                _accesoRapido(context, "Buscar", Icons.search, 5),
              ],
            ),
            const SizedBox(height: 25),

            // 🔹 Actividades destacadas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Actividades destacadas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigate(3), // lleva a registro_screen
                  child: const Text(
                    "Ver todo",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🔹 Cards horizontales
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: actividadesDestacadas.isEmpty
                    ? [const Text("No hay actividades próximas.")]
                    : actividadesDestacadas.map((act) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _ActividadCard(
                      imageUrl: act['foto'] ?? '',
                      titulo: act['nombre'] ?? '',
                      descripcion: act['descripcion'] ?? '',
                      categoria: act['categoria'] ?? '',
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 Próximos eventos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Próximos eventos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigate(1), // lleva a calendario_screen
                  child: const Text(
                    "Ver todo",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Column(
              children: proximosEventos.isEmpty
                  ? [const Text("No hay próximos eventos.")]
                  : proximosEventos.map((ev) {
                final fecha = (ev['fecha'] as Timestamp).toDate();
                final diaStr = DateFormat('d MMMM', 'es_ES').format(fecha);
                return _EventoItem(
                  hora: ev['horaInicio'] ?? '',
                  titulo: ev['titulo'] ?? '',
                  lugar: ev['ubicacion'] ?? '',
                  categoria: ev['categoria'] ?? '',
                  icono: _iconoCategoria(ev['categoria'] ?? ''),
                  dia: diaStr,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accesoRapido(BuildContext context, String texto, IconData icono, int index) {
    return GestureDetector(
      onTap: () => widget.onNavigate(index),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade50,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icono, size: 40, color: Colors.green),
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Conferencia':
        return Icons.mic;
      case 'Taller':
        return Icons.build;
      case 'Deportivo':
        return Icons.sports_soccer;
      case 'Social':
        return Icons.people;
      default:
        return Icons.event;
    }
  }
}

// 🔹 Card de Actividad Destacada
class _ActividadCard extends StatelessWidget {
  final String imageUrl;
  final String titulo;
  final String descripcion;
  final String categoria;

  const _ActividadCard({
    required this.imageUrl,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  descripcion,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoria,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Item de evento
class _EventoItem extends StatelessWidget {
  final String hora;
  final String titulo;
  final String lugar;
  final String categoria;
  final IconData icono;
  final String dia;

  const _EventoItem({
    required this.hora,
    required this.titulo,
    required this.lugar,
    required this.categoria,
    required this.icono,
    required this.dia,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  hora,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dia,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(lugar, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(icono, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      categoria,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
