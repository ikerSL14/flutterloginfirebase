import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'screens/admin_screen.dart'; // Asegúrate que este archivo exista

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 1. Si NO hay usuario logueado, ir al LoginScreen
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // 🔹 2. Si hay usuario, consultar su ROL en Firestore
        final User user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(

          // 💡 --- SOLUCIÓN DEL BUG DEL ADMIN --- 💡
          // Le damos una Key ÚNICA al FutureBuilder basada en el uid.
          // Cuando el uid cambia (de usuario_normal a admin),
          // Flutter ve una Key diferente, destruye el FutureBuilder
          // anterior (y su estado 'role: usuario') y crea uno NUEVO,
          // forzando la re-ejecución del futuro.
          key: Key(user.uid),

          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            // Mostrar un cargando mientras obtenemos el rol
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.green)),
              );
            }

            // --- SECCIÓN DE DEPURACIÓN (igual) ---
            if (userSnapshot.hasError) {
              print("AuthGate Error: Error al leer Firestore: ${userSnapshot.error}");
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              print("AuthGate Error: No se encontró el documento 'users/${user.uid}' en Firestore.");
              print("Asegúrate que un documento exista en 'users/${user.uid}'");
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            }
            // --- FIN DE DEPURACIÓN ---


            // 🔹 3. Decidir la navegación basada en el rol (igual)
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] ?? 'usuario'; // Default a 'usuario' si el rol no está definido

            print("AuthGate Info: Usuario ${user.email} tiene rol '$role'.");

            if (role == 'admin') {
              // ¡Éxito para Admin!
              return const AdminScreen();
            } else {
              // ¡Éxito para Usuario!
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}