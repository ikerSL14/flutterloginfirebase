import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No hay usuario logueado"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notificaciones')
          .orderBy('creadaEn', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final notificaciones = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Filtramos notificaciones borradas por el usuario
        final visibles = notificaciones.where((n) {
          final borradas = List<String>.from(n['usuariosBorrados'] ?? []);
          return !borradas.contains(user.uid);
        }).toList();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 70), // espacio para el botón
              child: visibles.isEmpty
                  ? const Center(
                child: Text(
                  "No hay notificaciones",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visibles.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Nuevas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  final n = visibles[index - 1];
                  return _notificacionCard(n);
                },
              ),
            ),
            if (visibles.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: ElevatedButton(
                  onPressed: () => _limpiarTodas(visibles, user.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800, // verde fuerte
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // ligeramente redondeado
                    ),
                  ),
                  child: const Text(
                    'Limpiar todas',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _notificacionCard(Map<String, dynamic> n) {
    final fecha = n['fecha'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(
      (n['fecha'] as Timestamp).toDate(),
    )
        : '';
    final categoria = n['categoria'] ?? '';

    IconData _iconoNotificacion(String tipo) {
      switch (tipo) {
        case 'evento':
          return Icons.event;
        case 'actividad':
          return Icons.sports_soccer;
        case 'terminacion':
          return Icons.celebration;
        default:
          return Icons.notifications;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconoNotificacion(n['tipo'] ?? ''),
              color: Colors.green, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['titulo'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  n['descripcion'] ?? '',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (categoria.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_soccer,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(categoria,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(fecha,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
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

  Future<void> _limpiarTodas(
      List<Map<String, dynamic>> visibles, String uid) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var notif in visibles) {
      final docRef = FirebaseFirestore.instance
          .collection('notificaciones')
          .doc(notif['id']);
      batch.update(docRef, {
        'usuariosBorrados': FieldValue.arrayUnion([uid])
      });
    }

    await batch.commit();
  }
}

