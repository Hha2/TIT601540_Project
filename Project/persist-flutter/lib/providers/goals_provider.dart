import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

class GoalsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<GoalModel> _goals = [];
  bool _loading = true;
  StreamSubscription? _sub;
  String? _uid;

  List<GoalModel> get goals => _goals;
  bool get loading => _loading;
  List<GoalModel> get activeGoals => _goals.where((g) => g.active).toList();

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
    await _db
        .collection('users')
        .doc(_uid)
        .collection('goals')
        .doc(goalId)
        .delete();
  }

  Future<void> setGoalActive(String goalId, bool active) async {
    await editGoal(goalId, {'active': active});
  }

  Future<void> toggleTask(
      String goalId, String dayId, String taskId, bool done) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final days = goal.days.map((day) {
      if (day.id != dayId) return day;
      final tasks = day.tasks.map((t) {
        return t.id == taskId ? t.copyWith(done: done) : t;
      }).toList();
      return day.copyWith(tasks: tasks);
    }).toList();

    await editGoal(goalId, {'days': days.map((d) => d.toMap()).toList()});
  }

  List<Map<String, dynamic>> getTodayTasks() {
    final result = <Map<String, dynamic>>[];
    for (final goal in activeGoals) {
      final today = goal.todayDay;
      if (today == null) continue;
      for (final task in today.tasks) {
        result.add({
          'goalId': goal.id,
          'goalName': goal.name,
          'goalCategory': goal.category,
          'categoryEmoji': goal.categoryEmoji,
          'dayId': today.id,
          'task': task,
        });
      }
    }
    return result;
  }

  int get totalTasksDoneToday {
    int count = 0;
    for (final goal in activeGoals) {
      count += goal.todayDay?.doneCount ?? 0;
    }
    return count;
  }
}
