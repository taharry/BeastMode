import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> recentWorkouts = [
      'Chest Day - 4 exercises',
      'Leg Day - Squats + Lunges',
      'Cardio - 3 mile run',
      'Back Day - Deadlifts',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: const [
              Expanded(
                child: ProgressCard(title: 'Total Workouts', value: '28'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ProgressCard(title: 'Current Streak', value: '6 days'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Recent Workouts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              itemCount: recentWorkouts.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(recentWorkouts[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
