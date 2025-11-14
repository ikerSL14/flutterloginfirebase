import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 💡 Imports que faltaban en la vista anterior
import 'screens/inicio_screen.dart';
import 'screens/calendario_screen.dart';
import 'screens/notificaciones_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/buscar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _nombreUsuario; // solo la inicial

  int _notificacionesNoLeidas = 0;
  List<Map<String, dynamic>> _notificaciones = [];

  // 💡 Lista de Títulos completa
  final List<String> _titles = [
    'Inicio',
    'Calendario',
    'Notificaciones',
    'Registro',
    'Perfil',
    'Buscar'
  ];

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _cargarNotificaciones();
  }

  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          // 💡 SOLUCIÓN setState 1: Comprobar si el widget sigue "montado"
          if (mounted) {
            setState(() {
              _nombreUsuario = doc.data()?['nombre'] ?? '?';
            });
          }
        }
      } catch (e) {
        print("Error al obtener nombre de usuario: $e");
        // 💡 SOLUCIÓN setState 2: Comprobar si el widget sigue "montado"
        if (mounted) {
          setState(() {
            _nombreUsuario = '?';
          });
        }
      }
    }
  }

  Future<void> _cargarNotificaciones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 💡 Query de notificaciones completa
      final snapshot = await FirebaseFirestore.instance
          .collection('notificaciones')
          .orderBy('creadaEn', descending: true)
          .get();

      // 💡 Lógica de mapeo completa
      final notifs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // 💡 Lógica de filtro completa
      final noLeidas = notifs.where((n) {
        final leidos = List<String>.from(n['usuariosLeidos'] ?? []);
        return !leidos.contains(user.uid);
      }).toList();

      // 💡 SOLUCIÓN setState 3: Comprobar si el widget sigue "montado"
      if (mounted) {
        setState(() {
          _notificaciones = notifs;
          _notificacionesNoLeidas = noLeidas.length;
        });
      }
    } catch (e) {
      print("Error al cargar notificaciones: $e");
    }
  }

  void _recargarInicialesUsuario() {
    _cargarNombreUsuario(); // Esta es la función que actualiza el estado en HomeScreen
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages.clear();
    // 💡 Lista de Páginas completa
    _pages.addAll([
      InicioScreen(onNavigate: _onItemTapped),
      const CalendarioScreen(),
      const NotificacionesScreen(),
      const RegistroScreen(),
      PerfilScreen(onProfileUpdated: _recargarInicialesUsuario), // 💡 Pasar el callback
      const BuscarScreen(),
    ]);
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      await _marcarNotificacionesLeidas();
    }
  }

  Future<void> _marcarNotificacionesLeidas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    // 💡 Lógica de filtro completa
    final noLeidas = _notificaciones.where((n) {
      final leidos = List<String>.from(n['usuariosLeidos'] ?? []);
      return !leidos.contains(user.uid);
    });

    // 💡 Lógica de batch completa
    for (var notif in noLeidas) {
      final docRef = FirebaseFirestore.instance
          .collection('notificaciones')
          .doc(notif['id']);
      batch.update(docRef, {
        'usuariosLeidos': FieldValue.arrayUnion([user.uid])
      });
    }

    await batch.commit();
    _cargarNotificaciones();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // El if (context.mounted) aquí es correcto
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

  @override
  Widget build(BuildContext context) {
    // 💡 Widget Build COMPLETO
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.black),
                  onPressed: () => _onItemTapped(2),
                ),
                if (_notificacionesNoLeidas > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_notificacionesNoLeidas',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 40),
                onSelected: (value) {
                  if (value == 'logout') _logout();
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
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    _nombreUsuario != null && _nombreUsuario!.isNotEmpty
                        ? _nombreUsuario![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Registro'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
        ],
      ),
    );
  }
}