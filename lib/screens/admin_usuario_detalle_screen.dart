import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_actividad_detalle_screen.dart';

// 💡 Colores reutilizados del AdminScreen
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _primaryTextColor = Colors.white;
const Color _secondaryTextColor = Color(0xFF668C98); // Color de las etiquetas secundarias
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminPrimaryColor = Color(0xFF07303B); // Para AppBar/Header

class AdminUsuarioDetalleScreen extends StatefulWidget {
  final String userId;
  final String userName; // Para mostrar en el AppBar mientras carga

  const AdminUsuarioDetalleScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUsuarioDetalleScreen> createState() => _AdminUsuarioDetalleScreenState();
}

class _AdminUsuarioDetalleScreenState extends State<AdminUsuarioDetalleScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> actividadesInscritas = [];
  List<Map<String, dynamic>> historialParticipacion = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // ----------------------------------------------------
  // Lógica de Carga de Datos
  // ----------------------------------------------------

  Future<void> _cargarDatosUsuario() async {
    // Cargar datos del usuario
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = userDoc.data();

    if (data == null) {
      setState(() {
        userData = {};
      });
      return;
    }

    // Buscar actividades en las que está inscrito este usuario
    final snapshot = await FirebaseFirestore.instance.collection('actividades').get();
    final List<Map<String, dynamic>> inscritas = [];
    final List<Map<String, dynamic>> historial = [];

    for (var doc in snapshot.docs) {
      // Intentamos castear la lista de inscritos de forma segura
      final inscritos = List<Map<String, dynamic>>.from(doc.data()['inscritos'] ?? [])
          .whereType<Map<String, dynamic>>() // Aseguramos que solo sean Maps
          .toList();

      final inscrito = inscritos.firstWhere(
            (i) => i['uid'] == widget.userId,
        orElse: () => {},
      );

      if (inscrito.isNotEmpty) {
        final actData = doc.data() as Map<String, dynamic>;
        final estado = inscrito['estado'] ?? 'en_curso';
        actData['estadoUsuario'] = estado;
        actData['id'] = doc.id; // 🔹 ID de la actividad para navegar

        // Agregamos a la lista correspondiente
        if (actData['estado'] == 'finalizada' || estado == 'finalizado') {
          historial.add(actData);
        } else if (estado == 'en_curso') {
          inscritas.add(actData);
        }
      }
    }

    setState(() {
      userData = data;
      actividadesInscritas = inscritas;
      historialParticipacion = historial;
    });
  }

  // ----------------------------------------------------
  // Widgets y Helper Functions
  // ----------------------------------------------------

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

  // Card de Actividad, adaptada al diseño Admin
  Widget _buildActividad(Map<String, dynamic> act, {bool terminado = false}) {
    final estadoUsuario = act['estadoUsuario'] ?? 'en_curso';
    final estadoActividad = act['estado'] ?? 'en_curso';
    final isFinalizado = estadoUsuario == 'finalizado' || estadoActividad == 'finalizada';

    Color colorBg = isFinalizado ? Colors.red.shade900.withOpacity(0.4) : _adminAccentColor.withOpacity(0.2);
    Color colorIcon = isFinalizado ? Colors.red.shade400 : _adminAccentColor;
    Color colorText = isFinalizado ? Colors.white70 : _primaryTextColor;

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalle de actividad de administración
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminActividadDetalleScreen(
              actividadData: act,
              actividadId: act['id'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _adminCardColor.withOpacity(0.5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconoCategoria(act['categoria'] ?? ''),
              color: colorIcon,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la actividad
                  Text(
                    act['nombre'] ?? 'Actividad sin nombre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Ubicación y Horario
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: _secondaryTextColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${act['ubicacion'] ?? 'N/A'} | ${act['hora_inicio'] ?? ''} - ${act['hora_fin'] ?? ''}',
                          style: const TextStyle(color: _secondaryTextColor, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Estado del Usuario en la Actividad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                estadoUsuario.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(color: colorIcon, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        backgroundColor: _adminBackgroundColor,
        appBar: AppBar(
          title: Text(widget.userName, style: const TextStyle(color: _primaryTextColor)),
          backgroundColor: _adminPrimaryColor,
          iconTheme: const IconThemeData(color: _adminAccentColor),
        ),
        body: const Center(child: CircularProgressIndicator(color: _adminAccentColor)),
      );
    }

    if (userData!.isEmpty) {
      return Scaffold(
        backgroundColor: _adminBackgroundColor,
        appBar: AppBar(
          title: Text(widget.userName, style: const TextStyle(color: _primaryTextColor)),
          backgroundColor: _adminPrimaryColor,
          iconTheme: const IconThemeData(color: _adminAccentColor),
        ),
        body: const Center(
            child: Text('Datos de usuario no encontrados.', style: TextStyle(color: _secondaryTextColor))),
      );
    }

    // ----------------------------------------------------
    // Estructura Principal
    // ----------------------------------------------------

    final nombre = userData!['nombre'] ?? '';
    final apellidoPaterno = userData!['apellido_paterno'] ?? '';
    final apellidoMaterno = userData!['apellido_materno'] ?? '';
    final nombreCompleto = '$nombre $apellidoPaterno $apellidoMaterno'.trim();
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: _adminBackgroundColor,
      appBar: AppBar(
        title: Text('Detalle de Usuario', style: const TextStyle(color: _primaryTextColor)),
        backgroundColor: _adminPrimaryColor,
        iconTheme: const IconThemeData(color: _adminAccentColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Foto de perfil como inicial
            CircleAvatar(
              radius: 50,
              backgroundColor: _adminAccentColor.withOpacity(0.2),
              child: Text(
                inicial,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: _adminAccentColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 🔹 Información Personal
            Text(
              nombreCompleto,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Matrícula: ${userData!['matricula'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 14, color: _secondaryTextColor),
            ),
            const SizedBox(height: 2),
            Text(
              userData!['email'] ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: _secondaryTextColor),
            ),
            const SizedBox(height: 30),

            // ------------------------------------------
            // 🔹 Actividades Inscritas
            // ------------------------------------------
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Actividades en curso (${actividadesInscritas.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryTextColor)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _adminCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: actividadesInscritas.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('El usuario no está inscrito en actividades activas.',
                    style: TextStyle(color: _secondaryTextColor)),
              )
                  : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: actividadesInscritas.length,
                itemBuilder: (context, index) {
                  return _buildActividad(actividadesInscritas[index]);
                },
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------
            // 🔹 Historial de Participación
            // ------------------------------------------
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Historial de participación (${historialParticipacion.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryTextColor)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _adminCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: historialParticipacion.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('El usuario no tiene historial de participación.',
                    style: TextStyle(color: _secondaryTextColor)),
              )
                  : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: historialParticipacion.length,
                itemBuilder: (context, index) {
                  return _buildActividad(historialParticipacion[index], terminado: true);
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}