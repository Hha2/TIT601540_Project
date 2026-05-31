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

class _ManualDayDraft {
  final TextEditingController titleCtrl;
  final List<TextEditingController> taskCtrls;

  _ManualDayDraft({String? title, List<String>? tasks})
      : titleCtrl = TextEditingController(text: title ?? ''),
        taskCtrls = (tasks == null || tasks.isEmpty ? [''] : tasks)
            .map((t) => TextEditingController(text: t))
            .toList();

  void dispose() {
    titleCtrl.dispose();
    for (final c in taskCtrls) {
      c.dispose();
    }
  }
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final _nameCtrl = TextEditingController();
  String _category = 'Learning';
  int _days = 7;
  String _difficulty = 'Medium';
  bool _loading = false;
  bool _aiLoading = false;
  List<Map<String, dynamic>>? _aiPlan;
  final List<_ManualDayDraft> _manualDays = [];

  bool get _isEditing => widget.goal != null;

  final _categories = [
    'Learning',
    'Fitness',
    'Mindfulness',
    'Career',
    'Health',
    'Creative'
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
      for (final day in widget.goal!.days) {
        _manualDays.add(_ManualDayDraft(
          title: day.title,
          tasks: day.tasks.map((t) => t.text).toList(),
        ));
      }
    } else if (widget.prefillName != null) {
      _nameCtrl.text = widget.prefillName!;
      _days = widget.prefillDays ?? 7;
      _category = widget.prefillCategory ?? 'Learning';
      _aiPlan = widget.aiPlan;
    }

    if (_manualDays.isEmpty) {
      _manualDays.add(_ManualDayDraft(
        title: 'Day 1 — Foundation',
        tasks: ['Start with one focused action'],
      ));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final day in _manualDays) {
      day.dispose();
    }
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

  void _addManualDay() {
    setState(() {
      final dayNum = _manualDays.length + 1;
      _manualDays.add(_ManualDayDraft(
        title: 'Day $dayNum — New Step',
        tasks: [''],
      ));
      _days = _manualDays.length;
      _aiPlan = null;
    });
  }

  void _removeManualDay(int index) {
    if (_manualDays.length <= 1) return;
    setState(() {
      final removed = _manualDays.removeAt(index);
      removed.dispose();
      _days = _manualDays.length;
      _aiPlan = null;
    });
  }

  void _addTaskToDay(int index) {
    setState(() {
      _manualDays[index].taskCtrls.add(TextEditingController());
      _aiPlan = null;
    });
  }

