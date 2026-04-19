import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/goals_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/goal.dart';
import '../goal_detail_screen.dart';
import '../new_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _filter = 'Active';
  bool _isGrid = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final goalsProvider = context.watch<GoalsProvider>();
    final allGoals = goalsProvider.goals;

    List<GoalModel> filtered;
    switch (_filter) {
      case 'Active':
        filtered = allGoals.where((g) => g.active).toList();
        break;
      case 'Inactive':
        filtered = allGoals.where((g) => !g.active).toList();
        break;
      default:
        filtered = allGoals;
    }

    final activeCount = allGoals.where((g) => g.active).length;
    final avgProgress = allGoals.isEmpty
        ? 0.0
        : allGoals.fold<double>(0, (acc, g) => acc + g.progressPercent) /
            allGoals.length *
            100;
    final bestStreak = allGoals.isEmpty
        ? 0
        : allGoals.map((g) => g.streakDays).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          //Floating app bar
          SliverAppBar(  
            floating: true,
            backgroundColor: theme.background,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Goals',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGrid ? Icons.view_list : Icons.grid_view,
                  color: theme.textMuted,
                ),
                onPressed: () => setState(() => _isGrid = !_isGrid),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewGoalScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: theme.linearGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  _StatCard(theme: theme, label: 'Active', value: '$activeCount', icon: '🎯'),
                  const SizedBox(width: 8),
                  _StatCard(theme: theme, label: 'Avg Progress', value: '${avgProgress.toStringAsFixed(0)}%', icon: '📈'),
                  const SizedBox(width: 8),
                  _StatCard(theme: theme, label: 'Best Streak', value: '$bestStreak', icon: '🔥'),
                ],
              ),
            ),
          ),

          // Filter pills
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Active', 'All', 'Inactive'].map((f) {
                  final active = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? theme.accent : theme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? theme.accent : theme.border),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: active ? Colors.white : theme.textMuted,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (filtered.isEmpty)
            // Empty state
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Text('🎯', style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'No goals yet',
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "+ New" to create your first goal',
                        style: TextStyle(color: theme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_isGrid)
            // GRIDVIEW — 2-column grid layout
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final goal = filtered[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal))),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.categoryEmoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 8),
                            Text(
                              goal.name,
                              style: TextStyle(color: theme.text, fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: goal.progressPercent),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (_, value, __) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${(value * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(color: theme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: theme.border,
                                      valueColor: AlwaysStoppedAnimation(theme.accent),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            )
          else
            // list view (AnimatedSwitcher)
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_filter),
                  children: List.generate(
                    filtered.length,
                    (index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _GoalCard(goal: filtered[index], theme: theme),
                    ),
                  ),
                ),
              ),
            ),
          // bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final dynamic theme;
  final String label;
  final String value;
  final String icon;

  const _StatCard({required this.theme, required this.label, required this.value, required this.icon});

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
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: theme.text, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: theme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatefulWidget {
  final GoalModel goal;
  final dynamic theme;

  const _GoalCard({required this.goal, required this.theme});

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _expanded = false;
  double _scale = 1.0;

  void _showMenu() {
    final theme = widget.theme;
    final goal = widget.goal;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: theme.accent),
            title: Text('Edit Goal', style: TextStyle(color: theme.text)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewGoalScreen(goal: goal)),
              );
            },
          ),
          ListTile(
            leading: Icon(
              goal.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: theme.textMuted,
            ),
            title: Text(
              goal.active ? 'Deactivate' : 'Activate',
              style: TextStyle(color: theme.text),
            ),
            onTap: () {
              Navigator.pop(context);
              context.read<GoalsProvider>().setGoalActive(goal.id, !goal.active);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.danger),
            title: Text('Delete', style: TextStyle(color: theme.danger)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final theme = widget.theme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.card,
        title: Text('Delete Goal?', style: TextStyle(color: theme.text)),
        content: Text(
          'This will permanently delete "${widget.goal.name}" and all its progress.',
          style: TextStyle(color: theme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GoalsProvider>().removeGoal(widget.goal.id);
            },
            child: Text('Delete', style: TextStyle(color: theme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final theme = widget.theme;
    final progress = goal.progressPercent;
    final today = goal.todayDay;
    final todayTasks = today?.tasks.take(3).toList() ?? [];

    return GestureDetector(
      onLongPress: () {
        setState(() => _scale = 0.96);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _scale = 1.0);
        });
        _showMenu();
      },
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
      ),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${goal.categoryEmoji} ${goal.category}',
                        style: TextStyle(color: theme.accent, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: goal.active,
                      onChanged: (v) =>
                          context.read<GoalsProvider>().setGoalActive(goal.id, v),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: theme.textMuted),
                      onPressed: _showMenu,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Hero(
                  tag: 'goal-name-${goal.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      goal.name,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Due ${goal.dueDate}',
                  style: TextStyle(color: theme.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}% done',
                          style: TextStyle(color: theme.textMuted, fontSize: 12),
                        ),
                        Text(
                          '${goal.completedDays}/${goal.totalDays} days',
                          style: TextStyle(color: theme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: theme.border,
                          valueColor: AlwaysStoppedAnimation(theme.accent),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Today tasks preview
              if (todayTasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Today's tasks",
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                ...todayTasks.map((t) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                      child: Row(
                        children: [
                          Icon(
                            t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 14,
                            color: t.done ? theme.accent : theme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.text,
                              style: TextStyle(
                                color: t.done ? theme.textMuted : theme.text,
                                fontSize: 13,
                                decoration: t.done ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Expand/collapse
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Show less' : 'View all ${goal.totalDays} days',
                        style: TextStyle(color: theme.accent, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down, color: theme.accent, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
