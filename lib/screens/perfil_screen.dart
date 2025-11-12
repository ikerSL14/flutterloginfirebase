import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'actividad_detalle_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> actividadesInscritas = [];
  List<Map<String, dynamic>> historialParticipacion = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data();

    final snapshot = await FirebaseFirestore.instance.collection('actividades').get();
    final List<Map<String, dynamic>> inscritas = [];
    final List<Map<String, dynamic>> historial = [];

    for (var doc in snapshot.docs) {
      final inscritos = List<Map<String, dynamic>>.from(doc['inscritos'] ?? []);
      final inscrito = inscritos.firstWhere(
            (i) => i['uid'] == user.uid,
        orElse: () => {},
      );

      if (inscrito.isNotEmpty) {
        final actData = doc.data() as Map<String, dynamic>;
        final estado = inscrito['estado'] ?? 'en_curso';
        actData['estadoUsuario'] = estado;
        actData['id'] = doc.id; // 🔹 Importante para pasar a detalle

        if (estado == 'en_curso') {
          inscritas.add(actData);
        } else if (estado == 'terminado') {
          historial.add(actData);
        }
      }
    }

    setState(() {
      userData = data;
      actividadesInscritas = inscritas;
      historialParticipacion = historial;
    });
  }

  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Académico':
        return Icons.school;
      case 'Deportivo':
        return Icons.sports_soccer;
      case 'Social':
        return Icons.people;
      case 'Cultural':
        return Icons.brush;
      default:
        return Icons.event;
    }
  }

  Widget _buildActividad(Map<String, dynamic> act, {bool terminado = false}) {
    final estado = terminado ? 'TERMINADO' : (act['estadoUsuario'] ?? 'EN_CURSO');
    final colorBg = terminado ? Colors.grey.shade300 : Colors.green.shade700;
    final colorText = terminado ? Colors.grey.shade800 : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActividadDetalleScreen(
              actividadData: act,
              actividadId: act['id'], // 🔹 Asegúrate de tener el ID en act
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconoCategoria(act['categoria'] ?? ''),
            color: terminado ? Colors.grey : Colors.green.shade700,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act['nombre'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: terminado ? Colors.grey.shade800 : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 3),
                        Text(
                          '${act['hora_inicio'] ?? ''} - ${act['hora_fin'] ?? ''}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              act['ubicacion'] ?? '',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              estado.toUpperCase(),
              style: TextStyle(color: colorText, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 🔹 Foto de perfil como inicial
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green.shade100,
            child: Text(
              (userData!['nombre'] != null && userData!['nombre'].isNotEmpty)
                  ? userData!['nombre'][0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 🔹 Nombre completo
          Text(
            '${userData!['nombre'] ?? ''} ${userData!['apellido_paterno'] ?? ''} ${userData!['apellido_materno'] ?? ''}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'Matrícula: ${userData!['matricula'] ?? ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 2),
          Text(
            '${userData!['email'] ?? ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Editar perfil', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 50),

          // 🔹 Actividades inscritas
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Actividades inscritas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(height: 12),
          if (actividadesInscritas.isEmpty)
            const Text('No estás inscrito en ninguna actividad', style: TextStyle(color: Colors.black54)),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: actividadesInscritas.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              return _buildActividad(actividadesInscritas[index]);
            },
          ),

          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Historial de participación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(height: 12),
          if (historialParticipacion.isEmpty)
            const Text('No tienes historial de participación', style: TextStyle(color: Colors.black54)),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: historialParticipacion.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              return _buildActividad(historialParticipacion[index], terminado: true);
            },
          ),
        ],
      ),
    );
  }
}
