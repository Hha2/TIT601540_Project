import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;
  String _focus = 'Study';
  int _structure = 3;
  String _struggle = 'Evening';
  String _skip = 'Sometimes';
  int _mood = 2;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('persist_onboarding_done', true);
    await prefs.setString('onboard_focus', _focus);
    await prefs.setInt('onboard_structure', _structure);
    await prefs.setString('onboard_struggle', _struggle);
    await prefs.setString('onboard_skip', _skip);
    await prefs.setInt('onboard_mood', _mood);
    widget.onFinished();
  }

  void _next() {
    if (_index == 5) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  int _score() {
    var score = 62;
    score += (_structure - 3) * 8;
    score += _mood * 3;
    if (_skip == 'Rarely') score += 12;
    if (_skip == 'Often') score -= 12;
    if (_skip == 'Very Often') score -= 22;
    return score.clamp(18, 92);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
              child: Row(
                children: List.generate(6, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= _index ? theme.accent : theme.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Welcome(theme: theme),
                  _Focus(
                    theme: theme,
                    selected: _focus,
                    onPick: (v) => setState(() => _focus = v),
                  ),
                  _Structure(
                    theme: theme,
                    value: _structure,
                    onPick: (v) => setState(() => _structure = v),
                  ),
                  _Struggle(
                    theme: theme,
                    selected: _struggle,
                    onPick: (v) => setState(() => _struggle = v),
                  ),
                  _Consistency(
                    theme: theme,
                    skip: _skip,
                    mood: _mood,
                    onSkip: (v) => setState(() => _skip = v),
                    onMood: (v) => setState(() => _mood = v),
                  ),
                  _Profile(theme: theme, score: _score()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                      ),
                      child: Text('Back', style: TextStyle(color: theme.textMuted)),
                    ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: theme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                      ),
                      child: Text(
                        _index == 5 ? 'Start My Plan' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenShell extends StatelessWidget {
  final dynamic theme;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ScreenShell({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.text,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: theme.textMuted, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  final dynamic theme;

  const _Welcome({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: theme.headerGradient),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/Logo.jpeg',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Center(
              child: Text(
                'Persist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Build steady routines without burnout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Small steps. Honest patterns. Calm recovery when you slip.',
                style: TextStyle(color: Colors.white, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Focus extends StatelessWidget {
  final dynamic theme;
  final String selected;
  final ValueChanged<String> onPick;

  const _Focus({required this.theme, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return _ScreenShell(
      theme: theme,
      title: 'What do you want to improve first?',
      subtitle: 'Pick the area that matters most right now.',
      children: ['Study', 'Health', 'Focus', 'Routine', 'Mindset']
          .map(
            (x) => _Choice(
              theme: theme,
              label: x,
              selected: selected == x,
              icon: _icon(x),
              onTap: () => onPick(x),
            ),
          )
          .toList(),
    );
  }

  IconData _icon(String x) {
    return {
      'Study': Icons.school_rounded,
      'Health': Icons.favorite_rounded,
      'Focus': Icons.track_changes_rounded,
      'Routine': Icons.calendar_month_rounded,
      'Mindset': Icons.psychology_rounded,
    }[x]!;
  }
}

class _Structure extends StatelessWidget {
  final dynamic theme;
  final int value;
  final ValueChanged<int> onPick;

  const _Structure({required this.theme, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final labels = ['Very Unstructured', 'Unstructured', 'Somewhat Structured', 'Structured', 'Very Structured'];
    return _ScreenShell(
      theme: theme,
      title: 'How structured do your days feel?',
      subtitle: 'This sets your starting stability profile.',
      children: List.generate(5, (i) {
        final v = 5 - i;
        return _Choice(
          theme: theme,
          label: '$v  ${labels[v - 1]}',
          selected: value == v,
          icon: Icons.circle_outlined,
          onTap: () => onPick(v),
        );
      }),
    );
  }
}

class _Struggle extends StatelessWidget {
  final dynamic theme;
  final String selected;
  final ValueChanged<String> onPick;

  const _Struggle({required this.theme, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final icons = {
      'Morning': Icons.wb_sunny_rounded,
      'Afternoon': Icons.light_mode_rounded,
      'Evening': Icons.nightlight_round,
      'Weekends': Icons.weekend_rounded,
    };
    return _ScreenShell(
      theme: theme,
      title: 'When do you struggle most?',
      subtitle: 'Persist uses this to make insights less generic.',
      children: ['Morning', 'Afternoon', 'Evening', 'Weekends']
          .map(
            (x) => _Choice(
              theme: theme,
              label: x,
              selected: selected == x,
              icon: icons[x]!,
              onTap: () => onPick(x),
            ),
          )
          .toList(),
    );
  }
}

class _Consistency extends StatelessWidget {
  final dynamic theme;
  final String skip;
  final int mood;
  final ValueChanged<String> onSkip;
  final ValueChanged<int> onMood;

  const _Consistency({
    required this.theme,
    required this.skip,
    required this.mood,
    required this.onSkip,
    required this.onMood,
  });

  @override
  Widget build(BuildContext context) {
    return _ScreenShell(
      theme: theme,
      title: 'How often do you skip planned tasks?',
      subtitle: 'No judgment. This only shapes your recovery plan.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Rarely', 'Sometimes', 'Often', 'Very Often'].map((x) {
            final selected = skip == x;
            return ChoiceChip(
              label: Text(x),
              selected: selected,
              onSelected: (_) => onSkip(x),
              selectedColor: theme.accentSoft,
              labelStyle: TextStyle(
                color: selected ? theme.accent : theme.textMuted,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(color: selected ? theme.accent : theme.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Text(
          'Current energy',
          style: TextStyle(color: theme.text, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (i) {
            final selected = mood == i;
            final labels = ['Low', 'Below', 'Okay', 'Good', 'Great'];
            return Expanded(
              child: GestureDetector(
                onTap: () => onMood(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? theme.accentSoft : theme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? theme.accent : theme.border),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: selected ? theme.accent : theme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Profile extends StatelessWidget {
  final dynamic theme;
  final int score;

  const _Profile({required this.theme, required this.score});

  @override
  Widget build(BuildContext context) {
    return _ScreenShell(
      theme: theme,
      title: 'Your Starting Stability Profile',
      subtitle: 'Based on your answers, Persist starts with a realistic baseline.',
      children: [
        Center(
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: theme.linearGradient,
              boxShadow: [
                BoxShadow(
                  color: theme.accent.withValues(alpha: .22),
                  blurRadius: 34,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Choice(theme: theme, label: 'Build a steady daily routine', selected: false, icon: Icons.track_changes_rounded, onTap: () {}),
        _Choice(theme: theme, label: 'Protect your energy from overload', selected: false, icon: Icons.bolt_rounded, onTap: () {}),
        _Choice(theme: theme, label: 'Recover gently after missed days', selected: false, icon: Icons.favorite_rounded, onTap: () {}),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final dynamic theme;
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _Choice({
    required this.theme,
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? theme.accentSoft : theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? theme.accent : theme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? theme.accent : theme.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.text, fontWeight: FontWeight.w800),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: theme.accent),
          ],
        ),
      ),
    );
  }
}
