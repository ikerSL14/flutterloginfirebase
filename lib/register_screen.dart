import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoPController = TextEditingController();
  final TextEditingController apellidoMController = TextEditingController();
  final TextEditingController matriculaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // 🔹 Crear usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String fotoUrl = '';

      // 🔹 Subir imagen a Firebase Storage si hay imagen seleccionada
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('usuarios/${userCredential.user!.uid}/perfil.jpg');

        await storageRef.putFile(_imageFile!);
        fotoUrl = await storageRef.getDownloadURL(); // 🔹 Esta es la URL pública
      }

      // 🔹 Guardar datos en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nombre': nombreController.text.trim(),
        'apellido_paterno': apellidoPController.text.trim(),
        'apellido_materno': apellidoMController.text.trim(),
        'matricula': matriculaController.text.trim(),
        'email': emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'role': 'usuario',
        'fotoPerfil': '', // Guardamos la URL, no el path local
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada exitosamente')),
      );

      Navigator.pop(context); // 🔹 Regresa al login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(25),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Registro de Usuario',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 📷 Selector de imagen
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🧍 Campos de texto
                    _buildTextField(nombreController, 'Nombre', Icons.person),
                    _buildTextField(apellidoPController, 'Apellido paterno', Icons.person_outline),
                    _buildTextField(apellidoMController, 'Apellido materno', Icons.person_outline),
                    _buildTextField(matriculaController, 'Matrícula (9 dígitos)', Icons.badge,
                        keyboardType: TextInputType.number, validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa la matrícula';
                          if (value.length != 9) return 'Debe tener 9 dígitos';
                          return null;
                        }),
                    _buildTextField(emailController, 'Correo', Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField(passwordController, 'Contraseña', Icons.lock,
                        obscure: true),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Registrar cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) return 'Campo obligatorio';
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green[700]),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

