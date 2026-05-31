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
  double _avgMood = 2.0;
  List<double> _moodTrend = [];
  List<AppUsageEntry> _appUsageToday = [];
  List<AppUsageEntry> _appUsage7Days = [];
  List<Map<String, dynamic>> _completionEvents = [];
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

    final avgMood = await svc.getAvgMoodLast7Days();
    final moods = await svc.getMoodsLast7Days();
    final usageToday = await svc.getAppUsageToday();
    final usage7 = await svc.getAppUsageLast7Days();
    final events = await svc.getTaskCompletionEventsLast7Days();

    final trend = <double>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayMoods = moods.where((m) => m.date == dayStr).map((m) => m.mood).toList();
      trend.add(dayMoods.isEmpty ? 2.0 : dayMoods.reduce((a, b) => a + b) / dayMoods.length);
    }

    if (!mounted) return;
    setState(() {
      _avgMood = avgMood;
      _moodTrend = trend;
      _appUsageToday = usageToday;
      _appUsage7Days = usage7;
      _completionEvents = events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final goals = context.watch<GoalsProvider>();
    final taskRate = goals.overallCompletionRate;
    final skipProb = _calculateSkipProbability(goals);
    final skipPct = (skipProb * 100).toStringAsFixed(0);
    final skipColor = skipProb < 0.3 ? theme.success : skipProb < 0.6 ? theme.warning : theme.danger;
    final skipLabel = skipProb < 0.3 ? 'Low Risk' : skipProb < 0.6 ? 'Moderate Risk' : 'High Risk';
    final usageTodayStr = _formatMinutes(_appUsageToday.fold<int>(0, (a, b) => a + b.minutes));
    final biggestDistraction = _biggestDistraction();
    final productiveTime = _mostProductiveTime();

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
                  title: Text('Insights', style: TextStyle(color: theme.text, fontWeight: FontWeight.bold)),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: theme.accent,
                    labelColor: theme.accent,
                    unselectedLabelColor: theme.textMuted,
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
                  RefreshIndicator(
                    onRefresh: _loadData,
                    color: theme.accent,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _Card(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Title(theme: theme, text: 'Goal Performance'),
                              const SizedBox(height: 16),
                              Row(children: [
                                _InsightStat(theme: theme, label: 'Best Streak', value: '${goals.bestStreak}', icon: Icons.local_fire_department_rounded),
                                _InsightStat(theme: theme, label: 'Avg Comp', value: '${(taskRate * 100).toStringAsFixed(0)}%', icon: Icons.analytics_rounded),
                                _InsightStat(theme: theme, label: 'Tasks Done', value: '${goals.totalCompletedTasks}/${goals.totalPlannedTasks}', icon: Icons.check_circle_rounded),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                _InsightStat(theme: theme, label: 'Done Goals', value: '${goals.completedGoals}/${goals.totalGoals}', icon: Icons.flag_rounded),
                                _InsightStat(theme: theme, label: 'Active', value: '${goals.activeGoalCount}', icon: Icons.flash_on_rounded),
                                _InsightStat(theme: theme, label: 'Open Today', value: '${goals.getTodayTasks().length}', icon: Icons.today_rounded),
                              ]),
                            ],
                          ),
                        ),
                        _Card(
                          theme: theme,
                          child: Column(
                            children: [
                              Text('AI Skip Probability', style: TextStyle(color: theme.textMuted, fontSize: 13)),
                              const SizedBox(height: 10),
                              Text('$skipPct%', style: TextStyle(color: skipColor, fontSize: 48, fontWeight: FontWeight.bold)),
                              Text(skipLabel, style: TextStyle(color: skipColor, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 16),
                              Row(children: [
                                _InsightStat(theme: theme, label: 'Avg Mood', value: _avgMood.toStringAsFixed(1), icon: Icons.mood_rounded),
                                _InsightStat(theme: theme, label: 'Task Rate', value: '${(taskRate * 100).toStringAsFixed(0)}%', icon: Icons.task_alt_rounded),
                                _InsightStat(theme: theme, label: 'Screen Time', value: usageTodayStr, icon: Icons.phone_android_rounded),
                              ]),
                            ],
                          ),
                        ),
                        _Card(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Title(theme: theme, text: 'Mood Trend (7 days)'),
                              const SizedBox(height: 16),
                              SizedBox(height: 120, child: MoodLineChart(data: _moodTrend, theme: theme)),
                            ],
                          ),
                        ),
                        _Card(
                          theme: theme,
                          gradient: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Smart Weekly Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ]),
                              const SizedBox(height: 12),
                              Text(
                                _buildSmartInsight(skipProb, productiveTime, biggestDistraction),
                                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadData,
                    color: theme.accent,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _Card(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Title(theme: theme, text: 'Real Completion Pattern'),
                              const SizedBox(height: 6),
                              Text('Based on actual task-completion timestamps from the last 7 days.', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                              const SizedBox(height: 16),
                              ..._buildCompletionPatternBars(theme),
                            ],
                          ),
                        ),
                        _Card(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Title(theme: theme, text: 'Biggest Distraction'),
                              const SizedBox(height: 12),
                              if (biggestDistraction == null)
                                Text('No app-usage data yet. Add usage logs before presenting this feature as real screen-time tracking.', style: TextStyle(color: theme.textMuted))
                              else
                                Row(children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: theme.accentSoft, borderRadius: BorderRadius.circular(14)),
                                    child: Icon(Icons.warning_amber_rounded, color: theme.warning),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(biggestDistraction.appName, style: TextStyle(color: theme.text, fontWeight: FontWeight.w800, fontSize: 16)),
                                      Text('${biggestDistraction.category} • ${_formatMinutes(biggestDistraction.minutes)} in last 7 days', style: TextStyle(color: theme.textMuted, fontSize: 12)),
                                    ]),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (_appUsageToday.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppUsageDetailScreen(usage: _appUsageToday))),
                          child: _Card(
                            theme: theme,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  _Title(theme: theme, text: 'App Usage Today'),
                                  Icon(Icons.arrow_forward_ios, color: theme.textMuted, size: 14),
                                ]),
                                const SizedBox(height: 4),
                                Text('Total: $usageTodayStr', style: TextStyle(color: theme.textMuted, fontSize: 13)),
                                const SizedBox(height: 12),
                                ..._buildUsageBars(theme, _appUsageToday),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(child: Text('No app usage data for today.', style: TextStyle(color: theme.textMuted))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  double _calculateSkipProbability(GoalsProvider goals) {
    final openTasks = goals.getTodayTasks().length;
    final completionRisk = 1 - goals.overallCompletionRate;
    final moodRisk = ((2.8 - _avgMood) / 2.8).clamp(0.0, 1.0);
    final screenMinutes = _appUsageToday.fold<int>(0, (a, b) => a + b.minutes);
    final screenRisk = (screenMinutes / 300).clamp(0.0, 1.0);
    final pressureRisk = (openTasks / 8).clamp(0.0, 1.0);
    final overdueRisk = (goals.totalOverdueDays / 5).clamp(0.0, 1.0);
    final streakProtection = (goals.currentStreak / 14).clamp(0.0, 1.0) * 0.18;
    return ((completionRisk * 0.30) + (overdueRisk * 0.30) + (moodRisk * 0.18) + (screenRisk * 0.12) + (pressureRisk * 0.10) - streakProtection).clamp(0.02, 0.95);
  }

  String _bucketForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'Afternoon';
    if (hour >= 18 && hour < 24) return 'Evening';
    return 'Night';
  }

  String _mostProductiveTime() {
    final counts = {'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
    for (final e in _completionEvents) {
      counts[_bucketForHour(e['hour'] as int)] = counts[_bucketForHour(e['hour'] as int)]! + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value == 0 ? 'not enough data yet' : sorted.first.key;
  }

  List<Widget> _buildCompletionPatternBars(dynamic theme) {
    final counts = {'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
    for (final e in _completionEvents) {
      final bucket = _bucketForHour(e['hour'] as int);
      counts[bucket] = counts[bucket]! + 1;
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return [Text('No completion timestamps yet. Complete a few tasks to generate real patterns.', style: TextStyle(color: theme.textMuted))];
    }
    final icons = {'Morning': Icons.wb_sunny_rounded, 'Afternoon': Icons.light_mode_rounded, 'Evening': Icons.nights_stay_rounded, 'Night': Icons.bedtime_rounded};
    return counts.entries.map((e) {
      final ratio = e.value / maxCount;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          SizedBox(width: 118, child: Row(children: [
            Icon(icons[e.key], color: theme.accent, size: 18),
            const SizedBox(width: 8),
            Text(e.key, style: TextStyle(color: theme.textMuted, fontSize: 12)),
          ])),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: ratio, backgroundColor: theme.border, valueColor: AlwaysStoppedAnimation(theme.accent), minHeight: 8))),
          const SizedBox(width: 10),
          Text('${e.value}', style: TextStyle(color: theme.text, fontWeight: FontWeight.w700)),
        ]),
      );
    }).toList();
  }

  AppUsageEntry? _biggestDistraction() {
    if (_appUsage7Days.isEmpty) return null;
    final byApp = <String, AppUsageEntry>{};
    for (final e in _appUsage7Days) {
      final current = byApp[e.appName];
      if (current == null) {
        byApp[e.appName] = e;
      } else {
        byApp[e.appName] = AppUsageEntry(
          id: current.id,
          appName: current.appName,
          category: current.category,
          minutes: current.minutes + e.minutes,
          date: current.date,
          timestamp: current.timestamp,
        );
      }
    }
    final sorted = byApp.values.toList()..sort((a, b) => b.minutes.compareTo(a.minutes));
    return sorted.first;
  }

  String _buildSmartInsight(double skipProb, String productiveTime, AppUsageEntry? distraction) {
    final distractionText = distraction == null ? 'No major distraction app is visible yet.' : '${distraction.appName} is your biggest logged distraction.';
    final overdueText = context.read<GoalsProvider>().totalOverdueDays > 0 ? 'You also have overdue goal pressure, so clear the oldest active day first.' : '';
    if (skipProb > 0.6) {
      return 'Risk is high. Your best completion window is $productiveTime. $distractionText Reduce today’s task load and finish one easy task first. $overdueText';
    }
    if (skipProb > 0.3) {
      return 'Risk is moderate. Your strongest pattern is $productiveTime. $distractionText Keep tasks short and avoid context switching. $overdueText';
    }
    return 'Momentum is good. Your best completion window is $productiveTime. $distractionText Keep the same routine and protect your streak.';
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  List<Widget> _buildUsageBars(dynamic theme, List<AppUsageEntry> usage) {
    final categories = <String, int>{};
    for (final a in usage) {
      categories[a.category] = (categories[a.category] ?? 0) + a.minutes;
    }
    final total = categories.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];
    final entries = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(4).map((e) {
      final ratio = e.value / total;
      final icon = AppUsageEntry.categoryIcons[e.key] ?? '📱';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(icon),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(e.key, style: TextStyle(color: theme.textMuted, fontSize: 12))),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: ratio, backgroundColor: theme.border, valueColor: AlwaysStoppedAnimation(theme.accent), minHeight: 6))),
          const SizedBox(width: 8),
          Text(_formatMinutes(e.value), style: TextStyle(color: theme.textMuted, fontSize: 12)),
        ]),
      );
    }).toList();
  }
}

class _Card extends StatelessWidget {
  final dynamic theme;
  final Widget child;
  final bool gradient;
  const _Card({required this.theme, required this.child, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: gradient ? null : theme.card,
          gradient: gradient ? theme.linearGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: gradient ? null : Border.all(color: theme.border),
        ),
        child: child,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final dynamic theme;
  final String text;
  const _Title({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: theme.text, fontWeight: FontWeight.w700, fontSize: 16));
  }
}

class _InsightStat extends StatelessWidget {
  final dynamic theme;
  final String label;
  final String value;
  final IconData icon;

  const _InsightStat({required this.theme, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: theme.accent, size: 21),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 11)),
      ]),
    );
  }
}
