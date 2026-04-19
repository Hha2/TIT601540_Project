import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goals_provider.dart';
import '../providers/theme_provider.dart';
import '../models/goal.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalModel goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final Set<int> _expandedDays = {};
  final Map<String, TextEditingController> _addTaskCtrls = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand today's day
    final today = widget.goal.todayDay;
    if (today != null) {
      _expandedDays.add(today.dayNum);
    }
  }

  @override
  void dispose() {
    for (final c in _addTaskCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleTask(GoalModel goal, DayModel day, TaskModel task) async {
    await context.read<GoalsProvider>().toggleTask(
          goal.id,
          day.id,
          task.id,
          !task.done,
        );
  }

  String _weekLabel(int dayNum) {
    final week = ((dayNum - 1) ~/ 7) + 1;
    const labels = [
      'Foundations',
      'Core Concepts',
      'Building Up',
      'Deep Dive',
      'Mastery',
      'Advanced',
      'Final Sprint',
    ];
    if (week <= labels.length) return labels[week - 1];
    return 'Week $week';
  }

  Color _dayColor(dynamic theme, String status) {
    switch (status) {
      case 'done':
        return theme.accent;
      case 'today':
        return theme.gradient[0];
      default:
        return theme.textFaint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    // Watch provider so UI updates when tasks toggle
    final goalsProvider = context.watch<GoalsProvider>();
    final goal = goalsProvider.goals.firstWhere(
      (g) => g.id == widget.goal.id,
      orElse: () => widget.goal,
    );

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: theme.headerGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(goal.categoryEmoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            goal.category,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Hero(
                          tag: 'goal-name-${goal.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${goal.dueDate}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(goal.progressPercent * 100).toStringAsFixed(0)}% done',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.progressPercent,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: theme.gradientHeader[0],
          ),

          if (goal.days.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'No days planned yet.',
                    style: TextStyle(color: theme.textMuted),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final day = goal.days[index];
                  final isWeekStart = (day.dayNum - 1) % 7 == 0;
                  final isExpanded = _expandedDays.contains(day.dayNum);
                  final dayColor = _dayColor(theme, day.status);
                  final doneCount = day.doneCount;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week label
                      if (isWeekStart)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            _weekLabel(day.dayNum),
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                      // Day accordion
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: day.status == 'today'
                                  ? theme.accent
                                  : theme.border,
                              width: day.status == 'today' ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Header row
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() {
                                  if (isExpanded) {
                                    _expandedDays.remove(day.dayNum);
                                  } else {
                                    _expandedDays.add(day.dayNum);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      // Day number badge
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: dayColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${day.dayNum}',
                                            style: TextStyle(
                                              color: dayColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              day.title,
                                              style: TextStyle(
                                                color: theme.text,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              day.status == 'today'
                                                  ? 'Today · $doneCount/${day.tasks.length} done'
                                                  : day.status == 'done'
                                                      ? 'Completed ✓'
                                                      : 'Upcoming · ${day.tasks.length} tasks',
                                              style: TextStyle(
                                                color: day.status == 'today'
                                                    ? theme.accent
                                                    : theme.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: theme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Expanded content
                              if (isExpanded) ...[
                                Divider(height: 1, color: theme.border),
                                ...day.tasks.map((task) => _TaskRow(
                                      theme: theme,
                                      task: task,
                                      onToggle: () =>
                                          _toggleTask(goal, day, task),
                                    )),
                                // Add task row
                                _AddTaskRow(
                                  theme: theme,
                                  dayId: day.id,
                                  goalId: goal.id,
                                  controller: _addTaskCtrls.putIfAbsent(
                                    day.id,
                                    () => TextEditingController(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                childCount: goal.days.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final dynamic theme;
  final TaskModel task;
  final VoidCallback onToggle;

  const _TaskRow({required this.theme, required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? theme.accent : Colors.transparent,
                border: Border.all(
                  color: task.done ? theme.accent : theme.border,
                  width: 2,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.text,
              style: TextStyle(
                color: task.done ? theme.textMuted : theme.text,
                fontSize: 14,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskRow extends StatelessWidget {
  final dynamic theme;
  final String dayId;
  final String goalId;
  final TextEditingController controller;

  const _AddTaskRow({
    required this.theme,
    required this.dayId,
    required this.goalId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          Icon(Icons.add, color: theme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: theme.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add task...',
                hintStyle: TextStyle(color: theme.textFaint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (text) {
                if (text.trim().isEmpty) return;
                // In a full implementation, this would add the task via the provider
                controller.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}
