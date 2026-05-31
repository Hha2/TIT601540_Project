import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/mood.dart';
import '../../widgets/mood_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<double> _moodData = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _completingTaskKey;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    final svc = FirestoreService(uid);
    final moods = await svc.getMoodsLast7Days();
    final events = await svc.getTaskCompletionEventsLast7Days();

    final grouped = <String, List<int>>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      grouped[DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)))] = [];
    }
    for (final mood in moods) {
      grouped[mood.date]?.add(mood.mood);
    }

    if (!mounted) return;
    setState(() {
      _moodData = grouped.values.map((values) {
        if (values.isEmpty) return 2.0;
        return values.reduce((a, b) => a + b) / values.length;
      }).toList();
      _events = events;
      _loading = false;
    });
  }

  Future<void> _handleTaskTap(Map<String, dynamic> entry) async {
    final task = entry['task'];
    if (task.done || _completingTaskKey != null) return;

    final mood = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodModal(theme: context.read<ThemeProvider>().theme),
    );

    if (mood == null || !mounted) return;

    setState(() => _completingTaskKey = _entryKey(entry));
    await Future.delayed(const Duration(milliseconds: 680));

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      final svc = FirestoreService(uid);
      await svc.logMood(mood, taskId: task.id);
      await svc.logTaskComplete(entry['goalId'], entry['dayId'], task.id);
      await context.read<GoalsProvider>().toggleTask(
            entry['goalId'],
            entry['dayId'],
            task.id,
            true,
          );
    }

    if (!mounted) return;
    setState(() => _completingTaskKey = null);
    _loadData();
  }

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final auth = context.watch<AuthProvider>();
    final goals = context.watch<GoalsProvider>();
    final name = auth.profile?.name.split(' ').first ?? 'Friend';
    final tasks = goals.getTodayTasks();
    final summaries = goals.getTodayGoalSummaries();
    final stability = goals.stabilityScore;
    final skipRisk = (goals.skipProbability * 100).round().clamp(0, 100);
    final allDone = summaries.isNotEmpty && summaries.every((s) => s['allDone'] == true);

    return Scaffold(
      backgroundColor: theme.background,
      body: RefreshIndicator(
        color: theme.accent,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(theme: theme, name: name, onPremium: _showUpgradeDialog),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _FocusCard(
                  theme: theme,
                  tasks: tasks,
                  allDone: allDone,
                  summaries: summaries,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _StabilityCard(
                  theme: theme,
                  score: stability,
                  risk: skipRisk,
                  events: _events,
                  streak: goals.currentStreak,
                ),
              ),
            ),
            if (!_loading && _moodData.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _MoodTrendCard(theme: theme, data: _moodData),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                child: Text(
                  'Today\'s tasks',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (tasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _EmptyTaskCard(
                    theme: theme,
                    allDone: allDone,
                    hasGoals: goals.activeGoals.isNotEmpty,
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = tasks[index];
                    final task = entry['task'];
                    final currentHeading = '${entry['goalCategory']} • ${entry['goalName']}';
                    final previousHeading = index == 0
                        ? null
                        : '${tasks[index - 1]['goalCategory']} • ${tasks[index - 1]['goalName']}';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentHeading != previousHeading)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcon(entry['goalCategory']),
                                  color: theme.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    currentHeading,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.text,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                          child: _TaskCard(
                            theme: theme,
                            entry: entry,
                            completing: _completingTaskKey == _entryKey(entry),
                            onTap: () => _handleTaskTap(entry),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: tasks.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String? category) => categoryIcon(category);

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (_) {
        final theme = context.read<ThemeProvider>().theme;
        return AlertDialog(
          backgroundColor: theme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Persist Premium',
            style: TextStyle(color: theme.text, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Advanced patterns, deeper AI coaching, custom reminders, and weekly recovery reports. Demo preview only.',
            style: TextStyle(color: theme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: theme.accent)),
            ),
          ],
        );
      },
    );
  }
}

IconData categoryIcon(String? category) {
  final c = (category ?? '').toLowerCase();
  if (c.contains('learn') || c.contains('study')) return Icons.school_rounded;
  if (c.contains('fit') || c.contains('health')) return Icons.favorite_rounded;
  if (c.contains('mind')) return Icons.spa_rounded;
  if (c.contains('career')) return Icons.work_rounded;
  if (c.contains('creative')) return Icons.brush_rounded;
  return Icons.flag_rounded;
}

