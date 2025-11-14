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

class AdminEventoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic>? evento;

  // Si evento es null, estamos creando. Si no, estamos editando.
  const AdminEventoDetalleScreen({super.key, this.evento});

  @override
  State<AdminEventoDetalleScreen> createState() => _AdminEventoDetalleScreenState();
}

class _AdminEventoDetalleScreenState extends State<AdminEventoDetalleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();

  // Estado del formulario
  DateTime? _fechaSeleccionada;
  String? _categoriaSeleccionada;
  String? _estadoSeleccionado;
  bool _isLoading = false;

  // Listas de opciones
  final List<String> _categorias = [
    'Académico', 'Deportivo', 'Social', 'Cultural', 'Otro',
  ];
  final List<String> _estados = [
    'en_curso',
    'cancelado',
    'finalizado'
  ];

  @override
  void initState() {
    super.initState();
    // 💡 Si se pasa un evento (modo edición), pre-cargar los datos
    if (widget.evento != null) {
      final e = widget.evento!;
      _tituloController.text = e['titulo'] ?? '';
      _descripcionController.text = e['descripcion'] ?? '';
      _ubicacionController.text = e['ubicacion'] ?? '';

      // CRÍTICO: Asegurarse de que las horas cargadas del String tengan formato HH:MM
      _horaInicioController.text = _formatTime(e['horaInicio'] ?? '');
      _horaFinController.text = _formatTime(e['horaFin'] ?? '');

      _fotoController.text = e['foto'] ?? '';
      _categoriaSeleccionada = e['categoria'];
      _estadoSeleccionado = e['estado'];

      if (e['fecha'] is Timestamp) {
        // Al cargar, extraemos solo el año, mes y día del Timestamp (que está en UTC/Z)
        final utcTime = (e['fecha'] as Timestamp).toDate();
        _fechaSeleccionada = DateTime(utcTime.year, utcTime.month, utcTime.day);
      }
    } else {
      // 💡 En modo creación, forzar el estado inicial a 'en_curso'
      _estadoSeleccionado = 'en_curso';
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
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
  int _getCombinedMillisecondsWithOffset() {
    final date = _fechaSeleccionada!;
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

  // 💡 Nueva función: Obtiene el Timestamp de la hora actual con compensación.
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
    // La validación del formulario incluye ahora el _timeValidator
    if (!_formKey.currentState!.validate() || _fechaSeleccionada == null || _categoriaSeleccionada == null || _estadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos requeridos y verifica el formato de las horas (HH:MM).', style: TextStyle(color: _adminErrorColor))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String docId = widget.evento?['id'] ?? FirebaseFirestore.instance.collection('eventos').doc().id;
    final bool isEditing = widget.evento != null;

    // --- Datos Comunes ---
    // Obtenemos los milisegundos para el Timestamp (con la compensación horaria)
    final int combinedDateTimeMs = _getCombinedMillisecondsWithOffset();

    // Formateamos las cadenas de hora antes de guardarlas en Firestore
    final formattedHoraInicio = _formatTime(_horaInicioController.text);
    final formattedHoraFin = _formatTime(_horaFinController.text);

    // --- 1. Datos del Evento ---
    Map<String, dynamic> eventData = {
      'titulo': _tituloController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'ubicacion': _ubicacionController.text.trim(),
      'horaInicio': formattedHoraInicio,
      'horaFin': formattedHoraFin,
      'foto': _fotoController.text.trim(),
      'categoria': _categoriaSeleccionada,
      // Guardamos el Timestamp con compensación
      'fecha': Timestamp.fromMillisecondsSinceEpoch(combinedDateTimeMs),
      'id': docId,
      'estado': _estadoSeleccionado,
    };

    try {
      // 1. Guardar/Actualizar Evento
      await FirebaseFirestore.instance.collection('eventos').doc(docId).set(eventData);

      // 2. Crear Notificación (SOLO si es un evento nuevo)
      if (!isEditing) {
        final notificationData = {
          'categoria': _categoriaSeleccionada,
          // Timestamp de creación con compensación horaria
          'creadaEn': _getCreationTimestampWithOffset(),
          'descripcion': _descripcionController.text.trim(),
          // Fecha del evento con compensación horaria
          'fecha': Timestamp.fromMillisecondsSinceEpoch(combinedDateTimeMs),
          'tipo': 'evento',
          // Título específico para notificaciones de nuevo evento
          'titulo': 'Nuevo evento: ${eventData['titulo']}',
          'ubicacion': _ubicacionController.text.trim(),
          'usuariosBorrados': [], // Inicialmente vacío
          'usuariosLeidos': [],    // Inicialmente vacío
        };

        await FirebaseFirestore.instance.collection('notificaciones').add(notificationData);
      }

      // 3. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Evento actualizado con éxito.' : 'Evento y notificación creados con éxito.', style: const TextStyle(color: Colors.white)), backgroundColor: _adminAccentColor),
      );
      if (context.mounted) Navigator.pop(context, true); // Regresar y refrescar
    } catch (e) {
      print('Error al guardar/actualizar evento o crear notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el evento: $e', style: TextStyle(color: _adminErrorColor))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.evento == null) return;

    final bool confirm = await _showConfirmationDialog(context);
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('eventos').doc(widget.evento!['id']).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado con éxito.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      if (context.mounted) Navigator.pop(context, true); // Regresar y refrescar
    } catch (e) {
      print('Error al eliminar evento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el evento: $e', style: TextStyle(color: _adminErrorColor))),
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
          content: Text('¿Estás seguro de que deseas eliminar el evento "${widget.evento!['titulo']}"?', style: const TextStyle(color: _adminLabelColor)),
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
        // Usamos el validador general si no se proporciona uno específico
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
    final bool isEditing = widget.evento != null;
    final bool isDisabled = !isEditing;

    return DropdownButtonFormField<String>(
      value: _estadoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Estado',
        labelStyle: TextStyle(color: isDisabled ? _adminLabelColor.withOpacity(0.5) : _adminLabelColor),
        filled: true,
        fillColor: isDisabled ? _adminCardColor.withOpacity(0.5) : _adminCardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDisabled ? _adminLabelColor.withOpacity(0.5) : _adminAccentColor, width: 2)),
      ),
      dropdownColor: _adminPrimaryColor,
      style: TextStyle(color: isDisabled ? _adminLabelColor : Colors.white),
      iconEnabledColor: isDisabled ? _adminLabelColor.withOpacity(0.5) : _adminAccentColor,
      onChanged: isDisabled ? null : (String? newValue) {
        setState(() {
          _estadoSeleccionado = newValue;
        });
      },
      items: _estados.map((String status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, style: TextStyle(color: isDisabled ? _adminLabelColor : Colors.white)),
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
            labelText: 'Fecha del Evento',
            labelStyle: const TextStyle(color: _adminLabelColor),
            filled: true,
            fillColor: _adminCardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _adminAccentColor, width: 2)),
          ),
          child: Text(
            _fechaSeleccionada == null
                ? 'Seleccionar fecha'
                : DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!),
            style: TextStyle(color: _fechaSeleccionada == null ? _adminLabelColor : Colors.white),
          ),
        ),
      ),
    );
  }

  // Picker de Fecha
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Usamos el DateTime actual para inicializar si no hay fecha seleccionada
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: _adminAccentColor, // Color principal del picker
              onPrimary: Colors.white,
              surface: _adminPrimaryColor, // Fondo del calendario
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _adminBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        // Al seleccionar, solo nos interesa la fecha (ignora la hora por defecto de 00:00)
        _fechaSeleccionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.evento != null;
    final title = isEditing ? 'Editar Evento' : 'Crear Nuevo Evento';

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
              _buildTextField(_tituloController, 'Título del Evento'),
              _buildTextField(_descripcionController, 'Descripción', maxLines: 5),
              _buildTextField(_ubicacionController, 'Ubicación'),

              // Fila para Categoría y Estado (lado a lado)
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

              _buildDateSelector(),

              Row(
                children: [
                  // Aplicamos el validador de formato HH:MM
                  Expanded(child: _buildTextField(_horaInicioController, 'Hora de Inicio (Ej: 17:00)', validator: _timeValidator)),
                  const SizedBox(width: 10),
                  // Aplicamos el validador de formato HH:MM
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
                  isEditing ? 'Actualizar Evento' : 'Crear Evento',
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
                  child: const Text('Eliminar Evento', style: TextStyle(fontSize: 16, color: _adminErrorColor)),
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