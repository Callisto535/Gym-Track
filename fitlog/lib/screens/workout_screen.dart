import 'package:flutter/material.dart';
import 'package:fitlog/models/exercise.dart';
import 'package:fitlog/screens/exercise_form_screen.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

class WorkoutScreen extends StatefulWidget {
  final Future<void> Function(Exercise) onAdd;
  final Future<void> Function(Exercise) onEdit;
  final Future<void> Function(int) onDelete;

  const WorkoutScreen({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final String _apiUrl = 'http://localhost:3000/workouts';

  final List<String> categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
  ];

  String selectedCategory = 'Chest';
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _exercises = data.map((item) => Exercise.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Cannot load workouts. Server status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Cannot connect to the backend. Make sure the server is running.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddForm() async {
    final Exercise? exercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseFormScreen()),
    );

    if (exercise != null) {
      await _createWorkout(exercise);
    }
  }

  Future<void> _createWorkout(Exercise exercise) async {
    final dateParts = exercise.date.split('/');
    String apiDate = exercise.date;

    if (dateParts.length == 3) {
      apiDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workout_day': exercise.category,
          'exercise_name': exercise.name,
          'weight': exercise.weight,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'workout_date': apiDate,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          selectedCategory = exercise.category;
        });
        await _fetchWorkouts();
        await widget.onAdd(exercise);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot save workout. Server status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to the backend. Make sure the server is running.',
          ),
        ),
      );
    }
  }

  Future<void> _openEditForm(Exercise exercise) async {
    final Exercise? updatedExercise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseFormScreen(exercise: exercise),
      ),
    );

    if (updatedExercise != null) {
      await _updateWorkout(updatedExercise);
    }
  }

  Future<void> _updateWorkout(Exercise exercise) async {
    final dateParts = exercise.date.split('/');
    String apiDate = exercise.date;

    if (dateParts.length == 3) {
      apiDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
    }

    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/${exercise.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workout_day': exercise.category,
          'exercise_name': exercise.name,
          'weight': exercise.weight,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'workout_date': apiDate,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          selectedCategory = exercise.category;
        });
        await _fetchWorkouts();
        await widget.onEdit(exercise);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 404
                  ? 'Workout not found'
                  : 'Cannot update workout. Server status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to the backend. Make sure the server is running.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text('Delete ${exercise.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteWorkout(exercise);
    }
  }

  Future<void> _deleteWorkout(Exercise exercise) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/${exercise.id}'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        await _fetchWorkouts();
        await widget.onDelete(exercise.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 404
                  ? 'Workout not found'
                  : 'Cannot delete workout. Server status: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to the backend. Make sure the server is running.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _exercises
        .where((exercise) => exercise.category == selectedCategory)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final bool isSelected = selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFFC7F000)
                            : const Color(0xFF292C26),
                        foregroundColor: isSelected
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAddForm,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7F000),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFB1B5AA)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchWorkouts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC7F000),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : filteredExercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises in this category.',
                        style: TextStyle(color: Color(0xFFB1B5AA)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFC7F000),
                              foregroundColor: Colors.black,
                              child: Icon(Icons.fitness_center),
                            ),
                            title: Text(exercise.name),
                            subtitle: Text(
                              '${exercise.weight} kg  •  '
                              '${exercise.sets} sets  •  '
                              '${exercise.reps} reps',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () {
                                    _openEditForm(exercise);
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFFC7F000),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    _deleteExercise(exercise);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
