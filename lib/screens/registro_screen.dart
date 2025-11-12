import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'actividad_detalle_screen.dart'; // Importa la pantalla de detalle

class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Actividades disponibles",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Explora y regístrate en los talleres, conferencias y programas que ofrece la universidad.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                "Próximas actividades",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // 🔥 StreamBuilder que carga las actividades en orden por fecha_inicio
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('actividades')
                      .where('fecha_inicio', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
                      .orderBy('fecha_inicio')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No hay actividades próximas.'),
                      );
                    }

                    final actividades = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: actividades.length,
                      itemBuilder: (context, index) {
                        final doc = actividades[index];
                        final data = doc.data() as Map<String, dynamic>;

                        // 🔹 Abrir detalle al tocar
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActividadDetalleScreen(
                                  actividadData: data,
                                  actividadId: doc.id,
                                ),
                              ),
                            );
                          },
                          child: _ActividadCard(data: data, id: doc.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget que muestra cada actividad individual
class _ActividadCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;

  const _ActividadCard({required this.data, required this.id});

  Future<void> _inscribirse(BuildContext context, String idActividad) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para inscribirte.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 📥 Obtener datos del usuario
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final nombreUsuario = userData != null
        ? '${userData['nombre']} ${userData['apellido_paterno']} ${userData['apellido_materno']}'
        : 'Sin nombre';

    final docRef = FirebaseFirestore.instance.collection('actividades').doc(idActividad);
    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>?;

    final List inscritos = data?['inscritos'] ?? [];
    final bool yaInscrito = inscritos.any((item) => item['uid'] == user.uid);

    if (yaInscrito) return;

    try {
      await docRef.update({
        'inscritos': FieldValue.arrayUnion([
          {'uid': user.uid, 'nombre': nombreUsuario, 'estado': 'en_curso'}
        ]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscripción realizada con éxito 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al inscribirse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Académico':
        return Icons.school;
      case 'Deportivo':
        return Icons.sports_soccer;
      case 'Cultural':
        return Icons.theater_comedy;
      case 'Social':
        return Icons.people;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final List inscritos = data['inscritos'] ?? [];
    final bool inscrito = user != null && inscritos.any((item) => item['uid'] == user.uid);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['foto'] != null && data['foto'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data['foto'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              data['nombre'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  _iconoCategoria(data['categoria'] ?? ''),
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 5),
                Text(
                  data['categoria'] ?? '',
                  style: const TextStyle(color: Colors.green, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  data['fecha_inicio'] != null && data['fecha_inicio'] is Timestamp
                      ? DateFormat('d MMMM yyyy', 'es_ES').format((data['fecha_inicio'] as Timestamp).toDate())
                      : '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  '${data['hora_inicio'] ?? ''} - ${data['hora_fin'] ?? ''}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  data['ubicacion'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['descripcion'] ?? '',
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: inscrito ? Colors.grey : Colors.green,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: inscrito ? null : () => _inscribirse(context, id),
                child: Text(
                  inscrito ? 'Inscrito' : 'Inscribirse',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
