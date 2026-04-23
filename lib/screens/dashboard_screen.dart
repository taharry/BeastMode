import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final String motivationQuote;

  final List<String> quotes = [
    'Take your time, but never stop moving.',
    'Power grows every time you show up.',
    'Discipline is louder than excuses.',
    'Train like the version of you you want to become.',
    'No shortcuts. Just effort and repetition.',
    'You do not need perfect. You need consistent.',
    'Every session is another step forward.',
    'Push through the doubt. Finish the set.',
    'Effort stacks. Results follow.',
    'Lock in today. Thank yourself tomorrow.',
  ];

  @override
  void initState() {
    super.initState();
    motivationQuote = quotes[Random().nextInt(quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, userSnapshot) {
        String displayName = '';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          displayName = data?['displayName'] ?? '';
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

            final welcomeName = displayName.trim().isNotEmpty
                ? displayName.trim()
                : 'Beast';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D2E),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D2E).withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $welcomeName',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track your progress and keep building momentum.',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PersonaStatCard(
                          title: 'THIS WEEK',
                          value: workoutsThisWeek.toString(),
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: PersonaStatCard(
                          title: 'TOTAL WORKOUTS',
                          value: totalWorkouts.toString(),
                          icon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const PersonaWideCard(
                    title: 'CURRENT STREAK',
                    value: 'SEE PROGRESS TAB',
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Today's Motivation",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D2E).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Color(0xFFE11D2E),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            motivationQuote,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PersonaStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const PersonaStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE11D2E), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonaWideCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const PersonaWideCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D2E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFE11D2E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
