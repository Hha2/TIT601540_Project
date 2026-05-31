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
  final Map<String, AnimationController> _fillControllers = {};
  String? _pendingUndoTaskId;
  String? _completingTaskId;
  Timer? _undoTimer;
  List<Map<String, dynamic>> _localTasks = [];
  List<double> _moodData = [];
  bool _moodLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final svc = FirestoreService(uid);
    final moods = await svc.getMoodsLast7Days();

    final grouped = <String, List<int>>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      grouped[DateFormat('yyyy-MM-dd').format(day)] = [];
    }
    for (final m in moods) {
      grouped[m.date]?.add(m.mood);
    }

    final data = grouped.values.map((vals) {
      if (vals.isEmpty) return 2.0;
      return vals.reduce((a, b) => a + b) / vals.length;
    }).toList();

    if (mounted) {
      setState(() {
        _moodData = data;
        _moodLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tasks = context.read<GoalsProvider>().getTodayTasks();
    if (_localTasks.isEmpty) {
      _localTasks = tasks;
    }
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    for (final c in _fillControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleTaskTap(Map<String, dynamic> taskEntry) async {
    final task = taskEntry['task'];
    if (task.done || _completingTaskId != null) return;

    final mood = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodModal(theme: context.read<ThemeProvider>().theme),
    );

    if (mood == null || !mounted) return;

    setState(() => _completingTaskId = task.id);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final uid = context.read<AuthProvider>().user?.uid;
    final goalsProvider = context.read<GoalsProvider>();
    if (uid != null) {
      final svc = FirestoreService(uid);
      await svc.logMood(mood, taskId: task.id);
      await svc.logTaskComplete(
        taskEntry['goalId'],
        taskEntry['dayId'],
        task.id,
      );
      if (!mounted) return;
      await goalsProvider.toggleTask(
        taskEntry['goalId'],
        taskEntry['dayId'],
        task.id,
        true,
      );
    }

    _undoTimer?.cancel();
    if (mounted) {
      setState(() {
        _pendingUndoTaskId = null;
        _completingTaskId = null;
      });
    }
  }

  Future<void> _undoTask(Map<String, dynamic> taskEntry) async {
    _undoTimer?.cancel();
    setState(() => _pendingUndoTaskId = null);
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      await context.read<GoalsProvider>().toggleTask(
            taskEntry['goalId'],
            taskEntry['dayId'],
            taskEntry['task'].id,
            false,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final auth = context.watch<AuthProvider>();
    final goals = context.watch<GoalsProvider>();
    final name = auth.profile?.name ?? 'Friend';
    final tasks = goals.getTodayTasks();
    final summaries = goals.getTodayGoalSummaries();
    final allVisibleDaysComplete = summaries.isNotEmpty && summaries.every((s) => s['allDone'] == true);
    final stability = goals.stabilityScore;
    final streak = goals.currentStreak;

    return Scaffold(
      backgroundColor: theme.background,
      body: RefreshIndicator(
        onRefresh: _loadMoodData,
        color: theme.accent,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: theme.headerGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _showUpgradeDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stat cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _StatCard(
                      theme: theme,
                      label: 'Stability',
                      value: '$stability%',
                      icon: '⚡',
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      theme: theme,
                      label: 'Tasks Done',
                      value: '${goals.totalTasksDoneToday}',
                      icon: '✅',
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      theme: theme,
                      label: 'Active Goals',
                      value: '${goals.activeGoals.length}',
                      icon: '🎯',
                    ),
                  ],
                ),
              ),
            ),

            // Mood chart
            if (!_moodLoading && _moodData.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Behavior Trend',
                              style: TextStyle(
                                color: theme.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (streak > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.accentSoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '🔥 $streak days',
                                  style: TextStyle(
                                    color: theme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: MoodLineChart(data: _moodData, theme: theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Today's tasks
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  "Today's Tasks",
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            if (summaries.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: summaries.map((summary) {
                      final done = summary['doneCount'] as int;
                      final total = summary['totalCount'] as int;
                      final open = summary['openCount'] as int;
                      final overdue = summary['overdueDays'] as int;
                      final allDone = summary['allDone'] == true;
                      final rate = (summary['completionRate'] as double).clamp(0.0, 1.0);

                      final statusText = allDone
                          ? 'Day ${summary['dayNum']} complete. Next day unlocks tomorrow.'
                          : overdue > 0
                              ? '$open task${open == 1 ? '' : 's'} left • $overdue day${overdue == 1 ? '' : 's'} overdue'
                              : '$open task${open == 1 ? '' : 's'} left today';

                      final statusColor = allDone
                          ? theme.success
                          : overdue > 0
                              ? theme.danger
                              : theme.accent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: allDone
                              ? theme.success.withValues(alpha: 0.08)
                              : overdue > 0
                                  ? theme.danger.withValues(alpha: 0.08)
                                  : theme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    allDone
                                        ? Icons.lock_clock_rounded
                                        : overdue > 0
                                            ? Icons.warning_amber_rounded
                                            : _categoryIcon(summary['goalCategory']),
                                    color: statusColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${summary['goalCategory']} • ${summary['goalName']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: theme.text,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$done/$total',
                                  style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: rate,
                                minHeight: 7,
                                backgroundColor: theme.border,
                                valueColor: AlwaysStoppedAnimation(statusColor),
                              ),
                            ),
                            if (overdue > 0 && !allDone) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Impact: stability drops and skip risk rises until this day is cleared.',
                                style: TextStyle(color: theme.textMuted, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            if (tasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Text('🎉', style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          allVisibleDaysComplete ? 'Today is complete!' : 'No tasks for today!',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allVisibleDaysComplete ? 'Next day unlocks tomorrow. Rest without guilt.' : 'Create a goal to get started.',
                          style: TextStyle(color: theme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = tasks[index];
                    final task = entry['task'];
                    final isUndo = _pendingUndoTaskId == task.id;

                    final currentHeading =
                        '${entry['goalCategory'] ?? 'Goal'} • ${entry['goalName'] ?? ''}';

                    String? previousHeading;
                    if (index > 0) {
                      final previousEntry = tasks[index - 1];
                      previousHeading =
                          '${previousEntry['goalCategory'] ?? 'Goal'} • ${previousEntry['goalName'] ?? ''}';
                    }

                    final showHeading = index == 0 || currentHeading != previousHeading;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeading)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: AnimatedOpacity(
                            opacity: task.done && !isUndo ? 0.5 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: GestureDetector(
                              onTap: task.done ? null : () => _handleTaskTap(entry),
                              child: Stack(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: _completingTaskId == task.id ? 1 : 0,
                                    ),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          minHeight: 62,
                                          backgroundColor: theme.card,
                                          valueColor: AlwaysStoppedAnimation(theme.accentSoft),
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _completingTaskId == task.id ? theme.accent : theme.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedScale(
                                          duration: const Duration(milliseconds: 220),
                                          scale: _completingTaskId == task.id ? 1.08 : 1,
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: theme.accentSoft,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _categoryIcon(entry['goalCategory']),
                                              color: theme.accent,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            task.text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: theme.text,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              decoration: task.done ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 220),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_completingTaskId == task.id || task.done)
                                                ? theme.accent
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: (_completingTaskId == task.id || task.done)
                                                  ? theme.accent
                                                  : theme.border,
                                              width: 2,
                                            ),
                                          ),
                                          child: (_completingTaskId == task.id || task.done)
                                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: tasks.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    final theme = context.read<ThemeProvider>().theme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Persist Premium', style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
        content: Text(
          'Premium preview: unlimited goals, deeper AI coaching, weekly reports, advanced risk insights, and smart reminders. This is a demo action for presentation.',
          style: TextStyle(color: theme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.accent)),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  IconData _categoryIcon(String? category) {
    final c = (category ?? '').toLowerCase();

    if (c.contains('study') || c.contains('learning') || c.contains('education')) {
      return Icons.school_rounded;
    }
    if (c.contains('fitness') || c.contains('health') || c.contains('workout')) {
      return Icons.fitness_center_rounded;
    }
    if (c.contains('work') || c.contains('career') || c.contains('productivity')) {
      return Icons.work_rounded;
    }
    if (c.contains('money') || c.contains('finance') || c.contains('saving')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (c.contains('mind') || c.contains('mental') || c.contains('reflect')) {
      return Icons.psychology_rounded;
    }
    if (c.contains('creative') || c.contains('art') || c.contains('design')) {
      return Icons.brush_rounded;
    }

    return Icons.flag_rounded;
  }
}

class _StatCard extends StatelessWidget {
  final dynamic theme;
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: theme.textMuted, fontSize: 11),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How do you feel?',
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'After completing this task',
              style: TextStyle(color: theme.textMuted),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, i),
                  child: Column(
                    children: [
                      Text(
                        MoodEntry.moodEmojis[i],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MoodEntry.moodLabels[i],
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
