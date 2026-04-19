import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/theme_provider.dart';
import 'tabs/home_screen.dart';
import 'tabs/goals_screen.dart';
import 'tabs/insights_screen.dart';
import 'tabs/reflect_screen.dart';
import 'tabs/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    GoalsScreen(),
    InsightsScreen(),
    ReflectScreen(),
    SettingsScreen(),
  ];

  final _tabs = const [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _TabItem(icon: Icons.flag_outlined, activeIcon: Icons.flag, label: 'Goals'),
    _TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Insights'),
    _TabItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Reflect'),
    _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final name = profile?.name ?? 'User';
    final email = profile?.email ?? '';
    final initials = profile?.initials ?? '?';
    final photoUrl = auth.user?.photoURL;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: theme.card,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(gradient: theme.linearGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            // Nav items
            ...[
              (Icons.home_outlined,      'Home',     0),
              (Icons.flag_outlined,      'Goals',    1),
              (Icons.bar_chart_outlined, 'Insights', 2),
              (Icons.chat_bubble_outline,'Reflect',  3),
              (Icons.settings_outlined,  'Settings', 4),
            ].map((item) => ListTile(
              leading: Icon(item.$1, color: _currentIndex == item.$3 ? theme.accent : theme.textMuted),
              title: Text(item.$2,
                  style: TextStyle(
                    color: _currentIndex == item.$3 ? theme.accent : theme.text,
                    fontWeight: _currentIndex == item.$3 ? FontWeight.w600 : FontWeight.normal,
                  )),
              selected: _currentIndex == item.$3,
              selectedTileColor: theme.accent.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                setState(() => _currentIndex = item.$3);
                Navigator.pop(context);
              },
            )),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.danger),
              title: Text('Sign Out', style: TextStyle(color: theme.danger)),
              onTap: () {
                Navigator.pop(context);
                context.read<GoalsProvider>().clear();
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.card,
          border: Border(top: BorderSide(color: theme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final active = i == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _currentIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: active
                                ? theme.accent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            active ? tab.activeIcon : tab.icon,
                            color: active ? theme.accent : theme.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? theme.accent : theme.textMuted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: active ? 20 : 0,
                          decoration: BoxDecoration(
                            color: theme.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}
