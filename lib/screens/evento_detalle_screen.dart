import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> evento;
  final VoidCallback? onBack; // opcional para ejecutar al volver

  const EventoDetalleScreen({super.key, required this.evento, this.onBack});

  @override
  Widget build(BuildContext context) {
    final fecha = evento['fecha'] != null
        ? DateFormat('dd/MM/yyyy').format((evento['fecha'] as Timestamp).toDate())
        : '';
    final horaInicio = evento['horaInicio'] ?? '';
    final horaFin = evento['horaFin'] ?? '';
    final categoria = evento['categoria'] ?? '';
    final ubicacion = evento['ubicacion'] ?? '';
    final foto = evento['foto'] ?? '';
    final descripcion = evento['descripcion'] ?? '';

    IconData _iconoCategoria(String cat) {
      switch (cat) {
        case 'Académico':
          return Icons.school;
        case 'Deportivo':
          return Icons.sports_soccer;
        case 'Social':
          return Icons.people;
        case 'Cultural':
          return Icons.palette;
        default:
          return Icons.more_horiz;
      }
    }

    // Unsplash URLs por categoría (ejemplo)
    String _unsplashUrl(String cat) {
      switch (cat) {
        case 'Académico':
          return 'https://images.unsplash.com/photo-1530971013997-e06bb52a2372?q=80&w=796&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
        case 'Deportivo':
          return 'https://images.unsplash.com/photo-1521412644187-c49fa049e84d?fit=crop&w=800&q=80';
        case 'Social':
          return 'https://images.unsplash.com/photo-1556484687-30636164638b?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
        case 'Cultural':
          return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?fit=crop&w=800&q=80';
        default:
          return 'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?fit=crop&w=800&q=80';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () {
            if (onBack != null) onBack!();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Detalles del evento',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            foto.isNotEmpty
                ? Image.network(
              foto,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            )
                : Image.network(
              _unsplashUrl(categoria),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    evento['titulo'] ?? '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Badge categoría
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconoCategoria(categoria),
                            size: 16, color: Colors.green.shade800),
                        const SizedBox(width: 4),
                        Text(
                          categoria,
                          style: TextStyle(
                              fontSize: 14, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Fecha
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(fecha),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Hora
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$horaInicio - $horaFin'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Ubicación
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(ubicacion)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Descripción
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
