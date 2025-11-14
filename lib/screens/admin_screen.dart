import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importamos los paquetes para las pantallas de administración
import '../screens/placeholder_screen.dart';
import '../screens/admin_inicio_screen.dart';
import '../screens/admin_eventos_screen.dart';
// 💡 Importar la nueva pantalla de Notificaciones
import '../screens/admin_notificaciones_screen.dart';
import '../screens/admin_actividades_screen.dart';
import '../screens/admin_usuario_screen.dart';

// 💡 Definimos los colores personalizados
const Color _adminPrimaryColor = Color(0xFF07303B); // Azul/Verde muy oscuro
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante para íconos
const Color _adminTextColor = Color(0xFF50727D); // Gris azulado para texto inactivo
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla más oscuro
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores (para uso futuro)


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}


class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // 1. Definición de las pantallas internas del Administrador
  final List<Widget> _pages = [
    const AdminInicioScreen(),
    const AdminEventosScreen(),
    // 💡 CAMBIO: Usamos AdminNotificacionesScreen en el índice 2
    const AdminNotificacionesScreen(),
    const AdminActividadesScreen(),
    const AdminUsuarioScreen(),
  ];

  // 2. Definición de los títulos del AppBar
  final List<String> _titles = [
    'Inicio',
    'Eventos',
    'Notificaciones', // 💡 Título actualizado para Notificaciones
    'Actividades',
    'Usuarios',
  ];

  // 3. Método para manejar la selección de la barra inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 4. Método para cerrar sesión
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesión de Admin cerrada.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _adminBackgroundColor, // Fondo general de la pantalla
      appBar: AppBar(
        // Color de la AppBar
        backgroundColor: _adminPrimaryColor,
        elevation: 0,
        title: Text(
          // Título dinámico
          'Panel Admin: ${_titles[_selectedIndex]}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // El texto del título principal queda blanco para alto contraste
          ),
        ),
        centerTitle: true,
        actions: [
          // 5. Botón de Configuración/Logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: _adminAccentColor),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: _pages[_selectedIndex], // Muestra la pantalla seleccionada

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _adminPrimaryColor, // Color de fondo de la barra
        selectedItemColor: _adminAccentColor, // Verde para el seleccionado
        unselectedItemColor: _adminTextColor, // Gris para el no seleccionado
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Actividades'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
        ],
      ),
    );
  }
}