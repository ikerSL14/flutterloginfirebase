import 'package:flutter/material.dart';

class CalendarioScreen extends StatelessWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.calendar_today, size: 100, color: Colors.green),
    );
  }
}
