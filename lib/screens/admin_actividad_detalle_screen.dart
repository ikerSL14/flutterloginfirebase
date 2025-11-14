import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 💡 Colores reutilizados del AdminScreen
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores/Inputs
const Color _adminLabelColor = Color(0xFF668C98); // Color de las etiquetas secundarias
const Color _adminErrorColor = Color(0xFFE57373); // Rojo suave para errores
const Color _adminPrimaryColor = Color(0xFF07303B);

class AdminActividadDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> actividadData;
  final String actividadId;

  const AdminActividadDetalleScreen({
    super.key,
    required this.actividadData,
    required this.actividadId,
  });

  @override
  State<AdminActividadDetalleScreen> createState() => _AdminActividadDetalleScreenState();
}

class _AdminActividadDetalleScreenState extends State<AdminActividadDetalleScreen> {
  // Usaremos un Stream para escuchar los cambios en tiempo real del documento (especialmente inscritos)
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _actividadStream;
  late String _currentId;

  @override
  void initState() {
    super.initState();
    _currentId = widget.actividadId;
    _actividadStream = FirebaseFirestore.instance.collection('actividades').doc(_currentId).snapshots();
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
    // Usamos imágenes de placeholder para el ambiente de desarrollo
    return 'https://placehold.co/1200x400/07303B/668C98?text=$categoria';
  }

  // ----------------------------------------------------
  // Lógica de Administración
  // ----------------------------------------------------

