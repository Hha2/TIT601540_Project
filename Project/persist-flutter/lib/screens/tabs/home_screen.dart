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
    if (task.done) return;

    // Show mood modal
    final mood = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoodModal(theme: context.read<ThemeProvider>().theme),
    );

    if (mood == null || !mounted) return;

    // Log mood and complete task
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

    setState(() {
      _pendingUndoTaskId = task.id;
    });
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _pendingUndoTaskId = null);
    });
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
    final stability = auth.profile?.stabilityScore ?? 72;
    final streak = auth.profile?.streak ?? 0;

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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('👑', style: TextStyle(fontSize: 20)),
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
                          'No tasks for today!',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a goal to get started.',
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

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: AnimatedOpacity(
                        opacity: task.done && !isUndo ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.border),
                          ),
                          child: isUndo
                              ? Row(
                                  children: [
                                    Text('✅ Done!',
                                        style: TextStyle(color: theme.accent)),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => _undoTask(entry),
                                      child: Text('Undo',
                                          style: TextStyle(color: theme.accent)),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(entry['categoryEmoji'] ?? '🎯',
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.text,
                                            style: TextStyle(
                                              color: theme.text,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              decoration: task.done
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            entry['goalName'] ?? '',
                                            style: TextStyle(
                                              color: theme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: task.done
                                          ? null
                                          : () => _handleTaskTap(entry),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: task.done
                                              ? theme.accent
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: task.done
                                                ? theme.accent
                                                : theme.border,
                                            width: 2,
                                          ),
                                        ),
                                        child: task.done
                                            ? const Icon(Icons.check,
                                                color: Colors.white, size: 14)
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
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
