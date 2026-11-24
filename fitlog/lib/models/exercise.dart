class Exercise {
  final int id;
  final String name;
  final String category;
  final double weight;
  final int sets;
  final int reps;
  final String date;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.weight,
    required this.sets,
    required this.reps,
    required this.date,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    String date = '';
    if (json['workout_date'] != null) {
      date = json['workout_date'].toString().substring(0, 10);
      final dateParts = date.split('-');
      if (dateParts.length == 3) {
        date = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
      }
    }

    return Exercise(
      id: int.parse(json['id'].toString()),
      name: json['exercise_name'],
      category: json['workout_day'],
      weight: double.parse(json['weight'].toString()),
      sets: int.parse(json['sets'].toString()),
      reps: int.parse(json['reps'].toString()),
      date: date,
    );
  }
}
