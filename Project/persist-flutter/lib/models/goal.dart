import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String text;
  final bool done;

  const TaskModel({required this.id, required this.text, this.done = false});

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: map['id'] ?? '',
        text: map['text'] ?? '',
        done: map['done'] ?? false,
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};

  TaskModel copyWith({String? id, String? text, bool? done}) => TaskModel(
        id: id ?? this.id,
        text: text ?? this.text,
        done: done ?? this.done,
      );
}

class DayModel {
  final String id;
  final int dayNum;
  final String title;
  final String status; // 'today' | 'upcoming' | 'done'
  final List<TaskModel> tasks;

  const DayModel({
    required this.id,
    required this.dayNum,
    required this.title,
    required this.status,
    required this.tasks,
  });

  factory DayModel.fromMap(Map<String, dynamic> map) => DayModel(
        id: map['id'] ?? '',
        dayNum: map['dayNum'] ?? 0,
        title: map['title'] ?? '',
        status: map['status'] ?? 'upcoming',
        tasks: (map['tasks'] as List<dynamic>? ?? [])
            .map((t) => TaskModel.fromMap(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayNum': dayNum,
        'title': title,
        'status': status,
        'tasks': tasks.map((t) => t.toMap()).toList(),
      };

  DayModel copyWith({
    String? id,
    int? dayNum,
    String? title,
    String? status,
    List<TaskModel>? tasks,
  }) =>
      DayModel(
        id: id ?? this.id,
        dayNum: dayNum ?? this.dayNum,
        title: title ?? this.title,
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
      );

  int get doneCount => tasks.where((t) => t.done).length;
  bool get allDone => tasks.isNotEmpty && tasks.every((t) => t.done);
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
    return GoalModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Learning',
      totalDays: data['totalDays'] ?? 0,
      dueDate: data['dueDate'] ?? '',
      completedDays: data['completedDays'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      active: data['active'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      days: (data['days'] as List<dynamic>? ?? [])
          .map((d) => DayModel.fromMap(d as Map<String, dynamic>))
          .toList(),
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

  double get progressPercent =>
      totalDays > 0 ? completedDays / totalDays : 0.0;

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
