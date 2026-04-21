import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        final totalWorkouts = docs.length;

        // Calculate workouts this week
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));

        int workoutsThisWeek = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (date.isAfter(weekAgo)) {
              workoutsThisWeek++;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Beast Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stay consistent. Track your workouts. Keep improving.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Workouts This Week',
                      value: workoutsThisWeek.toString(),
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: StatCard(
                      title: 'Current Streak',
                      value: 'Coming Soon',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              StatCard(
                title: 'Total Workouts',
                value: totalWorkouts.toString(),
                icon: Icons.fitness_center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Log Workout (Go to Workout tab)'),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Today's Motivation",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.bolt, color: Colors.deepOrange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Push yourself a little more today than yesterday.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepOrange),
            const SizedBox(height: 10),
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
