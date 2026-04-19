import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/openrouter_service.dart' as ai;
import '../new_goal_screen.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _typing = false;
  bool _isGoalFlow = false;
  int _goalStep = 0;
  String _goalName = '';
  int _goalDays = 30;
  String _goalCategory = 'Learning';
  final Set<String> _selected = {};
  bool _selectMode = false;
  FirestoreService? _svc;

  // Conversation history for AI (role/content pairs)
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    _svc = FirestoreService(uid);

    // Listen to stored chat messages
    _svc!.chatStream().listen((msgs) {
      if (mounted) setState(() => _messages = msgs);
      _scrollToBottom();
    });

    // Send welcome message if empty
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_messages.isEmpty && mounted) {
        _sendAiMessage(
          "Hey! I'm your Persist AI Coach 👋 I'm here to help you stay consistent with your goals. How are you feeling today? You can also say 'create a goal' and I'll help you set one up!",
          showLabel: true,
        );
      }
    });
  }

  Future<void> _sendAiMessage(String text, {bool showLabel = false}) async {
    await _svc?.saveChat(false, text, showLabel: showLabel);
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    await _svc?.saveChat(true, text);
    _history.add({'role': 'user', 'content': text});

    // Handle goal creation flow
    if (_isGoalFlow) {
      await _handleGoalFlow(text);
      return;
    }

    // Check if user wants to create a goal
    final lower = text.toLowerCase();
    if (lower.contains('create') && lower.contains('goal') ||
        lower.contains('new goal') ||
        lower.contains('set a goal')) {
      _isGoalFlow = true;
      _goalStep = 1;
      await _sendAiMessage(
          "Great! Let's create a new goal. 🎯\n\nStep 1/3: What's the name of your goal?");
      return;
    }

    // Regular AI chat
    setState(() => _typing = true);
    try {
      final reply = await ai.chatWithAI(_history.takeLast(20).toList());
      _history.add({'role': 'assistant', 'content': reply});
      await _sendAiMessage(reply);
    } finally {
      if (mounted) setState(() => _typing = false);
    }
  }

  Future<void> _handleGoalFlow(String text) async {
    switch (_goalStep) {
      case 1:
        _goalName = text;
        _goalStep = 2;
        await _sendAiMessage(
            "Step 2/3: How many days? (e.g., 7, 21, 30, 50, or 90)");
        break;
      case 2:
        final days = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
        if (days == null || days < 1) {
          await _sendAiMessage("Please enter a valid number of days (e.g., 30)");
          return;
        }
        _goalDays = days;
        _goalStep = 3;
        await _sendAiMessage(
            "Step 3/3: What category?\n• Learning\n• Fitness\n• Mindfulness\n• Career\n• Health\n• Creative");
        break;
      case 3:
        final cat = _parseCategory(text);
        _goalCategory = cat;
        _isGoalFlow = false;
        _goalStep = 0;

        await _sendAiMessage(
            "Perfect! I'll generate a $_goalDays-day plan for '$_goalName' now... ✨");
        setState(() => _typing = true);

        try {
          final plan = await ai.generateGoalPlan(_goalName, _goalDays, _goalCategory);
          if (plan != null && mounted) {
            // Create goal through NewGoalScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewGoalScreen(
                  prefillName: _goalName,
                  prefillDays: _goalDays,
                  prefillCategory: _goalCategory,
                  aiPlan: plan,
                ),
              ),
            );
            await _sendAiMessage(
                "I've pre-filled the goal form with your AI plan! Review it and tap 'Create Goal' to save.");
          } else {
            await _sendAiMessage(
                "I couldn't generate the plan right now. Would you like to create the goal manually instead?");
          }
        } finally {
          if (mounted) setState(() => _typing = false);
        }
        break;
    }
  }

  String _parseCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('learn') || lower.contains('study')) return 'Learning';
    if (lower.contains('fit') || lower.contains('gym') || lower.contains('workout')) return 'Fitness';
    if (lower.contains('mind') || lower.contains('meditat')) return 'Mindfulness';
    if (lower.contains('career') || lower.contains('work') || lower.contains('job')) return 'Career';
    if (lower.contains('health') || lower.contains('diet') || lower.contains('nutrition')) return 'Health';
    if (lower.contains('creat') || lower.contains('art') || lower.contains('music')) return 'Creative';
    return 'Learning';
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _selectMode = _selected.isNotEmpty;
    });
  }

  Future<void> _deleteSelected() async {
    for (final id in _selected) {
      await _svc?.deleteChat(id);
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        title: _selectMode
            ? Text(
                '${_selected.length} selected',
                style: TextStyle(color: theme.text),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reflect',
                    style: TextStyle(
                        color: theme.text, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Daily check-in',
                    style:
                        TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                ],
              ),
        actions: _selectMode
            ? [
                TextButton(
                  onPressed: _deleteSelected,
                  child: Text('Delete', style: TextStyle(color: theme.danger)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selected.clear();
                    _selectMode = false;
                  }),
                  child: Text('Cancel',
                      style: TextStyle(color: theme.textMuted)),
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.info_outline, color: theme.textMuted),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: theme.card,
                        title: Text('Tips', style: TextStyle(color: theme.text)),
                        content: Text(
                          'Talk to your AI coach about your goals, progress, or how you\'re feeling. Say "create a goal" to start the goal creation flow.\n\nLong-press any message to select and delete it.',
                          style: TextStyle(color: theme.textMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Got it', style: TextStyle(color: theme.accent)),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          // Goal flow indicator
          if (_isGoalFlow)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎯', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    'Creating goal — step $_goalStep/3',
                    style: TextStyle(color: theme.accent, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (_typing && index == _messages.length) {
                  return _TypingIndicator(theme: theme);
                }
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool? ?? false;
                final text = msg['text'] as String? ?? '';
                final id = msg['id'] as String? ?? '';
                final selected = _selected.contains(id);

                return GestureDetector(
                  onLongPress: () => _toggleSelect(id),
                  onTap: _selectMode ? () => _toggleSelect(id) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: selected
                        ? theme.accent.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isUser) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.accent,
                              child: const Text('✦',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isUser &&
                                    (msg['showLabel'] as bool? ?? false))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'PERSIST AI',
                                      style: TextStyle(
                                          color: theme.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: isUser
                                        ? theme.linearGradient
                                        : null,
                                    color: isUser ? null : theme.card,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: isUser
                                          ? const Radius.circular(16)
                                          : Radius.zero,
                                      bottomRight: isUser
                                          ? Radius.zero
                                          : const Radius.circular(16),
                                    ),
                                    border: isUser
                                        ? null
                                        : Border.all(color: theme.border),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : theme.text,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(Icons.check_circle,
                                        size: 16, color: theme.accent),
                                  ),
                              ],
                            ),
                          ),
                          if (isUser) const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            decoration: BoxDecoration(
              color: theme.card,
              border: Border(top: BorderSide(color: theme.border)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(color: theme.text),
                    decoration: InputDecoration(
                      hintText: 'Message your AI coach...',
                      hintStyle: TextStyle(color: theme.textMuted),
                      filled: true,
                      fillColor: theme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: theme.linearGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final dynamic theme;
  const _TypingIndicator({required this.theme});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.accent,
          child: const Text('✦',
              style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
          ),
          child: FadeTransition(
            opacity: _anim,
            child: Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: theme.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    return list.length <= n ? list : list.sublist(list.length - n);
  }
}
