import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutGoals {
  final int weeklyWorkoutTarget;
  final int targetDurationPerSession;
  final int maxRepsThreshold;
  final int maxSetsThreshold;

  const WorkoutGoals({
    this.weeklyWorkoutTarget = 5,
    this.targetDurationPerSession = 45,
    this.maxRepsThreshold = 20,
    this.maxSetsThreshold = 6,
  });

  factory WorkoutGoals.fromMap(Map<String, dynamic> data) {
    return WorkoutGoals(
      weeklyWorkoutTarget: data['weeklyWorkoutTarget'] ?? 5,
      targetDurationPerSession: data['targetDurationPerSession'] ?? 45,
      maxRepsThreshold: data['maxRepsThreshold'] ?? 20,
      maxSetsThreshold: data['maxSetsThreshold'] ?? 6,
    );
  }

  Map<String, dynamic> toMap() => {
        'weeklyWorkoutTarget': weeklyWorkoutTarget,
        'targetDurationPerSession': targetDurationPerSession,
        'maxRepsThreshold': maxRepsThreshold,
        'maxSetsThreshold': maxSetsThreshold,
      };
}

class FeedbackAlert {
  final String title;
  final String message;
  final FeedbackType type;

  const FeedbackAlert({
    required this.title,
    required this.message,
    required this.type,
  });
}

enum FeedbackType { safety, formReminder, encouragement, goal }

class WorkoutFeedbackService {
  static Future<WorkoutGoals> getGoals(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('goals')
        .doc(userId)
        .get();

    if (!doc.exists) return const WorkoutGoals();
    return WorkoutGoals.fromMap(doc.data()!);
  }

  static Future<void> saveGoals(String userId, WorkoutGoals goals) async {
    await FirebaseFirestore.instance
        .collection('goals')
        .doc(userId)
        .set(goals.toMap());
  }

  static List<FeedbackAlert> analyze({
    required List<Map<String, dynamic>> recentWorkouts,
    required WorkoutGoals goals,
  }) {
    final alerts = <FeedbackAlert>[];

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeek = recentWorkouts.where((w) {
      final ts = w['createdAt'] as Timestamp?;
      if (ts == null) return false;
      return ts.toDate().isAfter(weekAgo);
    }).toList();

    final weeklyCount = thisWeek.length;
    final target = goals.weeklyWorkoutTarget;

    if (weeklyCount >= target) {
      alerts.add(FeedbackAlert(
        title: 'Weekly Goal Reached',
        message:
            'You hit $weeklyCount/$target workouts this week. Keep it up!',
        type: FeedbackType.encouragement,
      ));
    } else {
      final remaining = target - weeklyCount;
      final daysLeft = 7 - now.weekday;
      alerts.add(FeedbackAlert(
        title: 'Weekly Goal Progress',
        message:
            '$weeklyCount/$target workouts done. $remaining more needed with $daysLeft days left.',
        type: FeedbackType.goal,
      ));
    }

    for (var workout in thisWeek) {
      final reps = workout['reps'] as int? ?? 0;
      final sets = workout['sets'] as int? ?? 0;
      final title = workout['workoutTitle'] ?? 'Workout';

      if (reps > goals.maxRepsThreshold) {
        final pct =
            (((reps - goals.maxRepsThreshold) / goals.maxRepsThreshold) * 100)
                .round();
        alerts.add(FeedbackAlert(
          title: 'High Rep Alert',
          message:
              '"$title" had $reps reps ($pct% over your ${goals.maxRepsThreshold} rep threshold). Consider reducing reps and increasing weight for strength.',
          type: FeedbackType.safety,
        ));
        break;
      }

      if (sets > goals.maxSetsThreshold) {
        alerts.add(FeedbackAlert(
          title: 'Volume Warning',
          message:
              '"$title" had $sets sets (threshold: ${goals.maxSetsThreshold}). High volume increases injury risk — ensure adequate rest between sets.',
          type: FeedbackType.safety,
        ));
        break;
      }
    }

    if (thisWeek.length >= 2) {
      final durations = thisWeek
          .map((w) => w['duration'] as int? ?? 0)
          .where((d) => d > 0)
          .toList();

      if (durations.isNotEmpty) {
        final avg = durations.reduce((a, b) => a + b) / durations.length;
        final targetDur = goals.targetDurationPerSession;

        if (avg < targetDur * 0.7) {
          alerts.add(FeedbackAlert(
            title: 'Session Duration Low',
            message:
                'Average session is ${avg.round()} min (target: $targetDur min). Try extending warm-up or adding accessory work.',
            type: FeedbackType.formReminder,
          ));
        } else if (avg > targetDur * 1.4) {
          alerts.add(FeedbackAlert(
            title: 'Sessions Running Long',
            message:
                'Average session is ${avg.round()} min (target: $targetDur min). Long sessions can reduce intensity — consider tighter rest periods.',
            type: FeedbackType.formReminder,
          ));
        }
      }
    }

    final categories = <String, int>{};
    for (var w in recentWorkouts) {
      final cat = w['category'] as String? ?? '';
      if (cat.isNotEmpty) categories[cat] = (categories[cat] ?? 0) + 1;
    }

    if (categories.length == 1 && recentWorkouts.length >= 3) {
      alerts.add(FeedbackAlert(
        title: 'Variety Reminder',
        message:
            'All recent workouts are ${categories.keys.first}. Mixing muscle groups promotes balanced development and reduces overuse injury.',
        type: FeedbackType.formReminder,
      ));
    }

    return alerts;
  }
}
