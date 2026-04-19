import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/app_usage.dart';
import '../../widgets/mood_chart.dart';
import '../app_usage_detail_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _skipProb = 0.0;
  double _avgMood = 2.0;
  List<double> _moodTrend = [];
  List<AppUsageEntry> _appUsage = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final svc = FirestoreService(uid);

    final results = await Future.wait([
      svc.calculateSkipProbability(),
      svc.getAvgMoodLast7Days(),
      svc.getMoodsLast7Days(),
      svc.getAppUsageToday(),
    ]);

    final moods = results[2] as dynamic;
    final List<double> trend = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayMoods = (moods as List)
          .where((m) => m.date == dayStr)
          .map((m) => m.mood as int)
          .toList();
      trend.add(
        dayMoods.isEmpty
            ? 2.0
            : dayMoods.reduce((a, b) => a + b) / dayMoods.length,
      );
    }

    if (mounted) {
      setState(() {
        _skipProb = results[0] as double;
        _avgMood = results[1] as double;
        _moodTrend = trend;
        _appUsage = results[3] as List<AppUsageEntry>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final goals = context.watch<GoalsProvider>();
    final taskRate = goals.totalTasksDoneToday /
        (goals.getTodayTasks().length.clamp(1, double.infinity));

    final skipPct = (_skipProb * 100).toStringAsFixed(0);
    final skipColor = _skipProb < 0.3
        ? theme.success
        : _skipProb < 0.6
            ? theme.warning
            : theme.danger;
    final skipEmoji = _skipProb < 0.3 ? '✅' : _skipProb < 0.6 ? '🔶' : '⚠️';
    final skipLabel = _skipProb < 0.3
        ? 'Low Risk'
        : _skipProb < 0.6
            ? 'Moderate Risk'
            : 'High Risk';

    final totalUsageMin =
        _appUsage.fold<int>(0, (acc, a) => acc + a.minutes);
    final totalUsageStr = totalUsageMin < 60
        ? '${totalUsageMin}m'
        : '${totalUsageMin ~/ 60}h ${totalUsageMin % 60}m';

    return Scaffold(
      backgroundColor: theme.background,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.accent))
          : NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: theme.background,
                  title: Text(
                    'Insights',
                    style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: theme.accent,
                    labelColor: theme.accent,
                    unselectedLabelColor: theme.textMuted,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Patterns'),
                      Tab(text: 'App Usage'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [

                  // ── TAB 1: Overview ──────────────────────────────────────
                  RefreshIndicator(
                    onRefresh: _loadData,
                    color: theme.accent,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // AI Skip Probability card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.border),
                            ),
                            child: Column(
                              children: [
                                Text('AI Skip Probability',
                                    style: TextStyle(color: theme.textMuted, fontSize: 13)),
                                const SizedBox(height: 12),
                                Text('$skipPct%',
                                    style: TextStyle(color: skipColor, fontSize: 48, fontWeight: FontWeight.bold)),
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('$skipEmoji  $skipLabel', style: TextStyle(color: skipColor)),
                                ]),
                                const SizedBox(height: 16),
                                Row(children: [
                                  _InsightStat(theme: theme, label: 'Avg Mood', value: _avgMood.toStringAsFixed(1), icon: '😊'),
                                  _InsightStat(theme: theme, label: 'Task Rate', value: '${(taskRate * 100).toStringAsFixed(0)}%', icon: '✅'),
                                  _InsightStat(theme: theme, label: 'Screen Time', value: totalUsageStr, icon: '📱'),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        // Mood trend card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                                Text('Mood Trend (7 days)',
                                    style: TextStyle(color: theme.text, fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 16),
                                SizedBox(height: 120, child: MoodLineChart(data: _moodTrend, theme: theme)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today']
                                      .map((d) => Text(d, style: TextStyle(color: theme.textMuted, fontSize: 10)))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // AI Insight card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: theme.linearGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Text('✦', style: TextStyle(color: Colors.white, fontSize: 18)),
                                  const SizedBox(width: 8),
                                  const Text('AI Weekly Insight',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ]),
                                const SizedBox(height: 12),
                                Text(_buildAiInsight(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── TAB 2: Patterns ──────────────────────────────────────
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                              Text('Distraction Patterns',
                                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 16),
                              ...[
                                ('🌅 Morning', 0.3, 'Low'),
                                ('☀️ Afternoon', 0.75, 'High'),
                                ('🌙 Evening', 0.5, 'Medium'),
                              ].map((row) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(children: [
                                      SizedBox(width: 110,
                                          child: Text(row.$1, style: TextStyle(color: theme.textMuted))),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: row.$2,
                                            backgroundColor: theme.border,
                                            valueColor: AlwaysStoppedAnimation(theme.accent),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(row.$3, style: TextStyle(color: theme.textMuted, fontSize: 12)),
                                    ]),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── TAB 3: App Usage ─────────────────────────────────────
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (_appUsage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => AppUsageDetailScreen(usage: _appUsage))),
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
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text('App Usage Today',
                                        style: TextStyle(color: theme.text, fontWeight: FontWeight.w600, fontSize: 16)),
                                    Icon(Icons.arrow_forward_ios, color: theme.textMuted, size: 14),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('Total: $totalUsageStr',
                                      style: TextStyle(color: theme.textMuted, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  ..._buildUsageBars(theme),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Text('No app usage data for today.',
                                style: TextStyle(color: theme.textMuted)),
                          ),
                        ),
                    ],
                  ),

                ],
              ),
            ),
    );
  }

  String _buildAiInsight() {
    if (_skipProb > 0.6) {
      return 'Your skip probability is high this week. Try breaking tasks into smaller steps and focusing on one goal at a time.';
    } else if (_skipProb > 0.3) {
      return 'You\'re making moderate progress! Consistency is key — aim to complete at least 2 tasks per day.';
    }
    return 'Excellent momentum this week! Your mood and completion rates are both trending up. Keep it going!';
  }

  List<Widget> _buildUsageBars(dynamic theme) {
    final categories = <String, int>{};
    for (final a in _appUsage) {
      categories[a.category] = (categories[a.category] ?? 0) + a.minutes;
    }
    final total = categories.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];

    return categories.entries.take(4).map((e) {
      final ratio = e.value / total;
      final icon = AppUsageEntry.categoryIcons[e.key] ?? '📱';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(icon),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text(e.key,
                  style: TextStyle(color: theme.textMuted, fontSize: 12)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: theme.border,
                  valueColor: AlwaysStoppedAnimation(theme.accent),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${e.value}m',
              style: TextStyle(color: theme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _InsightStat extends StatelessWidget {
  final dynamic theme;
  final String label;
  final String value;
  final String icon;

  const _InsightStat(
      {required this.theme,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                color: theme.text,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          Text(label,
              style: TextStyle(color: theme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
