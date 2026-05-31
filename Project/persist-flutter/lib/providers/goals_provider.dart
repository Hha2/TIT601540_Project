import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';

class GoalsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<GoalModel> _goals = [];
  bool _loading = true;
  StreamSubscription? _sub;
  String? _uid;
  bool _syncingDailyStatus = false;

  List<GoalModel> get goals => _goals;
  bool get loading => _loading;
  List<GoalModel> get activeGoals => _goals.where((g) => g.active).toList();

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  int get totalGoals => _goals.length;
  int get activeGoalCount => activeGoals.length;
  int get completedGoals => _goals.where((g) => !g.active && g.completedDays >= g.totalDays).length;

  int get totalPlannedTasks {
    var total = 0;
    for (final goal in _goals) {
      for (final day in goal.days) {
        total += day.tasks.length;
      }
    }
    return total;
  }

  int get totalCompletedTasks {
    var total = 0;
    for (final goal in _goals) {
      for (final day in goal.days) {
        total += day.doneCount;
      }
    }
    return total;
  }

  int get totalOverdueDays => activeGoals.fold<int>(0, (sum, goal) => sum + goal.overdueDays);

  double get overallCompletionRate {
    if (totalPlannedTasks == 0) return 0.0;
    return (totalCompletedTasks / totalPlannedTasks).clamp(0.0, 1.0);
  }

  int get bestStreak {
    if (_goals.isEmpty) return 0;
    return _goals.map((g) => g.streakDays).fold<int>(0, (a, b) => a > b ? a : b);
  }

  int get currentStreak {
    if (activeGoals.isEmpty) return bestStreak;
    return activeGoals.map((g) => g.streakDays).fold<int>(0, (a, b) => a > b ? a : b);
  }

  int get stabilityScore {
    final completion = overallCompletionRate * 52;
    final streakBoost = (currentStreak.clamp(0, 14) / 14) * 22;
    final activeBoost = activeGoalCount > 0 ? 10 : 0;
    final openTasks = getTodayTasks().length;
    final openTaskPenalty = openTasks >= 6 ? 8 : openTasks >= 3 ? 4 : 0;
    final overduePenalty = (totalOverdueDays * 8).clamp(0, 28);
    final score = 12 + completion + streakBoost + activeBoost - openTaskPenalty - overduePenalty;
    return score.round().clamp(0, 100);
  }

  double get skipProbability {
    final openTasks = getTodayTasks().length;
    final completionRisk = 1 - overallCompletionRate;
    final overdueRisk = (totalOverdueDays / 5).clamp(0.0, 1.0);
    final openTaskRisk = (openTasks / 8).clamp(0.0, 1.0);
    final streakProtection = (currentStreak / 14).clamp(0.0, 1.0) * 0.18;
    final risk = (completionRisk * 0.38) + (overdueRisk * 0.38) + (openTaskRisk * 0.24) - streakProtection;
    return risk.clamp(0.02, 0.95);
  }

  void init(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _loading = true;
    notifyListeners();

    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _goals = snap.docs.map(GoalModel.fromFirestore).toList();
      _loading = false;
      notifyListeners();
      syncDailyStatus();
    });
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    _goals = [];
    _loading = true;
    notifyListeners();
  }

  Future<String> addGoal(GoalModel goal) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('goals')
        .add(goal.toFirestore());
    return ref.id;
  }

  Future<void> editGoal(String goalId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('goals')
        .doc(goalId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeGoal(String goalId) async {
    await _db.collection('users').doc(_uid).collection('goals').doc(goalId).delete();
  }

  Future<void> setGoalActive(String goalId, bool active) async {
    await editGoal(goalId, {'active': active});
  }

  Future<void> syncDailyStatus() async {
    if (_uid == null || _syncingDailyStatus) return;
    _syncingDailyStatus = true;
    try {
      for (final goal in List<GoalModel>.from(activeGoals)) {
        final todayIndex = goal.days.indexWhere((d) => d.status == 'today');
        if (todayIndex == -1) continue;

        final currentDay = goal.days[todayIndex];

        // Rule: finishing all tasks does NOT unlock the next day immediately.
        // It unlocks next day only after the date changes.
        final completedEarlier = currentDay.allDone &&
            currentDay.completedDate != null &&
            currentDay.completedDate != _today;

        // Backward compatibility for old completed days without completedDate.
        final oldCompletedWithoutDate = currentDay.allDone && currentDay.completedDate == null;

        if (!completedEarlier && !oldCompletedWithoutDate) continue;

        var active = goal.active;
        final nextIndex = todayIndex + 1;
        final updatedDays = List<DayModel>.generate(goal.days.length, (i) {
          final day = goal.days[i];
          if (i == todayIndex) {
            return day.copyWith(status: 'done', completedDate: day.completedDate ?? _today);
          }
          if (i == nextIndex) {
            return day.copyWith(status: 'today', activatedDate: _today, clearCompletedDate: true);
          }
          return day;
        });

        if (nextIndex >= goal.days.length) {
          active = false;
        }

        final completedDays = updatedDays.where((day) => day.status == 'done').length;
        await editGoal(goal.id, {
          'days': updatedDays.map((d) => d.toMap()).toList(),
          'completedDays': completedDays,
          'streakDays': completedDays,
          'active': active,
        });
      }
    } finally {
      _syncingDailyStatus = false;
    }
  }

  Future<void> toggleTask(String goalId, String dayId, String taskId, bool done) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    var changedDayIndex = -1;

    final updatedDays = <DayModel>[];
    for (var i = 0; i < goal.days.length; i++) {
      final day = goal.days[i];
      if (day.id != dayId) {
        updatedDays.add(day);
        continue;
      }

      changedDayIndex = i;
      final updatedTasks = day.tasks.map((task) {
        if (task.id != taskId) return task;
        return task.copyWith(
          done: done,
          completedAt: done ? DateTime.now() : null,
          clearCompletedAt: !done,
        );
      }).toList();

      final updatedDay = day.copyWith(
        tasks: updatedTasks,
        activatedDate: day.activatedDate ?? _today,
        completedDate: updatedTasks.isNotEmpty && updatedTasks.every((t) => t.done) ? _today : null,
        clearCompletedDate: !(updatedTasks.isNotEmpty && updatedTasks.every((t) => t.done)),
      );

      updatedDays.add(updatedDay);
    }

    if (changedDayIndex == -1) return;

    // Important: do NOT advance to next day here.
    // The day stays completed/waiting until tomorrow.
    final completedDays = updatedDays.where((day) => day.status == 'done').length;

    await editGoal(goalId, {
      'days': updatedDays.map((d) => d.toMap()).toList(),
      'completedDays': completedDays,
      'active': goal.active,
    });
  }

  List<Map<String, dynamic>> getTodayTasks() {
    final result = <Map<String, dynamic>>[];
    for (final goal in activeGoals) {
      final today = goal.todayDay;
      if (today == null) continue;

      for (final task in today.tasks.where((task) => !task.done)) {
        result.add({
          'goalId': goal.id,
          'goalName': goal.name,
          'goalCategory': goal.category,
          'categoryEmoji': goal.categoryEmoji,
          'dayId': today.id,
          'dayTitle': today.title,
          'dayNum': today.dayNum,
          'doneCount': today.doneCount,
          'totalCount': today.tasks.length,
          'overdueDays': today.overdueDays,
          'task': task,
        });
      }
    }
    return result;
  }

  List<Map<String, dynamic>> getTodayGoalSummaries() {
    return activeGoals.map((goal) {
      final day = goal.todayDay;
      if (day == null) return null;
      return {
        'goalId': goal.id,
        'goalName': goal.name,
        'goalCategory': goal.category,
        'dayTitle': day.title,
        'dayNum': day.dayNum,
        'doneCount': day.doneCount,
        'totalCount': day.tasks.length,
        'openCount': day.openCount,
        'overdueDays': day.overdueDays,
        'allDone': day.allDone,
        'completionRate': day.completionRate,
      };
    }).whereType<Map<String, dynamic>>().toList();
  }

  int get totalTasksDoneToday {
    int count = 0;
    for (final goal in activeGoals) {
      count += goal.todayDay?.doneCount ?? 0;
    }
    return count;
  }
}
