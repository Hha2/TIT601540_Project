import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../models/app_usage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService(this.uid);

  // ── Moods ──────────────────────────────────────────────────────────────────

  Future<void> logMood(int mood, {String? taskId}) async {
    final now = DateTime.now();
    await _db.collection('users').doc(uid).collection('moods').add({
      'mood': mood,
      'taskId': taskId,
      'timestamp': Timestamp.fromDate(now),
      'date': DateFormat('yyyy-MM-dd').format(now),
      'hour': now.hour,
    });
  }

  Future<List<MoodEntry>> getMoodsLast7Days() async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('moods')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('timestamp')
        .get();
    return snap.docs.map(MoodEntry.fromFirestore).toList();
  }

  Future<double> getAvgMoodLast7Days() async {
    final moods = await getMoodsLast7Days();
    if (moods.isEmpty) return 2.0;
    final sum = moods.fold<int>(0, (acc, m) => acc + m.mood);
    return sum / moods.length;
  }

  // ── App Usage ──────────────────────────────────────────────────────────────

  Future<void> logAppUsage(String appName, String category, int minutes) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${date}_$appName';
    final ref = _db.collection('users').doc(uid).collection('appUsage').doc(docId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {
          'minutes': FieldValue.increment(minutes),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          'appName': appName,
          'category': category,
          'minutes': minutes,
          'date': date,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<List<AppUsageEntry>> getAppUsageToday() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('appUsage')
        .where('date', isEqualTo: date)
        .get();
    return snap.docs.map(AppUsageEntry.fromFirestore).toList();
  }

  Map<String, CategoryUsage> groupByCategory(List<AppUsageEntry> entries) {
    final map = <String, List<AppUsageEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    return map.map((cat, apps) => MapEntry(
          cat,
          CategoryUsage(
            category: cat,
            totalMinutes: apps.fold(0, (acc, a) => acc + a.minutes),
            apps: apps..sort((a, b) => b.minutes.compareTo(a.minutes)),
          ),
        ));
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<void> logTaskComplete(
      String goalId, String dayId, String taskId) async {
    final now = DateTime.now();
    await _db.collection('users').doc(uid).collection('events').add({
      'type': 'task_complete',
      'goalId': goalId,
      'dayId': dayId,
      'taskId': taskId,
      'timestamp': Timestamp.fromDate(now),
      'hour': now.hour,
    });
  }

  // ── Skip Probability ───────────────────────────────────────────────────────

  Future<double> calculateSkipProbability() async {
    final moods = await getMoodsLast7Days();
    final avgMood = moods.isEmpty
        ? 2.0
        : moods.fold<int>(0, (a, m) => a + m.mood) / moods.length;

    final since = DateTime.now().subtract(const Duration(days: 7));
    int eventCount = 0;
    try {
      final eventsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('events')
          .where('type', isEqualTo: 'task_complete')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
          .get();
      eventCount = eventsSnap.docs.length;
    } catch (_) {}

    const dayCount = 7;
    final completionRate = eventCount / (dayCount * 3).clamp(1, double.infinity);

    final moodFactor = (4 - avgMood) / 4 * 0.4;
    final completionFactor = (1 - completionRate.clamp(0.0, 1.0)) * 0.4;
    return (moodFactor + completionFactor).clamp(0.0, 0.95);
  }

  // ── Chats ──────────────────────────────────────────────────────────────────

  Future<void> saveChat(bool isUser, String text, {bool showLabel = false}) async {
    await _db.collection('users').doc(uid).collection('chats').add({
      'isUser': isUser,
      'text': text,
      'showLabel': showLabel,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> chatStream() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> deleteChat(String messageId) async {
    await _db.collection('users').doc(uid).collection('chats').doc(messageId).delete();
  }
}
