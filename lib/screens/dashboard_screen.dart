import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/streak.dart';
import '../services/workout_feedback.dart';

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
            final streak = calculateStreak(docs);

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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE11D2E), Color(0xFF7F1D1D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D2E).withOpacity(0.25),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
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
                        child: GlassStatCard(
                          title: 'THIS WEEK',
                          value: workoutsThisWeek.toString(),
                          icon: Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GlassStatCard(
                          title: 'TOTAL WORKOUTS',
                          value: totalWorkouts.toString(),
                          icon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GlassWideCard(
                    title: 'CURRENT STREAK',
                    value: '$streak day${streak == 1 ? '' : 's'}',
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Today's Motivation",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  GlassPanel(
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
                  const SizedBox(height: 24),
                  _WorkoutFeedbackSection(
                    userId: user.uid,
                    workouts: docs.map((d) =>
                        d.data() as Map<String, dynamic>).toList(),
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

class _WorkoutFeedbackSection extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> workouts;

  const _WorkoutFeedbackSection({
    required this.userId,
    required this.workouts,
  });

  @override
  State<_WorkoutFeedbackSection> createState() =>
      _WorkoutFeedbackSectionState();
}

class _WorkoutFeedbackSectionState extends State<_WorkoutFeedbackSection> {
  List<FeedbackAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void didUpdateWidget(covariant _WorkoutFeedbackSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workouts.length != widget.workouts.length) {
      _loadFeedback();
    }
  }

  Future<void> _loadFeedback() async {
    final goals = await WorkoutFeedbackService.getGoals(widget.userId);
    final alerts = WorkoutFeedbackService.analyze(
      recentWorkouts: widget.workouts,
      goals: goals,
    );
    if (!mounted) return;
    setState(() => _alerts = alerts);
  }

  IconData _iconForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.safety:
        return Icons.warning_amber_rounded;
      case FeedbackType.formReminder:
        return Icons.info_outline;
      case FeedbackType.encouragement:
        return Icons.emoji_events;
      case FeedbackType.goal:
        return Icons.track_changes;
    }
  }

  Color _colorForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.safety:
        return Colors.orange;
      case FeedbackType.formReminder:
        return Colors.blue;
      case FeedbackType.encouragement:
        return Colors.green;
      case FeedbackType.goal:
        return const Color(0xFFE11D2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Feedback',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ..._alerts.map((alert) {
          final color = _colorForType(alert.type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForType(alert.type),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.message,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;

  const GlassPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const GlassStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassWideCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const GlassWideCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
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
