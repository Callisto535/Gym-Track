import 'package:flutter/material.dart';
import 'package:fitlog/models/exercise.dart';

class HistoryScreen extends StatelessWidget {
  final List<Exercise> exercises;

  const HistoryScreen({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: exercises.isEmpty
          ? const Center(
              child: Text(
                'No workout history.',
                style: TextStyle(color: Color(0xFFB1B5AA)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exercise.date,
                              style: const TextStyle(color: Color(0xFFB1B5AA)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF303429),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                exercise.category,
                                style: const TextStyle(
                                  color: Color(0xFFC7F000),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              size: 18,
                              color: Color(0xFFC7F000),
                            ),
                            const SizedBox(width: 6),
                            Text('${exercise.weight} kg'),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.repeat,
                              size: 18,
                              color: Color(0xFFC7F000),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${exercise.sets} sets x ${exercise.reps} reps',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
