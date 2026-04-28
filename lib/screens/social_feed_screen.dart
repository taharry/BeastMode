import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  final List<IconData> avatars = const [
    Icons.fitness_center,
    Icons.local_fire_department,
    Icons.flash_on,
    Icons.sports_gymnastics,
    Icons.sports_kabaddi,
    Icons.directions_run,
    Icons.self_improvement,
    Icons.whatshot,
  ];

  final List<Color> avatarColors = const [
    Color(0xFFE11D2E),
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) {
      return {'displayName': 'Beast User', 'avatarIndex': 0};
    }

    final data = doc.data() ?? {};

    return {
      'displayName': data['displayName'] ?? 'Beast User',
      'avatarIndex': data['avatarIndex'] ?? 0,
    };
  }

  void showWorkoutDetails(
    BuildContext context, {
    required String displayName,
    required IconData avatarIcon,
    required Color avatarColor,
    required String workoutTitle,
    required String exerciseName,
    required String category,
    required int sets,
    required int reps,
    required int duration,
    required String notes,
    required String timeText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: avatarColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(avatarIcon, color: avatarColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            timeText,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D2E).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Color(0xFFE11D2E),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  workoutTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$exerciseName • $sets sets • $reps reps',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    DetailStat(label: 'SETS', value: sets.toString()),
                    const SizedBox(width: 10),
                    DetailStat(label: 'REPS', value: reps.toString()),
                    const SizedBox(width: 10),
                    DetailStat(label: 'MIN', value: duration.toString()),
                  ],
                ),

                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D2E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      notes,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workouts').snapshots(),
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

        if (workoutDocs.isEmpty) {
          return const Center(child: Text('No workouts posted yet'));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Community Feed',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap a post to see workout details.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            ...workoutDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final userId = data['userId'] ?? '';
              final workoutTitle = data['workoutTitle'] ?? 'Workout';
              final exerciseName = data['exerciseName'] ?? 'Exercise';
              final category = data['category'] ?? 'Uncategorized';
              final sets = data['sets'] ?? 0;
              final reps = data['reps'] ?? 0;
              final duration = data['duration'] ?? 0;
              final notes = data['notes'] ?? '';
              final createdAt = data['createdAt'] as Timestamp?;
              final timeText = formatTime(createdAt);

              return FutureBuilder<Map<String, dynamic>>(
                future: getUserData(userId),
                builder: (context, userSnapshot) {
                  final userData =
                      userSnapshot.data ??
                      {'displayName': 'Beast User', 'avatarIndex': 0};

                  final displayName =
                      userData['displayName'].toString().trim().isNotEmpty
                      ? userData['displayName']
                      : 'Beast User';

                  int avatarIndex = userData['avatarIndex'] ?? 0;
                  if (avatarIndex < 0 || avatarIndex >= avatars.length) {
                    avatarIndex = 0;
                  }

                  return FeedActivityCard(
                    displayName: displayName,
                    avatarIcon: avatars[avatarIndex],
                    avatarColor: avatarColors[avatarIndex],
                    category: category,
                    timeText: timeText,
                    onTap: () {
                      showWorkoutDetails(
                        context,
                        displayName: displayName,
                        avatarIcon: avatars[avatarIndex],
                        avatarColor: avatarColors[avatarIndex],
                        workoutTitle: workoutTitle,
                        exerciseName: exerciseName,
                        category: category,
                        sets: sets,
                        reps: reps,
                        duration: duration,
                        notes: notes,
                        timeText: timeText,
                      );
                    },
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}

class FeedActivityCard extends StatelessWidget {
  final String displayName;
  final IconData avatarIcon;
  final Color avatarColor;
  final String category;
  final String timeText;
  final VoidCallback onTap;

  const FeedActivityCard({
    super.key,
    required this.displayName,
    required this.avatarIcon,
    required this.avatarColor,
    required this.category,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.75),
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: avatarColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(avatarIcon, color: avatarColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$displayName logged a workout',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$category • $timeText',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const DetailStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D2E).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
