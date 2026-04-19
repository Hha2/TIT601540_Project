import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/app_usage.dart';

class AppUsageDetailScreen extends StatelessWidget {
  final List<AppUsageEntry> usage;

  const AppUsageDetailScreen({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    final totalMin = usage.fold<int>(0, (acc, a) => acc + a.minutes);
    final totalStr = totalMin < 60
        ? '${totalMin}m'
        : '${totalMin ~/ 60}h ${totalMin % 60}m';

    // Group by category
    final categoryMap = <String, CategoryUsage>{};
    for (final entry in usage) {
      final existing = categoryMap[entry.category];
      if (existing == null) {
        categoryMap[entry.category] = CategoryUsage(
          category: entry.category,
          totalMinutes: entry.minutes,
          apps: [entry],
        );
      } else {
        categoryMap[entry.category] = CategoryUsage(
          category: entry.category,
          totalMinutes: existing.totalMinutes + entry.minutes,
          apps: [...existing.apps, entry],
        );
      }
    }

    final categories = categoryMap.values.toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

    final sortedApps = List<AppUsageEntry>.from(usage)
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    final maxMin = sortedApps.isEmpty ? 1 : sortedApps.first.minutes;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: theme.headerGradient),
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Usage',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Total: $totalStr',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              titlePadding: const EdgeInsets.fromLTRB(48, 0, 0, 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: theme.gradientHeader[0],
            expandedHeight: 120,
          ),

          // By Category
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'BY CATEGORY',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = categories[index];
                final ratio = totalMin > 0 ? cat.totalMinutes / totalMin : 0.0;
                final isOverLimit = cat.category == 'Social' && cat.totalMinutes > 90;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOverLimit
                            ? theme.warning.withValues(alpha: 0.5)
                            : theme.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(cat.categoryIcon,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.category,
                                    style: TextStyle(
                                        color: theme.text,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    cat.formattedTime,
                                    style: TextStyle(
                                        color: theme.textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(ratio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: theme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: theme.border,
                            valueColor: AlwaysStoppedAnimation(
                              isOverLimit ? theme.warning : theme.accent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        if (isOverLimit) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: theme.warning, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Over 90 min limit by ${cat.totalMinutes - 90}m',
                                  style: TextStyle(
                                      color: theme.warning, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: categories.length,
            ),
          ),

          // AI insight
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      const Text('✦',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Insight',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      _buildInsight(categories),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Per App
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'PER APP',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = sortedApps[index];
                final ratio = maxMin > 0 ? app.minutes / maxMin : 0.0;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      children: [
                        Text(app.categoryIcon,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.appName,
                                style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  backgroundColor: theme.border,
                                  valueColor:
                                      AlwaysStoppedAnimation(theme.accent),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          app.formattedTime,
                          style:
                              TextStyle(color: theme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: sortedApps.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  String _buildInsight(List<CategoryUsage> cats) {
    if (cats.isEmpty) return 'No usage data recorded today.';
    final top = cats.first;
    if (top.category == 'Social' && top.totalMinutes > 90) {
      return 'Your social media usage is higher than recommended today. Consider setting a limit to protect your focus time.';
    }
    if (top.category == 'Productivity') {
      return 'Great job! Most of your screen time is on productive apps. Keep this momentum going!';
    }
    return 'You spent most time on ${top.category} apps today (${top.formattedTime}). Balance with productive activities for best results.';
  }
}
