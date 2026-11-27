import 'package:flutter/material.dart';

class FitLogLogo extends StatelessWidget {
  const FitLogLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFC7F000),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'FitLog',
          style: TextStyle(
            color: Color(0xFFC7F000),
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
