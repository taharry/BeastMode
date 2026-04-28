import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final TextEditingController workoutTitleController = TextEditingController();
  final TextEditingController exerciseNameController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool isLoading = false;

  final List<String> categories = [
    '     ',
    'Chest',
    'Back',
    'Legs',
    'Arms',
    'Shoulders',
    'Cardio',
    'Full Body',
    'Core',
    'Rest / Recovery',
  ];

  String selectedCategory = 'Chest';

  @override
  void dispose() {
    workoutTitleController.dispose();
    exerciseNameController.dispose();
    setsController.dispose();
    repsController.dispose();
    durationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> submitWorkout() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user is logged in')));
      return;
    }

    if (workoutTitleController.text.trim().isEmpty ||
        exerciseNameController.text.trim().isEmpty ||
        setsController.text.trim().isEmpty ||
        repsController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('workouts').add({
        'userId': user.uid,
        'userEmail': user.email,
        'workoutTitle': workoutTitleController.text.trim(),
        'exerciseName': exerciseNameController.text.trim(),
        'category': selectedCategory,
        'sets': int.tryParse(setsController.text.trim()) ?? 0,
        'reps': int.tryParse(repsController.text.trim()) ?? 0,
        'duration': int.tryParse(durationController.text.trim()) ?? 0,
        'notes': notesController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved successfully')),
      );

      workoutTitleController.clear();
      exerciseNameController.clear();
      setsController.clear();
      repsController.clear();
      durationController.clear();
      notesController.clear();

      setState(() {
        selectedCategory = 'Chest';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save workout: $e')));
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Workout',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your session and keep your progress moving.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 22),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Workout Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: workoutTitleController,
                decoration: const InputDecoration(
                  labelText: 'Workout Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: exerciseNameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sets',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : submitWorkout,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
