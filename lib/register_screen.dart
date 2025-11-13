import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final apellidoPController = TextEditingController();
  final apellidoMController = TextEditingController();
  final matriculaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nombre': nombreController.text.trim(),
        'apellido_paterno': apellidoPController.text.trim(),
        'apellido_materno': apellidoMController.text.trim(),
        'matricula': matriculaController.text.trim(),
        'email': emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'role': 'usuario',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada exitosamente')),
      );

      Navigator.pop(context);
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
              Color(0xFF00C53E), // Verde vivo arriba
              Color(0xFF014204), // Verde oscuro abajo
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ===== BOTÓN DE REGRESAR =====
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),

            // ===== TÍTULO REGISTRO =====
            Positioned(
              top: size.height * 0.10,
              left: 0,
              right: 0,
              child: const Center(
                child: Column(
                  children: [
                    Text(
                      'Registro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Crea tu cuenta en el sistema',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== FORMULARIO (CONTENEDOR BLANCO) =====
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: size.height * 0.70,
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 5),

                          // ===== INPUTS =====
                          _buildTextField(nombreController, 'Nombre',
                              Icons.person_outline),
                          const SizedBox(height: 15),
                          _buildTextField(apellidoPController,
                              'Apellido paterno', Icons.person),
                          const SizedBox(height: 15),
                          _buildTextField(apellidoMController,
                              'Apellido materno', Icons.person),
                          const SizedBox(height: 15),
                          _buildTextField(
                            matriculaController,
                            'Matrícula (9 dígitos)',
                            Icons.badge,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa la matrícula';
                              }
                              if (value.length != 9) {
                                return 'Debe tener 9 dígitos';
                              }
                              return null;
                            },
                            maxLength: 9,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(emailController, 'Correo',
                              Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 15),
                          _buildTextField(passwordController, 'Contraseña',
                              Icons.lock_outline,
                              obscure: true),
                          const SizedBox(height: 30),

                          // ===== BOTÓN REGISTRAR =====
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: register,
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
                                'Registrar cuenta',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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

  // ===== INPUT STYLE =====
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
        int? maxLength,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator ??
              (value) {
            if (value == null || value.isEmpty) return 'Campo obligatorio';
            return null;
          },
      maxLength: maxLength,
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        labelStyle: const TextStyle(color: Colors.black87),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
