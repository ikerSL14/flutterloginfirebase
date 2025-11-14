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

class AdminActividadEditScreen extends StatefulWidget {
  final Map<String, dynamic>? actividad;

  // Si actividad es null, estamos creando. Si no, estamos editando.
  const AdminActividadEditScreen({super.key, this.actividad});

  @override
  State<AdminActividadEditScreen> createState() => _AdminActividadEditScreenState();
}

class _AdminActividadEditScreenState extends State<AdminActividadEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto (Adaptados a los campos de Actividad)
  final TextEditingController _nombreController = TextEditingController(); // Antes: _tituloController
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();

  // Estado del formulario
  DateTime? _fechaInicioSeleccionada; // Antes: _fechaSeleccionada
  String? _categoriaSeleccionada;
  String? _estadoSeleccionado; // Nuevo campo en Actividades
  bool _isLoading = false;

  // Listas de opciones
  final List<String> _categorias = [
    'Académico', 'Deportivo', 'Social', 'Cultural', 'Otro',
  ];
  final List<String> _estados = [
    'en_curso',
    'cancelada', // Adaptado a femenino
    'finalizada' // Adaptado a femenino
  ];

  @override
  void initState() {
    super.initState();
    // 💡 Si se pasa una actividad (modo edición), pre-cargar los datos
    if (widget.actividad != null) {
      final a = widget.actividad!;
      _nombreController.text = a['nombre'] ?? '';
      _descripcionController.text = a['descripcion'] ?? '';
      _ubicacionController.text = a['ubicacion'] ?? '';

      // CRÍTICO: Asegurarse de que las horas cargadas del String tengan formato HH:MM
      _horaInicioController.text = _formatTime(a['hora_inicio'] ?? ''); // Campo hora_inicio
      _horaFinController.text = _formatTime(a['hora_fin'] ?? ''); // Campo hora_fin

      _fotoController.text = a['foto'] ?? '';
      _categoriaSeleccionada = a['categoria'];
      _estadoSeleccionado = a['estado'] ?? 'en_curso'; // Carga el estado, por defecto 'en_curso'

      if (a['fecha_inicio'] is Timestamp) { // Campo fecha_inicio
        final utcTime = (a['fecha_inicio'] as Timestamp).toDate();
        _fechaInicioSeleccionada = DateTime(utcTime.year, utcTime.month, utcTime.day);
      }
    } else {
      // 💡 En modo creación, forzar el estado inicial a 'en_curso'
      _estadoSeleccionado = 'en_curso';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // Lógica de Ayuda para Timestamp y Formato de Texto
  // ----------------------------------------------------

  /// Valida que la cadena de tiempo tenga un formato HH:MM válido.
  String? _timeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hora requerida.';
    }
    final parts = value.trim().split(':');
    if (parts.length != 2) {
      return 'Formato debe ser HH:MM (Ej: 17:00).';
    }

    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());

    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return 'Hora o minuto inválido (00:00 a 23:59).';
    }

    return null;
  }

  /// Formatea la cadena de tiempo HH:MM asegurando ceros a la izquierda.
  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';

    final parts = timeString.split(':');
    if (parts.length != 2) return timeString;

    final hour = int.tryParse(parts[0].trim()) ?? 0;
    final minute = int.tryParse(parts[1].trim()) ?? 0;

    // Aseguramos que tanto la hora como el minuto tengan dos dígitos
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // 💡 Crea un punto de tiempo "fake UTC" y le aplica la compensación manual (+6 horas).
  // Esto asegura que la fecha guardada sea la correcta para UTC-6
  int _getCombinedMillisecondsWithOffset() {
    final date = _fechaInicioSeleccionada!;
    final timeString = _horaInicioController.text.trim();

    int hour = 0;
    int minute = 0;

    // Intentamos parsear la hora
    final parts = timeString.split(':');
    if (parts.length == 2) {
      hour = int.tryParse(parts[0].trim()) ?? 0;
      minute = int.tryParse(parts[1].trim()) ?? 0;
    }

    // 1. Creamos un DateTime en UTC con la hora ingresada (Ej: 17:00Z)
    DateTime desiredUtcDateTime = DateTime.utc(date.year, date.month, date.day, hour, minute);

    // 2. CRÍTICO: Sumamos la compensación de 6 horas (para UTC-6)
    desiredUtcDateTime = desiredUtcDateTime.add(const Duration(hours: 6));

    // 3. Retornamos los milisegundos para control total del Timestamp.
    return desiredUtcDateTime.millisecondsSinceEpoch;
  }

  // 💡 Obtiene el Timestamp de la hora actual con compensación.
  Timestamp _getCreationTimestampWithOffset() {
    // 1. Obtiene la hora actual en UTC
    DateTime nowUtc = DateTime.now().toUtc();

    // 2. Sumamos la compensación de 6 horas
    DateTime compensatedUtc = nowUtc.add(const Duration(hours: 6));

    // 3. Retornamos el Timestamp compensado
    return Timestamp.fromMillisecondsSinceEpoch(compensatedUtc.millisecondsSinceEpoch);
  }

  // ----------------------------------------------------
  // Lógica de Guardado, Actualización y Eliminación
  // ----------------------------------------------------

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _fechaInicioSeleccionada == null || _categoriaSeleccionada == null || _estadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos requeridos y verifica el formato de las horas (HH:MM).', style: TextStyle(color: _adminErrorColor))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String docId = widget.actividad?['id'] ?? FirebaseFirestore.instance.collection('actividades').doc().id;
    final bool isEditing = widget.actividad != null;

    // --- Datos Comunes ---
    final int combinedDateTimeMs = _getCombinedMillisecondsWithOffset();
    final formattedHoraInicio = _formatTime(_horaInicioController.text);
    final formattedHoraFin = _formatTime(_horaFinController.text);

    // Si estamos creando, inicializamos el array de inscritos
    final List<Map<String, dynamic>> inscritos = isEditing
        ? (widget.actividad!['inscritos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()
        : [];

    // --- 1. Datos de la Actividad (Adaptado a campos de Actividades) ---
    Map<String, dynamic> actividadData = {
      'nombre': _nombreController.text.trim(), // Nombre en lugar de titulo
      'descripcion': _descripcionController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'hora_inicio': formattedHoraInicio, // hora_inicio en lugar de horaInicio
      'hora_fin': formattedHoraFin, // hora_fin en lugar de horaFin
      'foto': _fotoController.text.trim(),
      'categoria': _categoriaSeleccionada,
      'fecha_inicio': Timestamp.fromMillisecondsSinceEpoch(combinedDateTimeMs), // fecha_inicio
      'id': docId,
      'estado': _estadoSeleccionado,
      'inscritos': inscritos, // Aseguramos que el campo exista al crear
    };

    try {
      // 1. Guardar/Actualizar Actividad
      await FirebaseFirestore.instance.collection('actividades').doc(docId).set(actividadData);

      // 2. Crear Notificación (SOLO si es una actividad nueva)
      if (!isEditing) {
        final notificationData = {
          'categoria': _categoriaSeleccionada,
          'creadaEn': _getCreationTimestampWithOffset(),
          'descripcion': _descripcionController.text.trim(),
          'fecha': Timestamp.fromMillisecondsSinceEpoch(combinedDateTimeMs), // Usamos la fecha de la actividad
          'tipo': 'actividad',
          'titulo': 'Nueva actividad: ${actividadData['nombre']}', // Título adaptado
          'ubicacion': _ubicacionController.text.trim(),
          'usuariosBorrados': [],
          'usuariosLeidos': [],
        };

        await FirebaseFirestore.instance.collection('notificaciones').add(notificationData);
      }

      // 3. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Actividad actualizada con éxito.' : 'Actividad y notificación creadas con éxito.', style: const TextStyle(color: Colors.white)), backgroundColor: _adminAccentColor),
      );
      if (context.mounted) Navigator.pop(context, true); // Regresar y refrescar
    } catch (e) {
      print('Error al guardar/actualizar actividad o crear notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la actividad: $e', style: TextStyle(color: _adminErrorColor))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.actividad == null) return;

    final bool confirm = await _showConfirmationDialog(context);
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('actividades').doc(widget.actividad!['id']).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad eliminada con éxito.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      if (context.mounted) Navigator.pop(context, true); // Regresar y refrescar
    } catch (e) {
      print('Error al eliminar actividad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la actividad: $e', style: TextStyle(color: _adminErrorColor))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Diálogo de confirmación para la eliminación
  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _adminCardColor,
          title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
          content: Text('¿Estás seguro de que deseas eliminar la actividad "${widget.actividad!['nombre']}"?', style: const TextStyle(color: _adminLabelColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: _adminLabelColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: _adminErrorColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // ----------------------------------------------------
  // Widgets de Interfaz
  // ----------------------------------------------------

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: validator ?? (value) => value!.isEmpty ? 'Campo requerido.' : null,
        keyboardType: label.contains('Hora') ? TextInputType.datetime : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _adminLabelColor),
          filled: true,
          fillColor: _adminCardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _adminAccentColor, width: 2),
          ),
        ),
      ),
    );
  }

  // Selector de Categoría
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _categoriaSeleccionada,
      decoration: InputDecoration(
        labelText: 'Categoría',
        labelStyle: const TextStyle(color: _adminLabelColor),
        filled: true,
        fillColor: _adminCardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _adminAccentColor, width: 2)),
      ),
      dropdownColor: _adminPrimaryColor,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: _adminAccentColor,
      items: _categorias.map((String cat) {
        return DropdownMenuItem<String>(
          value: cat,
          child: Text(cat, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _categoriaSeleccionada = newValue;
        });
      },
      validator: (value) => value == null ? 'Selecciona una categoría.' : null,
    );
  }

  // Selector de Estado
  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _estadoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Estado',
        labelStyle: const TextStyle(color: _adminLabelColor),
        filled: true,
        fillColor: _adminCardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _adminAccentColor, width: 2)),
      ),
      dropdownColor: _adminPrimaryColor,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: _adminAccentColor,
      onChanged: (String? newValue) {
        setState(() {
          _estadoSeleccionado = newValue;
        });
      },
      items: _estados.map((String status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      validator: (value) => value == null ? 'Selecciona un estado.' : null,
    );
  }

  // Selector de Fecha
  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _pickDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Fecha de Inicio de Actividad', // Texto adaptado
            labelStyle: const TextStyle(color: _adminLabelColor),
            filled: true,
            fillColor: _adminCardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _adminAccentColor, width: 2)),
          ),
          child: Text(
            _fechaInicioSeleccionada == null
                ? 'Seleccionar fecha'
                : DateFormat('dd/MM/yyyy').format(_fechaInicioSeleccionada!),
            style: TextStyle(color: _fechaInicioSeleccionada == null ? _adminLabelColor : Colors.white),
          ),
        ),
      ),
    );
  }

  // Picker de Fecha
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicioSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _adminAccentColor,
              onPrimary: Colors.white,
              surface: _adminPrimaryColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _adminBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaInicioSeleccionada) {
      setState(() {
        _fechaInicioSeleccionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.actividad != null;
    final title = isEditing ? 'Editar Actividad' : 'Crear Nueva Actividad';

    return Scaffold(
      backgroundColor: _adminBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _adminPrimaryColor,
        iconTheme: const IconThemeData(color: _adminAccentColor),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _adminAccentColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nombreController, 'Nombre de la Actividad'), // Adaptado
              _buildTextField(_descripcionController, 'Descripción', maxLines: 5),
              _buildTextField(_ubicacionController, 'Ubicación'),

              // Fila para Categoría y Estado
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStateDropdown()),
                  ],
                ),
              ),

              _buildDateSelector(), // Ahora usa _fechaInicioSeleccionada

              Row(
                children: [
                  Expanded(child: _buildTextField(_horaInicioController, 'Hora de Inicio (Ej: 17:00)', validator: _timeValidator)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_horaFinController, 'Hora de Fin (Ej: 19:00)', validator: _timeValidator)),
                ],
              ),

              _buildTextField(_fotoController, 'URL de la Foto (Opcional)', validator: (_) => null),

              const SizedBox(height: 30),

              // Botón principal de Guardar/Actualizar
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _adminAccentColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEditing ? 'Actualizar Actividad' : 'Crear Actividad',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 15),
                // Botón de Eliminar (solo en modo edición)
                OutlinedButton(
                  onPressed: _handleDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: _adminErrorColor, width: 2),
                  ),
                  child: const Text('Eliminar Actividad', style: TextStyle(fontSize: 16, color: _adminErrorColor)),
                ),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}