import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/goals_provider.dart';
import '../providers/theme_provider.dart';
import '../models/goal.dart';
import '../services/openrouter_service.dart' as ai;

class NewGoalScreen extends StatefulWidget {
  final GoalModel? goal;
  final String? prefillName;
  final int? prefillDays;
  final String? prefillCategory;
  final List<Map<String, dynamic>>? aiPlan;

  const NewGoalScreen({
    super.key,
    this.goal,
    this.prefillName,
    this.prefillDays,
    this.prefillCategory,
    this.aiPlan,
  });

  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final _nameCtrl = TextEditingController();
  String _category = 'Learning';
  int _days = 30;
  String _difficulty = 'Medium';
  bool _loading = false;
  bool _aiLoading = false;
  List<Map<String, dynamic>>? _aiPlan;
  final List<String> _milestones = [];
  final _milestoneCtrl = TextEditingController();

  bool get _isEditing => widget.goal != null;

  final _categories = [
    'Learning', 'Fitness', 'Mindfulness', 'Career', 'Health', 'Creative'
  ];
  final _durations = [7, 21, 30, 50, 90];
  final _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.goal!.name;
      _category = widget.goal!.category;
      _days = widget.goal!.totalDays;
    } else if (widget.prefillName != null) {
      _nameCtrl.text = widget.prefillName!;
      _days = widget.prefillDays ?? 30;
      _category = widget.prefillCategory ?? 'Learning';
      _aiPlan = widget.aiPlan;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _milestoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAiPlan() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a goal name first.')),
      );
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final plan = await ai.generateGoalPlan(
        _nameCtrl.text.trim(),
        _days,
        _category,
      );
      if (mounted) {
        setState(() {
          _aiPlan = plan;
          _aiLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal name.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final goalsProvider = context.read<GoalsProvider>();

      if (_isEditing) {
        await goalsProvider.editGoal(widget.goal!.id, {
          'name': name,
          'category': _category,
        });
        if (mounted) Navigator.pop(context);
        return;
      }

      // Build days from AI plan or milestones
      final days = _buildDays();
      final dueDate = DateFormat('MMM d, yyyy')
          .format(DateTime.now().add(Duration(days: _days)));

      final goal = GoalModel(
        id: '',
        name: name,
        category: _category,
        totalDays: _days,
        dueDate: dueDate,
        completedDays: 0,
        streakDays: 0,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        days: days,
      );

      await goalsProvider.addGoal(goal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DayModel> _buildDays() {
    if (_aiPlan != null) {
      return List.generate(_days, (i) {
        final dayNum = i + 1;
        final planDay = i < _aiPlan!.length ? _aiPlan![i] : null;
        final isToday = i == 0;

        final tasks = planDay != null
            ? (planDay['tasks'] as List<dynamic>? ?? [])
                .asMap()
                .entries
                .map((e) => TaskModel(
                      id: 'task_${dayNum}_${e.key}',
                      text: e.value.toString(),
                    ))
                .toList()
            : [
                TaskModel(id: 'task_${dayNum}_0', text: 'Task 1'),
                TaskModel(id: 'task_${dayNum}_1', text: 'Task 2'),
                TaskModel(id: 'task_${dayNum}_2', text: 'Task 3'),
              ];

        return DayModel(
          id: 'day_$dayNum',
          dayNum: dayNum,
          title: planDay?['title']?.toString() ?? 'Day $dayNum',
          status: isToday ? 'today' : 'upcoming',
          tasks: tasks,
        );
      });
    }

    // Build from milestones
    return List.generate(_days, (i) {
      final dayNum = i + 1;
      final milestoneIndex = (i * _milestones.length / _days).floor();
      final milestone = _milestones.isNotEmpty
          ? _milestones[milestoneIndex.clamp(0, _milestones.length - 1)]
          : 'Goal progress';

      return DayModel(
        id: 'day_$dayNum',
        dayNum: dayNum,
        title: 'Day $dayNum — $milestone',
        status: i == 0 ? 'today' : 'upcoming',
        tasks: [
          TaskModel(id: 'task_${dayNum}_0', text: 'Work on: $milestone'),
          TaskModel(id: 'task_${dayNum}_1', text: 'Review progress'),
          TaskModel(id: 'task_${dayNum}_2', text: 'Reflect & plan next step'),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: theme.headerGradient),
              ),
              title: Text(
                _isEditing ? 'Edit Goal' : 'Create New Goal',
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.fromLTRB(48, 0, 0, 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: theme.gradientHeader[0],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal name
                  _Label(theme: theme, text: 'Goal Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: theme.text),
                    decoration: _inputDeco(theme, 'e.g., Learn Spanish'),
                  ),
                  const SizedBox(height: 20),

                  // Category
                  _Label(theme: theme, text: 'Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? theme.accent : theme.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? theme.accent : theme.border,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : theme.textMuted,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Duration (hidden when editing)
                  if (!_isEditing) ...[
                    _Label(theme: theme, text: 'Duration (Days)'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _durations.map((d) {
                        final selected = _days == d;
                        return GestureDetector(
                          onTap: () => setState(() => _days = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? theme.accent : theme.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? theme.accent : theme.border,
                              ),
                            ),
                            child: Text(
                              '$d',
                              style: TextStyle(
                                color: selected ? Colors.white : theme.textMuted,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Difficulty
                    _Label(theme: theme, text: 'Difficulty'),
                    const SizedBox(height: 8),
                    Row(
                      children: _difficulties.map((d) {
                        final selected = _difficulty == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _difficulty = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? theme.accent : theme.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? theme.accent : theme.border,
                                ),
                              ),
                              child: Text(
                                d,
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : theme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // AI Builder card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('✦', style: TextStyle(color: theme.accent)),
                            const SizedBox(width: 8),
                            Text(
                              'AI Build for Me',
                              style: TextStyle(
                                color: theme.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            'Let AI generate a day-by-day plan for your goal.',
                            style: TextStyle(color: theme.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _aiLoading ? null : _generateAiPlan,
                            child: Container(
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: theme.linearGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _aiLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Generate Plan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // AI plan preview
                          if (_aiPlan != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Generated Plan Preview:',
                              style: TextStyle(
                                  color: theme.textMuted, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            ..._aiPlan!.take(5).map((day) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: theme.accentSoft,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${day['dayNum']}',
                                            style: TextStyle(
                                              color: theme.accent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          day['title']?.toString() ?? '',
                                          style: TextStyle(
                                              color: theme.text,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            if (_aiPlan!.length > 5)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '· · ·  ${_aiPlan!.length - 5} more days generated · · ·',
                                  style: TextStyle(
                                      color: theme.textMuted, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Manual milestones
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manual Milestones',
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._milestones.asMap().entries.map((entry) {
                            final colors = [
                              theme.accent,
                              theme.warning,
                              theme.success,
                              theme.danger,
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colors[entry.key % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(color: theme.text),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _milestones.removeAt(entry.key)),
                                    child: Icon(Icons.close,
                                        size: 16, color: theme.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _milestoneCtrl,
                                  style: TextStyle(color: theme.text, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Add milestone...',
                                    hintStyle: TextStyle(color: theme.textFaint),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (text) {
                                    if (text.trim().isEmpty) return;
                                    setState(() {
                                      _milestones.add(text.trim());
                                      _milestoneCtrl.clear();
                                    });
                                  },
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_milestoneCtrl.text.trim().isEmpty) return;
                                  setState(() {
                                    _milestones.add(_milestoneCtrl.text.trim());
                                    _milestoneCtrl.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.accentSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.add,
                                      color: theme.accent, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save button
                  GestureDetector(
                    onTap: _loading ? null : _save,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: theme.linearGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : Text(
                                _isEditing ? 'Save Changes' : 'Create Goal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(dynamic theme, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textFaint),
      filled: true,
      fillColor: theme.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.accent, width: 2),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final dynamic theme;
  final String text;
  const _Label({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: theme.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
