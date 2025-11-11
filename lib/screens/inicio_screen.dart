import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InicioScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const InicioScreen({super.key, required this.onNavigate});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 AppBar fija arriba (permanece al hacer scroll)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Inicio",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () => widget.onNavigate(2),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 40),
                onSelected: (value) async {
                  if (value == 'logout') {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Sesión cerrada correctamente."),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error al cerrar sesión: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
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

              // 🔹 Primera fila más compacta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _accesoRapido(context, "Calendario", Icons.calendar_today, 1),
                  _accesoRapido(context, "Registro", Icons.edit_note, 3),
                  _accesoRapido(context, "Notificaciones", Icons.notifications, 2),
                ],
              ),

              const SizedBox(height: 15),

              // 🔹 Segunda fila centrada y separada
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
                children: const [
                  Text(
                    "Actividades destacadas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Ver todo",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 🔹 Cards horizontales
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _ActividadCard(
                      imageUrl:
                      'https://images.unsplash.com/photo-1519389950473-47ba0277781c',
                      titulo: 'Taller de programación',
                      descripcion:
                      'Aprende lógica, Flutter y Firebase desde cero...',
                      categoria: 'Académico',
                    ),
                    SizedBox(width: 16),
                    _ActividadCard(
                      imageUrl:
                      'https://images.unsplash.com/photo-1517649763962-0c623066013b',
                      titulo: 'Torneo interfacultades',
                      descripcion:
                      'Compite y representa a tu facultad en este torneo...',
                      categoria: 'Deportivo',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 Próximos eventos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Próximos eventos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Ver todo",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // 🔹 Lista de eventos
              Column(
                children: const [
                  _EventoItem(
                    hora: "10:00 A.M.",
                    titulo: "Conferencia: Inteligencia artificial",
                    lugar: "Auditorio Principal, Edificio A",
                    categoria: "Conferencia",
                    icono: Icons.computer,
                  ),
                  _EventoItem(
                    hora: "12:00 P.M.",
                    titulo: "Taller de Robótica",
                    lugar: "Laboratorio 3, Edificio B",
                    categoria: "Taller",
                    icono: Icons.smart_toy,
                  ),
                  _EventoItem(
                    hora: "3:00 P.M.",
                    titulo: "Partido de fútbol",
                    lugar: "Campo Deportivo",
                    categoria: "Deportivo",
                    icono: Icons.sports_soccer,
                  ),
                  _EventoItem(
                    hora: "5:00 P.M.",
                    titulo: "Reunión estudiantil",
                    lugar: "Sala 101, Edificio C",
                    categoria: "Social",
                    icono: Icons.group,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Widget de Acceso Rápido
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

  const _EventoItem({
    required this.hora,
    required this.titulo,
    required this.lugar,
    required this.categoria,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Centrado vertical
        children: [
          SizedBox(
            width: 80,
            child: Text(
              hora,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
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
