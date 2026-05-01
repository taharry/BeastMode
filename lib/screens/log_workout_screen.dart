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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: Color(0xFFE11D2E),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D2E), Color(0xFF7F1D1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE11D2E).withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fitness_center, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Log Workout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your session and keep your progress moving.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151515) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('CATEGORY'),
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

                const SizedBox(height: 20),
                _sectionLabel('EXERCISE DETAILS'),

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

                const SizedBox(height: 20),
                _sectionLabel('VOLUME & DURATION'),

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

                const SizedBox(height: 20),
                _sectionLabel('NOTES'),

                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
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
                      'SUBMIT WORKOUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
