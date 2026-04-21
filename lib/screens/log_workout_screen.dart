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
        'sets': int.tryParse(setsController.text.trim()) ?? 0,
        'reps': int.tryParse(repsController.text.trim()) ?? 0,
        'duration': int.tryParse(durationController.text.trim()) ?? 0,
        'notes': notesController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved successfully')),
      );

      workoutTitleController.clear();
      exerciseNameController.clear();
      setsController.clear();
      repsController.clear();
      durationController.clear();
      notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save workout: $e')));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: workoutTitleController,
            decoration: const InputDecoration(labelText: 'Workout Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: exerciseNameController,
            decoration: const InputDecoration(labelText: 'Exercise Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: setsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sets'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : submitWorkout,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit Workout'),
            ),
          ),
        ],
      ),
    );
  }
}
