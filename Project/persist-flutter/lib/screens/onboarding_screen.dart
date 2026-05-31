import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/persist_brand.dart';
import '../providers/theme_provider.dart';
import 'auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  String? _focus;
  int? _structure;
  String? _struggle;
  String? _skip;
  int? _mood;

  static const int _totalPages = 5;

  bool get _isResult => _page == _totalPages - 1;

  bool get _canContinue {
    switch (_page) {
      case 0:
        return _focus != null;
      case 1:
        return _structure != null;
      case 2:
        return _struggle != null;
      case 3:
        return _skip != null && _mood != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  int _score() {
    var score = 62;
    final structure = _structure ?? 3;
    final mood = _mood ?? 2;
    score += (structure - 3) * 8;
    score += (mood - 2) * 5;
    switch (_skip) {
      case 'Rarely':
        score += 12;
        break;
      case 'Sometimes':
        score += 2;
        break;
      case 'Often':
        score -= 12;
        break;
      case 'Very Often':
        score -= 22;
        break;
    }
    return score.clamp(18, 94);
  }

  void _next() {
    if (!_canContinue) return;
    if (_isResult) {
      _finishToSignup();
      return;
    }
    setState(() => _page++);
  }

  void _back() {
    if (_page == 0) {
      Navigator.maybePop(context);
    } else {
      setState(() => _page--);
    }
  }

  Future<void> _finishToSignup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('persist_onboarding_done', true);
    await prefs.setString('onboard_focus', _focus ?? 'General');
    await prefs.setInt('onboard_structure', _structure ?? 3);
    await prefs.setString('onboard_struggle', _struggle ?? 'Evening');
    await prefs.setString('onboard_skip', _skip ?? 'Sometimes');
    await prefs.setInt('onboard_mood', _mood ?? 2);
    await prefs.setInt('onboard_stability_score', _score());

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignupScreen(fromOnboarding: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = context.watch<ThemeProvider>().theme;
    final bool darkResult = _isResult;
    final background = darkResult ? PersistBrand.coreDarkBackground : baseTheme.background;
    final navBrightness = darkResult ? Brightness.light : Brightness.dark;
    final buttonText = _isResult ? 'Create My Account' : 'Continue';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: navBrightness,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: navBrightness,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: KeyedSubtree(
                key: ValueKey(_page),
                child: _buildPage(baseTheme),
              ),
            ),
            _TopProgress(
              page: _page,
              total: _totalPages,
              onBack: _back,
              dark: darkResult,
              accent: darkResult ? PersistBrand.coreDarkPrimary : baseTheme.accent,
              border: darkResult ? Colors.white.withOpacity(.22) : baseTheme.border,
              textColor: darkResult ? Colors.white : baseTheme.text,
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              child: SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: _canContinue ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkResult ? PersistBrand.coreDarkPrimary : baseTheme.accent,
                    disabledBackgroundColor: darkResult ? Colors.white.withOpacity(.16) : baseTheme.border,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: darkResult ? Colors.white.withOpacity(.48) : baseTheme.textFaint,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(dynamic theme) {
    switch (_page) {
      case 0:
        return _GoalFocusPage(theme: theme, selected: _focus, onPick: (v) => setState(() => _focus = v));
      case 1:
        return _StructurePage(theme: theme, selected: _structure, onPick: (v) => setState(() => _structure = v));
      case 2:
        return _StrugglePage(theme: theme, selected: _struggle, onPick: (v) => setState(() => _struggle = v));
      case 3:
        return _ConsistencyMoodPage(
          theme: theme,
          skip: _skip,
          mood: _mood,
          onSkip: (v) => setState(() => _skip = v),
          onMood: (v) => setState(() => _mood = v),
        );
      case 4:
      default:
        return _ProfilePage(score: _score());
    }
  }
}

class _TopProgress extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onBack;
  final bool dark;
  final Color accent;
  final Color border;
  final Color textColor;

  const _TopProgress({
    required this.page,
    required this.total,
    required this.onBack,
    required this.dark,
    required this.accent,
    required this.border,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 22, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: (page + 1) / total,
                  backgroundColor: border,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageShell extends StatelessWidget {
  final dynamic theme;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _PageShell({required this.theme, required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 92, 24, 112),
        children: [
          Text(title, style: TextStyle(color: theme.text, fontSize: 26, fontWeight: FontWeight.w900, height: 1.13)),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(color: theme.textMuted, fontSize: 14, height: 1.45, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _GoalFocusPage extends StatelessWidget {
  final dynamic theme;
  final String? selected;
  final ValueChanged<String> onPick;

  const _GoalFocusPage({required this.theme, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Study', 'Build better learning habits', Icons.school_rounded),
      ('Health', 'Feel stronger and healthier', Icons.favorite_rounded),
      ('Focus', 'Reduce distractions and stay present', Icons.track_changes_rounded),
      ('Routine', 'Create structure that sticks', Icons.event_available_rounded),
      ('Mindset', 'Build emotional stability and confidence', Icons.spa_rounded),
    ];
    return _PageShell(
      theme: theme,
      title: 'What do you want to improve first?',
      subtitle: 'Pick the area that matters most to you right now.',
      children: data.map((item) => _ChoiceCard(
        theme: theme,
        title: item.$1,
        subtitle: item.$2,
        icon: item.$3,
        selected: selected == item.$1,
        onTap: () => onPick(item.$1),
      )).toList(),
    );
  }
}

class _StructurePage extends StatelessWidget {
  final dynamic theme;
  final int? selected;
  final ValueChanged<int> onPick;

  const _StructurePage({required this.theme, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final data = [
      (5, 'Very Structured', 'I have a clear routine and it works well.'),
      (4, 'Structured', 'I follow a routine most of the time.'),
      (3, 'Somewhat Structured', 'I have a routine, but it does not always hold.'),
      (2, 'Unstructured', 'My days feel random and inconsistent.'),
      (1, 'Very Unstructured', 'I have no real routine right now.'),
    ];
    return _PageShell(
      theme: theme,
      title: 'How structured do your days feel right now?',
      subtitle: 'This helps us tailor the right level of structure for you.',
      children: data.map((item) => _NumberChoice(
        theme: theme,
        number: item.$1,
        title: item.$2,
        subtitle: item.$3,
        selected: selected == item.$1,
        onTap: () => onPick(item.$1),
      )).toList(),
    );
  }
}

class _StrugglePage extends StatelessWidget {
  final dynamic theme;
  final String? selected;
  final ValueChanged<String> onPick;

  const _StrugglePage({required this.theme, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Morning', 'Getting started is hard', Icons.wb_sunny_rounded),
      ('Afternoon', 'Energy dips mid-day', Icons.light_mode_rounded),
      ('Evening', 'Hard to stay on track', Icons.nightlight_round),
      ('Weekends', 'My routine falls apart', Icons.weekend_rounded),
    ];
    return _PageShell(
      theme: theme,
      title: 'When do you struggle most?',
      subtitle: 'There is no right or wrong answer. This helps personalize your insights.',
      children: [
        ...data.map((item) => _ChoiceCard(
          theme: theme,
          title: item.$1,
          subtitle: item.$2,
          icon: item.$3,
          selected: selected == item.$1,
          onTap: () => onPick(item.$1),
        )),
        const SizedBox(height: 10),
        _SoftHint(theme: theme, text: 'Your pattern can change later. Persist adapts as you use it.'),
      ],
    );
  }
}

class _ConsistencyMoodPage extends StatelessWidget {
  final dynamic theme;
  final String? skip;
  final int? mood;
  final ValueChanged<String> onSkip;
  final ValueChanged<int> onMood;

  const _ConsistencyMoodPage({required this.theme, required this.skip, required this.mood, required this.onSkip, required this.onMood});

  @override
  Widget build(BuildContext context) {
    final skipData = [
      ('Rarely', 'Almost never'),
      ('Sometimes', 'A few times a week'),
      ('Often', 'Several times a week'),
      ('Very Often', 'Almost daily'),
    ];
    final moods = [
      (0, 'Low', Icons.sentiment_very_dissatisfied_rounded),
      (1, 'Below', Icons.sentiment_dissatisfied_rounded),
      (2, 'Okay', Icons.sentiment_neutral_rounded),
      (3, 'Good', Icons.sentiment_satisfied_alt_rounded),
      (4, 'Great', Icons.sentiment_very_satisfied_rounded),
    ];

    return _PageShell(
      theme: theme,
      title: 'How often do you skip what you planned?',
      subtitle: 'Be honest. This helps us support you without judgment.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skipData.map((item) => SizedBox(
                width: (constraints.maxWidth - 8) / 2,
                child: _MiniChoice(
                  theme: theme,
                  title: item.$1,
                  subtitle: item.$2,
                  selected: skip == item.$1,
                  onTap: () => onSkip(item.$1),
                ),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        Text('How would you describe your current energy or mood?', style: TextStyle(color: theme.text, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('This helps personalize your experience from day one.', style: TextStyle(color: theme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(
          children: moods.map((item) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _MoodChoice(
                theme: theme,
                label: item.$2,
                icon: item.$3,
                selected: mood == item.$1,
                onTap: () => onMood(item.$1),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final int score;

  const _ProfilePage({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [PersistBrand.coreDarkBackground, PersistBrand.coreDarkSurface, PersistBrand.coreDarkPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 92, 24, 112),
          children: [
            const Text('Your Starting\nStability Profile', style: TextStyle(color: Colors.white, fontSize: 28, height: 1.12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Based on your answers', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 26),
            Center(child: _ScoreRing(score: score)),
            const SizedBox(height: 28),
            const Text('You are building momentum.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('With the right structure and support, you can create lasting stability.', style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 22),
            const _ProfileAdvice(icon: Icons.track_changes_rounded, title: 'Build a steady daily routine', subtitle: 'Small consistent actions create change.'),
            const _ProfileAdvice(icon: Icons.bolt_rounded, title: 'Protect your energy', subtitle: 'Manage dips and reduce overwhelm.'),
            const _ProfileAdvice(icon: Icons.favorite_rounded, title: 'Strengthen your mindset', subtitle: 'Reflect, reset, and grow with self-compassion.'),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;

  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 16,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withOpacity(.24),
              valueColor: const AlwaysStoppedAnimation<Color>(PersistBrand.coreDarkAccent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Behavior Stability\nScore', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, height: 1.25, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final dynamic theme;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({required this.theme, required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? theme.accentSoft : theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? theme.accent : theme.border, width: selected ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(selected ? .07 : .035), blurRadius: 14, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: selected ? theme.accent.withOpacity(.13) : theme.cardAlt, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: selected ? theme.accent : theme.textMuted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.text, fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: theme.textMuted, fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: theme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NumberChoice extends StatelessWidget {
  final dynamic theme;
  final int number;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _NumberChoice({required this.theme, required this.number, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? theme.accentSoft : theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? theme.accent : theme.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? theme.accent : theme.cardAlt, border: Border.all(color: selected ? theme.accent : theme.border)),
              child: Text('$number', style: TextStyle(color: selected ? Colors.white : theme.text, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: theme.textMuted, height: 1.25, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChoice extends StatelessWidget {
  final dynamic theme;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MiniChoice({required this.theme, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? theme.accentSoft : theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? theme.accent : theme.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? theme.accent : theme.textMuted, size: 22),
            const SizedBox(height: 7),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: theme.text, fontSize: 12.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MoodChoice extends StatelessWidget {
  final dynamic theme;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChoice({required this.theme, required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.accentSoft : theme.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? theme.accent : theme.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? theme.accent : theme.textMuted, size: 22),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.text, fontSize: 10.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SoftHint extends StatelessWidget {
  final dynamic theme;
  final String text;

  const _SoftHint({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.accentSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.border)),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: theme.textMuted, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ProfileAdvice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileAdvice({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFFE2F3F1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: PersistBrand.coreDarkPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: PersistBrand.coreLightText, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF60737B), fontWeight: FontWeight.w600, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
