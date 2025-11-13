import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00E649), // verde más vivo arriba
              Color(0xFF046709), // verde más oscuro hacia el fondo
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ===== ICONOS DECORATIVOS =====
            Positioned(
              top: 80,
              left: 30,
              child: Icon(Icons.school,
                  color: Colors.white.withOpacity(0.15), size: 70),
            ),
            Positioned(
              top: 150,
              right: 40,
              child: Icon(Icons.sports_soccer,
                  color: Colors.white.withOpacity(0.15), size: 60),
            ),
            Positioned(
              top: 40,
              right: 90,
              child: Icon(Icons.calendar_month,
                  color: Colors.white.withOpacity(0.32), size: 65),
            ),
            Positioned(
              top: 220,
              left: 60,
              child: Icon(Icons.emoji_events,
                  color: Colors.white.withOpacity(0.22), size: 55),
            ),
            Positioned(
              top: 275,
              right: 90,
              child: Icon(Icons.access_time_filled,
                  color: Colors.white.withOpacity(0.15), size: 55),
            ),
            Positioned(
              top: 310,
              left: 140,
              child: Icon(Icons.notifications,
                  color: Colors.white.withOpacity(0.15), size: 55),
            ),

            // ===== LOGO =====
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: size.height * 0.12),
                child: Image.asset(
                  'assets/images/xtraujat.png',
                  height: 150,
                ),
              ),
            ),

            // ===== CONTENEDOR BLANCO =====
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: size.height * 0.55,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // ===== INPUT CORREO =====
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // ===== INPUT CONTRASEÑA =====
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // ===== BOTÓN ENTRAR =====
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              shadowColor:
                              const Color(0xFF1B5E20).withOpacity(0.5),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ===== LINK REGISTRO =====
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            '¿No tienes cuenta? Regístrate',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
