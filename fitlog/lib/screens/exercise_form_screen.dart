import 'package:flutter/material.dart';
import 'package:fitlog/models/exercise.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise;

  const ExerciseFormScreen({super.key, this.exercise});

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final List<String> categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
  ];

  String _category = 'Chest';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);

    if (widget.exercise != null) {
      _category = widget.exercise!.category;
      _nameController.text = widget.exercise!.name;
      _weightController.text = widget.exercise!.weight.toString();
      _setsController.text = widget.exercise!.sets.toString();
      _repsController.text = widget.exercise!.reps.toString();

      final dateParts = widget.exercise!.date.split('/');
      if (dateParts.length == 3) {
        _selectedDate = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        _dateController.text = _formatDate(_selectedDate);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = _formatDate(date);
      });
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _saveExercise() {
    if (_formKey.currentState!.validate()) {
      final Exercise exercise = Exercise(
        id: widget.exercise?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text,
        category: _category,
        weight: double.parse(_weightController.text),
        sets: int.parse(_setsController.text),
        reps: int.parse(_repsController.text),
        date: _formatDate(_selectedDate),
      );

      Navigator.pop(context, exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.exercise != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Exercise' : 'Add Exercise')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Workout Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }

                  final double? weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Sets',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of sets';
                  }

                  final int? sets = int.tryParse(value);
                  if (sets == null || sets <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Reps',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of reps';
                  }

                  final int? reps = int.tryParse(value);
                  if (reps == null || reps <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                onTap: _chooseDate,
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Workout Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC7F000),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isEditing ? 'SAVE CHANGES' : 'SAVE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
