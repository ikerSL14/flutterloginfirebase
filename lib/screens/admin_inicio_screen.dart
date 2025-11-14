import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 🚨 NOTA: Se asume que la librería 'fl_chart' está disponible para las gráficas.
import 'package:fl_chart/fl_chart.dart';

// 💡 Colores reutilizados del AdminScreen (para consistencia)
const Color _adminAccentColor = Color(0xFF27C475); // Verde brillante
const Color _adminBackgroundColor = Color(0xFF052A35); // Fondo de pantalla
const Color _adminCardColor = Color(0xFF063945); // Color de los contenedores
const Color _adminLabelColor = Color(0xFF668C98); // Color de las etiquetas secundarias

class AdminInicioScreen extends StatelessWidget {
  const AdminInicioScreen({super.key});

  // 1. Obtiene el conteo de usuarios con rol 'usuario'
  Future<int> _getTotalUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'usuario')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error al contar usuarios: $e');
      return 0;
    }
  }

  // 2. Obtiene el conteo total de eventos
  Future<int> _getTotalEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('eventos').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error al contar eventos: $e');
      return 0;
    }
  }

  // 3. Obtiene el conteo total de actividades
  Future<int> _getTotalActivities() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('actividades').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error al contar actividades: $e');
      return 0;
    }
  }

  // 4. Función combinada para obtener los datos de la gráfica
  Future<Map<String, int>> _fetchChartData() async {
    final events = await _getTotalEvents();
    final activities = await _getTotalActivities();
    return {
      'events': events,
      'activities': activities
    };
  }

  // 💡 Widget de Tarjeta de Métrica Reutilizable (para Eventos y Actividades)
  Widget _buildMetricCard({
    required Future<int> futureCount,
    required String label,
    required IconData icon,
    required Color iconColor,
    double iconSize = 28,
  }) {
    return FutureBuilder<int>(
      future: futureCount,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          decoration: BoxDecoration(
            color: _adminCardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícono dentro de un círculo (Arriba a la izquierda, según el diseño)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: iconColor),
              ),

              const SizedBox(height: 10),

              // Número (Métrica)
              isLoading
                  ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  )
              )
                  : Text(
                '$count',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 5),

              // Etiqueta
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: _adminLabelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _adminBackgroundColor, // Asegura que el fondo sea el correcto
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // 1. Contenedor de Total de Usuarios (Grande y rectangular)
            // ----------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: _adminCardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Etiqueta (color #668c98)
                      const Text(
                        'Total de usuarios',
                        style: TextStyle(
                          fontSize: 16,
                          color: _adminLabelColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Número de Usuarios (color blanco)
                      FutureBuilder<int>(
                        future: _getTotalUsers(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            snapshot.connectionState == ConnectionState.waiting
                                ? '...'
                                : '$count',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Ícono de Usuario (verde #24c475 dentro de círculo)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _adminAccentColor.withOpacity(0.2), // Color de círculo que combine
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt,
                      size: 40,
                      color: _adminAccentColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------
            // 2 & 3. Contenedores de Eventos y Actividades (Horizontal)
            // ----------------------------------------------------
            Row(
              children: [
                // Eventos Próximos
                Expanded(
                  child: _buildMetricCard(
                    futureCount: _getTotalEvents(),
                    label: 'Eventos próximos',
                    icon: Icons.event,
                    iconColor: Colors.blue.shade300,
                  ),
                ),
                const SizedBox(width: 15),

                // Actividades Próximas
                Expanded(
                  child: _buildMetricCard(
                    futureCount: _getTotalActivities(),
                    label: 'Actividades próximas',
                    icon: Icons.local_activity,
                    iconColor: Colors.orange.shade300,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------
            // 4. Gráfica de Barras (Eventos vs. Actividades)
            // ----------------------------------------------------
            _EventsActivitiesBarChart(futureData: _fetchChartData()),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// WIDGET DE GRÁFICA DE BARRAS (Eventos vs. Actividades)
// =================================================================

class _EventsActivitiesBarChart extends StatelessWidget {
  final Future<Map<String, int>> futureData;

  const _EventsActivitiesBarChart({required this.futureData});

  // Colores de las barras
  static const Color _eventColor = Color(0xFF509CFF); // Azul para Eventos
  static const Color _activityColor = Color(0xFFFF8C50); // Naranja para Actividades

  // Función para obtener el título del eje X
  Widget _getBottomTitle(double value, TitleMeta meta) {
    const style = TextStyle(
      color: _adminLabelColor,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Eventos';
        break;
      case 1:
        text = 'Actividades';
        break;
      default:
        text = '';
        break;
    }
    // 🚨 CORRECCIÓN DEFINITIVA:
    // Para fl_chart 1.1.1, se requiere pasar el objeto 'meta' completo.
    // Esto satisface el requisito de 'meta' y permite a SideTitleWidget
    // usar internamente 'meta.axisSide'.
    return SideTitleWidget(
      meta: meta, // <--- CAMBIO CLAVE
      space: 8,
      child: Text(text, style: style),
    );
  }

  // Función para construir cada item de la Leyenda
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 300,
            decoration: BoxDecoration(color: _adminCardColor, borderRadius: BorderRadius.circular(15)),
            child: const Center(child: CircularProgressIndicator(color: _adminAccentColor)),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 300,
            decoration: BoxDecoration(color: _adminCardColor, borderRadius: BorderRadius.circular(15)),
            child: Center(
                child: Text('Error al cargar datos: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }

        final data = snapshot.data ?? {'events': 0, 'activities': 0};
        final eventsCount = data['events']!.toDouble();
        final activitiesCount = data['activities']!.toDouble();

        final double maxY = [eventsCount, activitiesCount, 10.0].reduce((a, b) => a > b ? a : b) + 5;

        // 💡 Datos de las barras
        final barGroups = [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: eventsCount,
                color: _eventColor,
                width: 30,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: activitiesCount,
                color: _activityColor,
                width: 30,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
            ],
          ),
        ];

        return Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 20, right: 20, bottom: 5, left: 10),
          decoration: BoxDecoration(
            color: _adminCardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10.0, bottom: 15.0),
                child: Text(
                  'Comparativa: Eventos vs. Actividades',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: _getBottomTitle,
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 5, // Títulos cada 5 unidades
                            getTitlesWidget: (value, meta) {
                              // Títulos del eje Y
                              return Text(value.toInt().toString(), style: const TextStyle(color: _adminLabelColor, fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: _adminLabelColor.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: _adminLabelColor.withOpacity(0.4), width: 1),
                          left: BorderSide(color: _adminLabelColor.withOpacity(0.4), width: 1),
                        ),
                      ),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ),

              // 3. Leyenda (debajo de la gráfica)
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Eventos', _eventColor),
                    const SizedBox(width: 25),
                    _buildLegendItem('Actividades', _activityColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}