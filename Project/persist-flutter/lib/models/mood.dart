import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final int mood; // 0-4
  final String? taskId;
  final DateTime timestamp;
  final String date;
  final int hour;

  const MoodEntry({
    required this.id,
    required this.mood,
    this.taskId,
    required this.timestamp,
    required this.date,
    required this.hour,
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      mood: data['mood'] ?? 0,
      taskId: data['taskId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: data['date'] ?? '',
      hour: data['hour'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'mood': mood,
        if (taskId != null) 'taskId': taskId,
        'timestamp': Timestamp.fromDate(timestamp),
        'date': date,
        'hour': hour,
      };

  static const moodEmojis = ['😞', '😕', '😐', '🙂', '😄'];
  static const moodLabels = ['Rough', 'Meh', 'Okay', 'Good', 'Great'];

  String get emoji => moodEmojis[mood.clamp(0, 4)];
  String get label => moodLabels[mood.clamp(0, 4)];
}
