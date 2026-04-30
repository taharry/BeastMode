import 'package:cloud_firestore/cloud_firestore.dart';

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
