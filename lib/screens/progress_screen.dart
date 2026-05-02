import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/streak.dart';
import '../services/workout_feedback.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  final List<String> categories = const [
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

  Future<void> deleteWorkout(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Workout'),
          content: const Text('Are you sure you want to delete this workout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workout deleted')));
    }
  }

  Future<void> editWorkout(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final workoutTitleController = TextEditingController(
      text: data['workoutTitle'] ?? '',
    );
    final exerciseNameController = TextEditingController(
      text: data['exerciseName'] ?? '',
    );
    final setsController = TextEditingController(
      text: (data['sets'] ?? '').toString(),
    );
    final repsController = TextEditingController(
      text: (data['reps'] ?? '').toString(),
    );
    final durationController = TextEditingController(
      text: (data['duration'] ?? '').toString(),
    );
    final notesController = TextEditingController(text: data['notes'] ?? '');

    String selectedCategory = data['category'] ?? 'Chest';

    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Chest';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Workout'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
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
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: workoutTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Workout Title',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: exerciseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sets'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('workouts')
                        .doc(docId)
                        .update({
                          'category': selectedCategory,
                          'workoutTitle': workoutTitleController.text.trim(),
                          'exerciseName': exerciseNameController.text.trim(),
                          'sets': int.tryParse(setsController.text.trim()) ?? 0,
                          'reps': int.tryParse(repsController.text.trim()) ?? 0,
                          'duration':
                              int.tryParse(durationController.text.trim()) ?? 0,
                          'notes': notesController.text.trim(),
                          'updatedAt': Timestamp.now(),
                        });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workout updated')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    workoutTitleController.dispose();
    exerciseNameController.dispose();
    setsController.dispose();
    repsController.dispose();
    durationController.dispose();
    notesController.dispose();
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ProgressGlassCard(
                      title: 'TOTAL WORKOUTS',
                      value: totalWorkouts.toString(),
                      icon: Icons.fitness_center,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ProgressGlassCard(
                      title: 'TOTAL MINUTES',
                      value: totalDuration.toString(),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ProgressGlassCard(
                title: 'CURRENT STREAK',
                value: '$streak day${streak == 1 ? '' : 's'}',
                icon: Icons.local_fire_department,
                fullWidth: true,
              ),
              const SizedBox(height: 24),
              _GoalsSection(userId: user.uid),
              const SizedBox(height: 24),
              const Text(
                'Recent Workouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
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
                  final category = data['category'] ?? 'Uncategorized';
                  final sets = data['sets'] ?? 0;
                  final reps = data['reps'] ?? 0;
                  final duration = data['duration'] ?? 0;
                  final notes = data['notes'] ?? '';

                  return ProgressWorkoutTile(
                    title: workoutTitle,
                    category: category,
                    subtitle:
                        '$exerciseName • $sets sets • $reps reps • $duration min',
                    notes: notes,
                    onEdit: () {
                      editWorkout(context, doc.id, data);
                    },
                    onDelete: () {
                      deleteWorkout(context, doc.id);
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class ProgressGlassCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool fullWidth;

  const ProgressGlassCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE11D2E), size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
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

class ProgressWorkoutTile extends StatelessWidget {
  final String title;
  final String category;
  final String subtitle;
  final String notes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProgressWorkoutTile({
    super.key,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.notes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE11D2E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFFE11D2E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D2E).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE11D2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                  if (notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notes,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;

  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(22),
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

class _GoalsSection extends StatefulWidget {
  final String userId;
  const _GoalsSection({required this.userId});

  @override
  State<_GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<_GoalsSection> {
  WorkoutGoals? _goals;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await WorkoutFeedbackService.getGoals(widget.userId);
    if (!mounted) return;
    setState(() => _goals = goals);
  }

  void _showGoalsDialog() {
    final goals = _goals ?? const WorkoutGoals();
    final weeklyCtrl =
        TextEditingController(text: goals.weeklyWorkoutTarget.toString());
    final durationCtrl =
        TextEditingController(text: goals.targetDurationPerSession.toString());
    final repsCtrl =
        TextEditingController(text: goals.maxRepsThreshold.toString());
    final setsCtrl =
        TextEditingController(text: goals.maxSetsThreshold.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Workout Goals'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weeklyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weekly Workout Target',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Duration (min)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Reps Threshold',
                  prefixIcon: Icon(Icons.repeat),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: setsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Sets Threshold',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newGoals = WorkoutGoals(
                weeklyWorkoutTarget: int.tryParse(weeklyCtrl.text) ?? 5,
                targetDurationPerSession:
                    int.tryParse(durationCtrl.text) ?? 45,
                maxRepsThreshold: int.tryParse(repsCtrl.text) ?? 20,
                maxSetsThreshold: int.tryParse(setsCtrl.text) ?? 6,
              );

              await WorkoutFeedbackService.saveGoals(
                widget.userId,
                newGoals,
              );

              if (!context.mounted) return;
              Navigator.pop(context);

              setState(() => _goals = newGoals);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goals updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = _goals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D2E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: Color(0xFFE11D2E),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'WORKOUT GOALS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFE11D2E),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showGoalsDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D2E),
                ),
              ),
            ],
          ),
          if (goals != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GoalChip(
                  label: '${goals.weeklyWorkoutTarget}/week',
                  icon: Icons.calendar_today,
                ),
                _GoalChip(
                  label: '${goals.targetDurationPerSession} min',
                  icon: Icons.timer_outlined,
                ),
                _GoalChip(
                  label: '${goals.maxRepsThreshold} max reps',
                  icon: Icons.repeat,
                ),
                _GoalChip(
                  label: '${goals.maxSetsThreshold} max sets',
                  icon: Icons.format_list_numbered,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _GoalChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D2E).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFE11D2E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE11D2E),
            ),
          ),
        ],
      ),
    );
  }
}
