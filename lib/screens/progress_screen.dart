import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  int calculateStreak(List<QueryDocumentSnapshot> workoutDocs) {
    final dates = <DateTime>{};

    for (var doc in workoutDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }

    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime currentDay = DateTime.now();
    currentDay = DateTime(currentDay.year, currentDay.month, currentDay.day);

    for (int i = 0; i < 365; i++) {
      if (dates.contains(currentDay)) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workoutDocs = snapshot.data?.docs ?? [];

        workoutDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        final totalWorkouts = workoutDocs.length;

        int totalDuration = 0;
        for (var doc in workoutDocs) {
          final data = doc.data() as Map<String, dynamic>;
          totalDuration += (data['duration'] ?? 0) as int;
        }

        final streak = calculateStreak(workoutDocs);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ProgressCard(
                      title: 'Total Workouts',
                      value: totalWorkouts.toString(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ProgressCard(
                      title: 'Total Minutes',
                      value: totalDuration.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ProgressCard(
                title: 'Current Streak',
                value: '$streak day${streak == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (workoutDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(child: Text('No workouts logged yet')),
                )
              else
                ...workoutDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final workoutTitle = data['workoutTitle'] ?? 'No Title';
                  final exerciseName = data['exerciseName'] ?? 'No Exercise';
                  final sets = data['sets'] ?? 0;
                  final reps = data['reps'] ?? 0;
                  final duration = data['duration'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.fitness_center),
                      ),
                      title: Text(workoutTitle),
                      subtitle: Text(
                        '$exerciseName • $sets sets • $reps reps • $duration min',
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class ProgressCard extends StatelessWidget {
  final String title;
  final String value;

  const ProgressCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
