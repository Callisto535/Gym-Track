import 'package:flutter/material.dart';
import 'package:fitlog/screens/home_screen.dart';
import 'package:fitlog/screens/workout_screen.dart';
import 'package:fitlog/screens/history_screen.dart';
import 'package:fitlog/models/exercise.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10110F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC7F000),
          surface: Color(0xFF1C1E1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10110F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1C1E1A),
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final String _apiUrl = 'http://localhost:3000/workouts';

  final List<Exercise> _exercises = [];
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
          _exercises
            ..clear()
            ..addAll(data.map((item) => Exercise.fromJson(item)).toList());
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

  Future<void> _addExercise(Exercise exercise) async {
    await _fetchWorkouts();
  }

  Future<void> _editExercise(Exercise exercise) async {
    await _fetchWorkouts();
  }

  Future<void> _deleteExercise(int id) async {
    await _fetchWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        exercises: _exercises,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRefresh: _fetchWorkouts,
      ),
      WorkoutScreen(
        onAdd: _addExercise,
        onEdit: _editExercise,
        onDelete: _deleteExercise,
      ),
      HistoryScreen(exercises: _exercises),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            _fetchWorkouts();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF191B17),
        selectedItemColor: const Color(0xFFC7F000),
        unselectedItemColor: const Color(0xFF8C9185),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
