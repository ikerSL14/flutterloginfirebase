import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _eventosPorDia = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarEventos();
  }

  /// Carga todos los eventos desde Firestore una vez y los indexa por día.
  Future<void> _cargarEventos() async {
    final snapshot = await FirebaseFirestore.instance.collection('eventos').get();
    final Map<DateTime, List<Map<String, dynamic>>> eventosTemp = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['fecha'] != null && data['fecha'] is Timestamp) {
        final DateTime fechaEvento = (data['fecha'] as Timestamp).toDate();
        final DateTime fechaKey = DateTime(fechaEvento.year, fechaEvento.month, fechaEvento.day);

        eventosTemp.putIfAbsent(fechaKey, () => []);
        eventosTemp[fechaKey]!.add(data);
      }
    }

    setState(() {
      _eventosPorDia = eventosTemp;
    });
  }

  /// Para TableCalendar: devuelve la lista de eventos para una fecha dada.
  List<Map<String, dynamic>> _getEventosDelDia(DateTime dia) {
    final DateTime fechaKey = DateTime(dia.year, dia.month, dia.day);
    return _eventosPorDia[fechaKey] ?? [];
  }

  Color _estadoColorDinamico(Map<String, dynamic> data) {
    final estadoBD = data['estado'] ?? '';
    if (estadoBD == 'cancelado') return Colors.red.shade700;

    if (estadoBD == 'en_curso') {
      final now = DateTime.now();
      // Convertir horaInicio y horaFin a DateTime
      try {
        final fecha = (data['fecha'] as Timestamp).toDate();
        final horaInicioParts = (data['horaInicio'] ?? '00:00').split(':');
        final horaFinParts = (data['horaFin'] ?? '23:59').split(':');

        final inicio = DateTime(fecha.year, fecha.month, fecha.day,
            int.parse(horaInicioParts[0]), int.parse(horaInicioParts[1]));
        final fin = DateTime(fecha.year, fecha.month, fecha.day,
            int.parse(horaFinParts[0]), int.parse(horaFinParts[1]));

        if (now.isBefore(inicio)) {
          // Evento aún no comienza
          return Colors.blueGrey.shade400; // fondo verde claro
        } else if (now.isAfter(fin)) {
          // Evento ya terminó
          return Colors.grey.shade600;
        } else {
          // Evento en curso
          return Colors.green.shade700;
        }
      } catch (e) {
        return Colors.black45; // fallback
      }
    }

    return Colors.black45; // fallback para otros casos
  }

  String _estadoTextoDinamico(Map<String, dynamic> data) {
    final estadoBD = data['estado'] ?? '';
    if (estadoBD == 'cancelado') return 'CANCELADO';

    if (estadoBD == 'en_curso') {
      final now = DateTime.now();
      try {
        final fecha = (data['fecha'] as Timestamp).toDate();
        final horaInicioParts = (data['horaInicio'] ?? '00:00').split(':');
        final horaFinParts = (data['horaFin'] ?? '23:59').split(':');

        final inicio = DateTime(fecha.year, fecha.month, fecha.day,
            int.parse(horaInicioParts[0]), int.parse(horaInicioParts[1]));
        final fin = DateTime(fecha.year, fecha.month, fecha.day,
            int.parse(horaFinParts[0]), int.parse(horaFinParts[1]));

        if (now.isBefore(inicio)) {
          return 'PRÓXIMAMENTE';
        } else if (now.isAfter(fin)) {
          return 'TERMINADO';
        } else {
          return 'EN CURSO';
        }
      } catch (e) {
        return 'EN CURSO';
      }
    }

    return estadoBD.toString().toUpperCase();
  }


  IconData _iconoCategoria(String categoria) {
    switch (categoria) {
      case 'Conferencia':
        return Icons.mic;
      case 'Taller':
        return Icons.build;
      case 'Deportivo':
        return Icons.sports_soccer;
      case 'Social':
        return Icons.people;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar<Map<String, dynamic>>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) => _getEventosDelDia(day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            // Capitaliza la primera letra del mes
            titleTextFormatter: (date, locale) {
              final formatted = DateFormat.yMMMM('es_ES').format(date);
              return formatted[0].toUpperCase() + formatted.substring(1);
            },
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.green.shade700,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.green.shade200,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(), // no lo usamos, usamos calendarBuilders
            markersMaxCount: 1,
          ),
          calendarBuilders: CalendarBuilders(
            // Construye el punto (marker) debajo del número del día
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              final bool isSelected = isSameDay(date, _selectedDay);
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            // Opcional: personalizar el día seleccionado para que contraste con el punto blanco
            selectedBuilder: (context, date, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(6.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
            // Día normal
            defaultBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(6.0),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: const TextStyle(color: Colors.black87),
                ),
              );
            },
            // Hoy
            todayBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(6.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green.shade200,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: const TextStyle(color: Colors.black87),
                ),
              );
            },
          ),
          locale: 'es_ES',
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _selectedDay == null
              ? const Center(child: Text('Seleccione un día.'))
              : _buildEventosList(),
        ),
      ],
    );
  }

  Widget _buildEventosList() {
    final eventos = _getEventosDelDia(_selectedDay!);

    if (eventos.isEmpty) {
      return const Center(child: Text('No hay eventos para este día.'));
    }

    // 🔹 Ordenar por horaInicio
    eventos.sort((a, b) {
      final horaA = a['horaInicio'] ?? '00:00';
      final horaB = b['horaInicio'] ?? '00:00';
      return horaA.compareTo(horaB);
    });

    return ListView.builder(
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final data = eventos[index];
        final colorEstado = _estadoColorDinamico(data);
        final textoEstado = _estadoTextoDinamico(data);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  radius: 25,
                  child: Icon(
                    _iconoCategoria(data['categoria'] ?? ''),
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['titulo'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badge categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconoCategoria(data['categoria'] ?? ''),
                              size: 16,
                              color: Colors.green.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data['categoria'] ?? '',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data['descripcion'] ?? ''),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 5),
                          Text('${data['horaInicio'] ?? ''} - ${data['horaFin'] ?? ''}'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 5),
                          Text(data['ubicacion'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Estado dinámico
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorEstado,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          textoEstado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

