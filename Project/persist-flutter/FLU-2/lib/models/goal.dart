import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

class TaskModel {
  final String id;
  final String text;
  final bool done;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.text,
    this.done = false,
    this.completedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final rawCompletedAt = map['completedAt'];
    DateTime? completedAt;
    if (rawCompletedAt is Timestamp) {
      completedAt = rawCompletedAt.toDate();
    } else if (rawCompletedAt is String) {
      completedAt = DateTime.tryParse(rawCompletedAt);
    }

    return TaskModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      done: map['done'] ?? false,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'done': done,
        if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      };

  TaskModel copyWith({
    String? id,
    String? text,
    bool? done,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) =>
      TaskModel(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
        completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      );
}

class DayModel {
  final String id;
  final int dayNum;
  final String title;
  final String status; // 'today' | 'upcoming' | 'done'
  final List<TaskModel> tasks;
  final String? activatedDate;
  final String? completedDate;

  const DayModel({
    required this.id,
    required this.dayNum,
    required this.title,
    required this.status,
    required this.tasks,
    this.activatedDate,
    this.completedDate,
  });

  factory DayModel.fromMap(Map<String, dynamic> map) => DayModel(
        id: map['id'] ?? '',
        dayNum: map['dayNum'] ?? 0,
        title: map['title'] ?? '',
        status: map['status'] ?? 'upcoming',
        activatedDate: map['activatedDate'] as String?,
        completedDate: map['completedDate'] as String?,
        tasks: (map['tasks'] as List<dynamic>? ?? [])
            .map((t) => TaskModel.fromMap(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayNum': dayNum,
        'title': title,
        'status': status,
        if (activatedDate != null) 'activatedDate': activatedDate,
        if (completedDate != null) 'completedDate': completedDate,
        'tasks': tasks.map((t) => t.toMap()).toList(),
      };

  DayModel copyWith({
    String? id,
    int? dayNum,
    String? title,
    String? status,
    List<TaskModel>? tasks,
    String? activatedDate,
    String? completedDate,
    bool clearCompletedDate = false,
  }) =>
      DayModel(
        id: id ?? this.id,
        dayNum: dayNum ?? this.dayNum,
        title: title ?? this.title,
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
        activatedDate: activatedDate ?? this.activatedDate,
        completedDate: clearCompletedDate ? null : completedDate ?? this.completedDate,
      );

  int get doneCount => tasks.where((t) => t.done).length;
  int get openCount => tasks.length - doneCount;
  bool get allDone => tasks.isNotEmpty && tasks.every((t) => t.done);
  double get completionRate => tasks.isEmpty ? 0.0 : doneCount / tasks.length;

  int get overdueDays {
    if (status != 'today' || allDone) return 0;
    final key = activatedDate;
    if (key == null) return 0;
    final start = DateTime.tryParse(key);
    if (start == null) return 0;
    final today = DateTime.now();
    final startDate = DateTime(start.year, start.month, start.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final diff = todayDate.difference(startDate).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class GoalModel {
  final String id;
  final String name;
  final String category;
  final int totalDays;
  final String dueDate;
  final int completedDays;
  final int streakDays;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DayModel> days;

  const GoalModel({
    required this.id,
    required this.name,
    required this.category,
    required this.totalDays,
    required this.dueDate,
    required this.completedDays,
    required this.streakDays,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.days,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final days = (data['days'] as List<dynamic>? ?? [])
        .map((d) => DayModel.fromMap(d as Map<String, dynamic>))
        .toList();

    // Backward compatibility: old goals may have a today day without activation date.
    final todayKey = _todayKey();
    final normalizedDays = days.map((day) {
      if (day.status == 'today' && day.activatedDate == null) {
        return day.copyWith(activatedDate: todayKey);
      }
      return day;
    }).toList();

    return GoalModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Learning',
      totalDays: data['totalDays'] ?? normalizedDays.length,
      dueDate: data['dueDate'] ?? '',
      completedDays: data['completedDays'] ?? normalizedDays.where((d) => d.status == 'done').length,
      streakDays: data['streakDays'] ?? 0,
      active: data['active'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      days: normalizedDays,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'totalDays': totalDays,
        'dueDate': dueDate,
        'completedDays': completedDays,
        'streakDays': streakDays,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'days': days.map((d) => d.toMap()).toList(),
      };

  double get progressPercent => totalDays > 0 ? completedDays / totalDays : 0.0;

  String get categoryEmoji {
    switch (category) {
      case 'Learning':
        return '📚';
      case 'Fitness':
        return '💪';
      case 'Mindfulness':
        return '🧘';
      case 'Career':
        return '💼';
      case 'Health':
        return '❤️';
      case 'Creative':
        return '🎨';
      default:
        return '🎯';
    }
  }

  DayModel? get todayDay {
    try {
      return days.firstWhere((d) => d.status == 'today');
    } catch (_) {
      return null;
    }
  }

  int get overdueDays => todayDay?.overdueDays ?? 0;
  bool get isTodayCompleteWaiting => active && todayDay != null && todayDay!.allDone && todayDay!.completedDate == _todayKey();
  List<TaskModel> get todayTasks => todayDay?.tasks ?? [];

  GoalModel copyWith({
    String? id,
    String? name,
    String? category,
    int? totalDays,
    String? dueDate,
    int? completedDays,
    int? streakDays,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DayModel>? days,
  }) =>
      GoalModel(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        totalDays: totalDays ?? this.totalDays,
        dueDate: dueDate ?? this.dueDate,
        completedDays: completedDays ?? this.completedDays,
        streakDays: streakDays ?? this.streakDays,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        days: days ?? this.days,
      );
}