  /// Elimina un alumno del array 'inscritos'.
  Future<void> _eliminarInscrito(String uid, String nombreAlumno) async {
    // 💡 CORRECCIÓN: Se añade el 'context' como primer argumento.
    final bool confirm = await _showConfirmationDialog(
      context,
      'Eliminar Alumno',
      '¿Estás seguro de que deseas eliminar a $nombreAlumno de esta actividad?',
    );
    if (!confirm) return;

    final docRef = FirebaseFirestore.instance.collection('actividades').doc(_currentId);

    try {
      // Obtenemos los datos actuales (para evitar problemas de concurrencia)
      final docSnap = await docRef.get();
      List<dynamic> inscritos = docSnap.data()?['inscritos'] ?? [];

      // Filtramos la lista para quitar al alumno por su UID
      List<Map<String, dynamic>> nuevaLista = inscritos
          .cast<Map<String, dynamic>>()
          .where((item) => item['uid'] != uid)
          .toList();

      await docRef.update({'inscritos': nuevaLista});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nombreAlumno ha sido eliminado de la actividad.', style: const TextStyle(color: Colors.white)),
          backgroundColor: _adminAccentColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar inscrito: $e', style: TextStyle(color: _adminErrorColor)),
          backgroundColor: _adminCardColor,
        ),
      );
    }
  }

  /// Marca la actividad como 'finalizada' y actualiza el estado de todos los inscritos.
  Future<void> _marcarComoFinalizada() async {
    // 💡 CORRECCIÓN: Se añade el 'context' como primer argumento.
    final bool confirm = await _showConfirmationDialog(
      context,
      'Finalizar Actividad',
      'Esto marcará la actividad y a todos los alumnos inscritos como "finalizada". ¿Confirmar?',
      isDanger: true,
    );
    if (!confirm) return;

    final docRef = FirebaseFirestore.instance.collection('actividades').doc(_currentId);

    try {
      // 1. Obtenemos los datos actuales
      final docSnap = await docRef.get();
      List<dynamic> inscritos = docSnap.data()?['inscritos'] ?? [];

      // 2. Actualizamos el estado de cada inscrito a 'finalizado'
      List<Map<String, dynamic>> inscritosFinalizados = inscritos
          .cast<Map<String, dynamic>>()
          .map((item) {
        return {...item, 'estado': 'finalizado'};
      }).toList();

      // 3. Actualizamos el documento en Firestore
      await docRef.update({
        'estado': 'finalizada',
        'inscritos': inscritosFinalizados,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividad marcada como FINALIZADA con éxito.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar actividad: $e', style: TextStyle(color: _adminErrorColor)),
          backgroundColor: _adminCardColor,
        ),
      );
    }
  }

  // Diálogo de confirmación reutilizable
  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content, {bool isDanger = false}) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _adminCardColor,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(content, style: const TextStyle(color: _adminLabelColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: _adminLabelColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isDanger ? 'Confirmar' : 'Eliminar',
                style: TextStyle(color: isDanger ? _adminErrorColor : _adminAccentColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // ----------------------------------------------------
  // Widgets de Interfaz
  // ----------------------------------------------------

  // Widget para mostrar un alumno inscrito con botón de eliminar
  Widget _buildInscritoItem(Map<String, dynamic> alumno) {
    final nombre = alumno['nombre'] ?? 'Usuario Desconocido';
    final uid = alumno['uid'] ?? '';
    final estado = alumno['estado'] ?? 'en_curso';

    Color estadoColor;
    String estadoTexto;

    switch (estado) {
      case 'finalizado':
        estadoColor = Colors.blueAccent;
        estadoTexto = 'FINALIZADO';
        break;
      case 'cancelado':
        estadoColor = Colors.orange;
        estadoTexto = 'CANCELADO';
        break;
      default:
        estadoColor = _adminAccentColor;
        estadoTexto = 'EN CURSO';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: _adminLabelColor,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoTexto,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Botón de Eliminar (solo si tiene UID válido)
          if (uid.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: _adminErrorColor),
              tooltip: 'Eliminar inscrito',
              onPressed: () => _eliminarInscrito(uid, nombre),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _actividadStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: _adminErrorColor)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Usar los datos iniciales si no hay snapshot (mientras carga)
          final data = widget.actividadData;
          final nombre = data['nombre'] ?? 'Cargando...';

          return Scaffold(
            backgroundColor: _adminBackgroundColor,
            appBar: AppBar(
              title: Text(nombre, style: const TextStyle(color: Colors.white)),
              backgroundColor: _adminPrimaryColor,
              iconTheme: const IconThemeData(color: _adminAccentColor),
            ),
            body: const Center(child: CircularProgressIndicator(color: _adminAccentColor)),
          );
        }

        final data = snapshot.data!.data()!;
        final nombre = data['nombre'] ?? 'Actividad sin nombre';
        final estadoActividad = data['estado'] ?? 'en_curso';
        final List inscritos = data['inscritos'] ?? [];
        final bool isFinalizada = estadoActividad == 'finalizada';

        // Estilos para el estado general
        Color estadoColor;
        String estadoTexto;
        switch (estadoActividad) {
          case 'finalizada':
            estadoColor = Colors.blueAccent;
            estadoTexto = 'FINALIZADA';
            break;
          case 'cancelada':
            estadoColor = Colors.orange;
            estadoTexto = 'CANCELADA';
            break;
          default:
            estadoColor = _adminAccentColor;
            estadoTexto = 'EN CURSO';
        }


        return Scaffold(
          backgroundColor: _adminBackgroundColor,
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
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: _adminPrimaryColor,
                                  child: Center(
                                    child: Icon(_iconoCategoria(data['categoria'] ?? 'Otros'), size: 50, color: _adminLabelColor),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: CircleAvatar(
                                backgroundColor: _adminPrimaryColor.withOpacity(0.8),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: _adminAccentColor),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                            // Botón de Finalizar/Terminar
                            Positioned(
                              top: 18,
                              right: 18,
                              child: ElevatedButton.icon(
                                onPressed: isFinalizada ? null : _marcarComoFinalizada,
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                label: Text(isFinalizada ? 'FINALIZADA' : 'Terminar Actividad',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFinalizada ? Colors.red.shade900.withOpacity(0.5) : Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              Text(nombre,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 10),

                              // Estado General de la Actividad
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: estadoColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Estado: $estadoTexto',
                                    style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 12),

                              // Detalles de la Actividad
                              _buildDetailRow(
                                  Icons.category,
                                  'Categoría',
                                  data['categoria'] ?? '',
                                  _adminAccentColor
                              ),
                              _buildDetailRow(
                                  Icons.calendar_today,
                                  'Fecha',
                                  data['fecha_inicio'] != null && data['fecha_inicio'] is Timestamp
                                      ? DateFormat('d MMMM yyyy', 'es_ES')
                                      .format((data['fecha_inicio'] as Timestamp).toDate())
                                      : 'N/A',
                                  _adminLabelColor
                              ),
                              _buildDetailRow(
                                  Icons.access_time,
                                  'Horario',
                                  '${data['hora_inicio'] ?? ''} - ${data['hora_fin'] ?? ''}',
                                  _adminLabelColor
                              ),
                              _buildDetailRow(
                                  Icons.location_on,
                                  'Ubicación',
                                  data['ubicacion'] ?? '',
                                  _adminLabelColor
                              ),

                              const SizedBox(height: 12),
                              Text('Descripción', style: TextStyle(color: _adminLabelColor.withOpacity(0.7), fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(data['descripcion'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),

                              const SizedBox(height: 30),

                              // Lista de Alumnos Inscritos
                              Text('Alumnos Inscritos (${inscritos.length})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Divider(color: _adminCardColor, height: 20),

                              if (inscritos.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text(
                                      'Aún no hay alumnos inscritos.',
                                      style: TextStyle(color: _adminLabelColor),
                                    ),
                                  ),
                                )
                              else
                                ...inscritos.map((alumno) => _buildInscritoItem(alumno.cast<String, dynamic>())).toList(),

                              const SizedBox(height: 50), // Espacio inferior
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget auxiliar para las filas de detalle
  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: _adminLabelColor, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}