  void _removeTaskFromDay(int dayIndex, int taskIndex) {
    final day = _manualDays[dayIndex];
    if (day.taskCtrls.length <= 1) return;
    setState(() {
      final removed = day.taskCtrls.removeAt(taskIndex);
      removed.dispose();
      _aiPlan = null;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal name.')),
      );
      return;
    }

    final days = _buildDays();
    if (days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one day with one task.')),
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
          'totalDays': days.length,
          'days': days.map((d) => d.toMap()).toList(),
        });
        if (mounted) Navigator.pop(context);
        return;
      }

      final dueDate = DateFormat('MMM d, yyyy')
          .format(DateTime.now().add(Duration(days: days.length)));

      final goal = GoalModel(
        id: '',
        name: name,
        category: _category,
        totalDays: days.length,
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
    if (_aiPlan != null && _aiPlan!.isNotEmpty) {
      return List.generate(_days, (i) {
        final dayNum = i + 1;
        final planDay = i < _aiPlan!.length ? _aiPlan![i] : null;
        final rawTasks = (planDay?['tasks'] as List<dynamic>? ?? [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final tasks = rawTasks.isEmpty ? ['Review and progress'] : rawTasks;

        return DayModel(
          id: 'day_$dayNum',
          dayNum: dayNum,
          title: planDay?['title']?.toString() ?? 'Day $dayNum',
          status: i == 0 ? 'today' : 'upcoming',
          activatedDate: i == 0 ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : null,
          tasks: tasks
              .asMap()
              .entries
              .map((e) => TaskModel(id: 'task_${dayNum}_${e.key}', text: e.value))
              .toList(),
        );
      });
    }

    final validDays = <DayModel>[];
    for (var i = 0; i < _manualDays.length; i++) {
      final draft = _manualDays[i];
      final dayNum = i + 1;
      final title = draft.titleCtrl.text.trim().isEmpty
          ? 'Day $dayNum'
          : draft.titleCtrl.text.trim();
      final tasks = draft.taskCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (tasks.isEmpty) continue;

      validDays.add(DayModel(
        id: 'day_${validDays.length + 1}',
        dayNum: validDays.length + 1,
        title: title,
        status: validDays.isEmpty ? 'today' : 'upcoming',
        activatedDate: validDays.isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : null,
        tasks: tasks
            .asMap()
            .entries
            .map((e) => TaskModel(
                  id: 'task_${validDays.length + 1}_${e.key}',
                  text: e.value,
                ))
            .toList(),
      ));
    }
    return validDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
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
                  _Label(theme: theme, text: 'Goal Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: theme.text),
                    decoration: _inputDeco(theme, 'e.g., Learn Flutter'),
                  ),
                  const SizedBox(height: 20),

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

                  if (!_isEditing) ...[
                    _Label(theme: theme, text: 'AI Duration'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _durations.map((d) {
                        final selected = _days == d;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _days = d;
                            _aiPlan = null;
                          }),
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

                    _aiBuilderCard(theme),
                    const SizedBox(height: 20),
                  ],

                  _manualBuilderCard(theme),
                  const SizedBox(height: 32),

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

  Widget _aiBuilderCard(dynamic theme) {
    return Container(
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
            Icon(Icons.auto_awesome_rounded, color: theme.accent, size: 18),
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
            'AI creates headings and tasks for every day.',
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
          if (_aiPlan != null) ...[
            const SizedBox(height: 16),
            Text(
              'Generated Plan Preview:',
              style: TextStyle(color: theme.textMuted, fontSize: 13),
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
                          borderRadius: BorderRadius.circular(6),
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
                          style: TextStyle(color: theme.text, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _manualBuilderCard(dynamic theme) {
    return Container(
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
                'Manual Plan',
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton.icon(
                onPressed: _addManualDay,
                icon: Icon(Icons.add, color: theme.accent, size: 18),
                label: Text('Add Day', style: TextStyle(color: theme.accent)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Each day needs a subheading and any number of tasks.',
            style: TextStyle(color: theme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ..._manualDays.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final day = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Day ${dayIndex + 1}',
                        style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_manualDays.length > 1)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _removeManualDay(dayIndex),
                          icon: Icon(Icons.delete_outline,
                              color: theme.textMuted, size: 18),
                        ),
                    ],
                  ),
                  TextField(
                    controller: day.titleCtrl,
                    style: TextStyle(color: theme.text, fontSize: 14),
                    decoration: _inputDeco(theme, 'Subheading e.g., Setup basics'),
                    onChanged: (_) => _aiPlan = null,
                  ),
                  const SizedBox(height: 10),
                  ...day.taskCtrls.asMap().entries.map((taskEntry) {
                    final taskIndex = taskEntry.key;
                    final ctrl = taskEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${taskIndex + 1}.',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              style:
                                  TextStyle(color: theme.text, fontSize: 14),
                              decoration: _inputDeco(
                                  theme, 'Task ${taskIndex + 1}'),
                              onChanged: (_) => _aiPlan = null,
                            ),
                          ),
                          if (day.taskCtrls.length > 1)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  _removeTaskFromDay(dayIndex, taskIndex),
                              icon: Icon(Icons.close,
                                  size: 18, color: theme.textMuted),
                            ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addTaskToDay(dayIndex),
                      icon: Icon(Icons.add_task_rounded,
                          size: 18, color: theme.accent),
                      label: Text('Add Task',
                          style: TextStyle(color: theme.accent)),
                    ),
                  ),
                ],
              ),
            );
          }),
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
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