class _Header extends StatelessWidget {
  final dynamic theme;
  final String name;
  final VoidCallback onPremium;

  const _Header({required this.theme, required this.name, required this.onPremium});

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: theme.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Small steps. Lasting change.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Good day, $name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onPremium,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final dynamic theme;
  final List tasks;
  final bool allDone;
  final List<Map<String, dynamic>> summaries;

  const _FocusCard({
    required this.theme,
    required this.tasks,
    required this.allDone,
    required this.summaries,
  });

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = summaries.fold<int>(0, (sum, item) {
      return sum + (item['overdueDays'] as int? ?? 0);
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: theme.linearGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Day complete' : overdue > 0 ? 'Recovery focus' : 'Today’s focus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  allDone
                      ? 'Next day unlocks tomorrow. Rest or reflect now.'
                      : overdue > 0
                          ? 'You are $overdue day(s) behind. Clear the oldest active day first.'
                          : '${tasks.length} small action(s) waiting. Start with the easiest one.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .84), height: 1.35),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              allDone ? 'Done' : 'Start',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _StabilityCard extends StatelessWidget {
  final dynamic theme;
  final int score;
  final int risk;
  final List<Map<String, dynamic>> events;
  final int streak;

  const _StabilityCard({
    required this.theme,
    required this.score,
    required this.risk,
    required this.events,
    required this.streak,
  });

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final keys = events.map((event) {
      return DateFormat('yyyy-MM-dd').format(event['timestamp'] as DateTime);
    }).toSet();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly stability',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$streak day streak • Skip risk $risk%',
                      style: TextStyle(color: theme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: theme.border,
                      valueColor: AlwaysStoppedAnimation(theme.accent),
                    ),
                    Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (i) {
              final day = now.subtract(Duration(days: 6 - i));
              final key = DateFormat('yyyy-MM-dd').format(day);
              final done = keys.contains(key);
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: done ? theme.accent : theme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: done ? theme.accent : theme.border),
                      ),
                      child: Icon(
                        done ? Icons.check_rounded : Icons.circle_outlined,
                        size: 16,
                        color: done ? Colors.white : theme.textFaint,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            score >= 70
                ? 'Momentum is healthy. Protect it with one small action.'
                : score >= 45
                    ? 'A bit wobbly. Finish one easy task to stabilize today.'
                    : 'Fragile day. Do not chase perfection — restart with two minutes.',
            style: TextStyle(color: theme.textMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendCard extends StatelessWidget {
  final dynamic theme;
  final List<double> data;

  const _MoodTrendCard({required this.theme, required this.data});

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood trend',
            style: TextStyle(color: theme.text, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 94, child: MoodLineChart(data: data, theme: theme)),
        ],
      ),
    );
  }
}

class _EmptyTaskCard extends StatelessWidget {
  final dynamic theme;
  final bool allDone;
  final bool hasGoals;

  const _EmptyTaskCard({required this.theme, required this.allDone, required this.hasGoals});

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(
            allDone ? Icons.verified_rounded : Icons.flag_rounded,
            color: theme.accent,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            allDone ? 'Today is complete' : 'No active tasks',
            style: TextStyle(color: theme.text, fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            allDone
                ? 'Your next day appears tomorrow.'
                : hasGoals
                    ? 'Your current active days are clear.'
                    : 'Create a goal to start your plan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic theme;
  final Map<String, dynamic> entry;
  final bool completing;
  final VoidCallback onTap;

  const _TaskCard({
    required this.theme,
    required this.entry,
    required this.completing,
    required this.onTap,
  });

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    final task = entry['task'];
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      categoryIcon(entry['goalCategory']),
                      color: theme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['dayTitle'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          task.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.accent, width: 2),
                    ),
                    child: completing
                        ? Icon(Icons.check_rounded, size: 16, color: theme.accent)
                        : null,
                  ),
                ],
              ),
            ),
            if (completing)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 620),
                  builder: (_, value, __) {
                    return FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: Container(color: theme.accent.withValues(alpha: .16)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MoodModal extends StatelessWidget {
  final dynamic theme;

  const _MoodModal({required this.theme});

  String _entryKey(Map<String, dynamic> entry) {
    final task = entry['task'];
    return '${entry['goalId']}::${entry['dayId']}::${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'How do you feel after this task?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(MoodEntry.moodEmojis[i], style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 5),
                    Text(
                      MoodEntry.moodLabels[i],
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
