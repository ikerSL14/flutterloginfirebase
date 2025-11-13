import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditarPerfilScreen({super.key, required this.userData});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoPaternoController;
  late TextEditingController _apellidoMaternoController;
  late TextEditingController _matriculaController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _currentPasswordController;

  bool _guardando = false;
  bool _cambiarPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _nombreController =
        TextEditingController(text: widget.userData['nombre'] ?? '');
    _apellidoPaternoController =
        TextEditingController(text: widget.userData['apellido_paterno'] ?? '');
    _apellidoMaternoController =
        TextEditingController(text: widget.userData['apellido_materno'] ?? '');
    _matriculaController =
        TextEditingController(text: widget.userData['matricula'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _passwordController = TextEditingController();
    _currentPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _matriculaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _guardando = true);

    try {
      // 🔹 Reautenticación si se cambiará contraseña o correo
      if (_cambiarPassword || user.email != _emailController.text.trim()) {
        if (_currentPasswordController.text.trim().isEmpty) {
          throw Exception("Debes ingresar tu contraseña actual para continuar.");
        }

        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);
      }

      // 🔹 Actualizar Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nombre': _nombreController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'email': _emailController.text.trim(),
      });

      // 🔹 Actualizar correo si cambió
      if (user.email != _emailController.text.trim()) {
        await user.updateEmail(_emailController.text.trim());
      }

      // 🔹 Actualizar contraseña si se solicitó
      if (_cambiarPassword && _passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Encabezado verde con gradiente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade600,
                    Colors.green.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Editar perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                        value!.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidoPaternoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido paterno',
                          prefixIcon: Icon(Icons.badge),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                        value!.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidoMaternoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido materno',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                        value!.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // 🔸 Campo matrícula (gris, no editable)
                      TextFormField(
                        controller: _matriculaController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          labelText: 'Matrícula (no editable)',
                          prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                          border: const UnderlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email),
                          border: UnderlineInputBorder(),
                        ),
                        validator: (value) =>
                        value!.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Botón para cambiar contraseña
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.lock_outline, color: Colors.green),
                          label: Text(
                            _cambiarPassword
                                ? 'Cancelar cambio de contraseña'
                                : 'Cambiar contraseña',
                            style: const TextStyle(color: Colors.green),
                          ),
                          onPressed: () {
                            setState(() {
                              _cambiarPassword = !_cambiarPassword;
                              _passwordController.clear();
                              _currentPasswordController.clear();
                            });
                          },
                        ),
                      ),

                      // 🔹 Campos de contraseña (solo si se activa el cambio)
                      if (_cambiarPassword) ...[
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña actual',
                            prefixIcon: Icon(Icons.lock),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_cambiarPassword &&
                                (value == null || value.isEmpty)) {
                              return 'Ingresa tu contraseña actual';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon: Icon(Icons.lock_reset),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_cambiarPassword) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa la nueva contraseña';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardarCambios,
                        icon: _guardando
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.save_outlined, color: Colors.white),
                        label: Text(
                          _guardando ? 'Guardando...' : 'Guardar cambios',
                          style: const TextStyle(fontSize: 16,color: Colors.white, // 👈 Texto blanco
                            fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
