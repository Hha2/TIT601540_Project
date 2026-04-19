import 'package:cloud_firestore/cloud_firestore.dart';

class AppUsageEntry {
  final String id;
  final String appName;
  final String category;
  final int minutes;
  final String date;
  final DateTime timestamp;

  const AppUsageEntry({
    required this.id,
    required this.appName,
    required this.category,
    required this.minutes,
    required this.date,
    required this.timestamp,
  });

  factory AppUsageEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUsageEntry(
      id: doc.id,
      appName: data['appName'] ?? '',
      category: data['category'] ?? 'Others',
      minutes: data['minutes'] ?? 0,
      date: data['date'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'appName': appName,
        'category': category,
        'minutes': minutes,
        'date': date,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  static const categoryIcons = {
    'Social': '💬',
    'Gaming': '🎮',
    'Entertainment': '🎬',
    'Productivity': '💼',
    'Others': '📱',
  };

  String get categoryIcon => categoryIcons[category] ?? '📱';

  String get formattedTime {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class CategoryUsage {
  final String category;
  final int totalMinutes;
  final List<AppUsageEntry> apps;

  const CategoryUsage({
    required this.category,
    required this.totalMinutes,
    required this.apps,
  });

  String get categoryIcon => AppUsageEntry.categoryIcons[category] ?? '📱';

  String get formattedTime {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
