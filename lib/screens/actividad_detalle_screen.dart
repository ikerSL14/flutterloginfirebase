import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActividadDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> actividadData;
  final String actividadId;

  const ActividadDetalleScreen({super.key, required this.actividadData, required this.actividadId});

  @override
  State<ActividadDetalleScreen> createState() => _ActividadDetalleScreenState();
}

class _ActividadDetalleScreenState extends State<ActividadDetalleScreen> {
  late Map<String, dynamic> data;
  late String id;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    data = widget.actividadData;
    id = widget.actividadId;
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Académico':
        return Icons.school;
      case 'Cultural':
        return Icons.theater_comedy;
      case 'Social':
        return Icons.people;
      case 'Deportivo':
        return Icons.sports_soccer;
      default:
        return Icons.event;
    }
  }

  String _imagenPorCategoria(String categoria) {
    switch (categoria) {
      case 'Académico':
        return 'https://images.unsplash.com/photo-1581090700227-4c08c31e4f7b';
      case 'Cultural':
        return 'https://images.unsplash.com/photo-1511376777868-611b54f68947';
      case 'Social':
        return 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f';
      case 'Deportivo':
        return 'https://images.unsplash.com/photo-1521412644187-c49fa049e84d';
      default:
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e';
    }
  }

  Future<void> _inscribirse() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para inscribirte.'), backgroundColor: Colors.red),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final nombreUsuario = userDoc.data() != null
        ? '${userDoc['nombre']} ${userDoc['apellido_paterno'] ?? ''} ${userDoc['apellido_materno'] ?? ''}'
        : 'Sin nombre';

    final docRef = FirebaseFirestore.instance.collection('actividades').doc(id);
    final docSnap = await docRef.get();
    final List inscritos = docSnap.data()?['inscritos'] ?? [];

    final bool yaInscrito = inscritos.any((item) => item['uid'] == user!.uid);
    if (yaInscrito) return;

    try {
      await docRef.update({
        'inscritos': FieldValue.arrayUnion([
          {'uid': user!.uid, 'nombre': nombreUsuario, 'estado': 'en_curso'}
        ]),
      });
      setState(() {
        data['inscritos'] = [...inscritos, {'uid': user!.uid, 'nombre': nombreUsuario, 'estado': 'en_curso'}];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripción realizada con éxito 🎉'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inscribirse: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List inscritos = data['inscritos'] ?? [];
    final bool inscrito = user != null && inscritos.any((i) => i['uid'] == user!.uid);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                          child: Image.network(
                            (data['foto'] != null && data['foto'].toString().isNotEmpty)
                                ? data['foto']
                                : _imagenPorCategoria(data['categoria'] ?? 'Otros'),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.white70,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['nombre'] ?? '',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(_iconoCategoria(data['categoria'] ?? ''), color: Colors.green),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(data['categoria'] ?? '', style: TextStyle(color: Colors.green.shade800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                data['fecha_inicio'] != null && data['fecha_inicio'] is Timestamp
                                    ? DateFormat('d MMMM yyyy', 'es_ES')
                                    .format((data['fecha_inicio'] as Timestamp).toDate())
                                    : '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('${data['hora_inicio'] ?? ''} - ${data['hora_fin'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(data['ubicacion'] ?? '', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(data['descripcion'] ?? '', style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 20),
                          const Text('Alumnos inscritos',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: inscritos.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final alumno = inscritos[index];
                              final estado = alumno['estado'] ?? 'en_curso';
                              return Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 20,
                                    child: Icon(Icons.person, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(alumno['nombre'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: estado == 'en_curso'
                                                ? Colors.green.shade800
                                                : Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            estado == 'en_curso' ? 'En curso' : 'Terminado',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 80), // espacio para el botón fijo
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Botón fijo abajo
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: inscrito ? null : _inscribirse,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: inscrito ? Colors.grey : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(inscrito ? 'Inscrito' : 'Inscribirse',
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
