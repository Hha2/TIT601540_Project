import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/themes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminders = true;
  bool _goalNudges = true;
  bool _weeklySummary = false;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() => _localImage = File(path));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', picked.path);
    setState(() => _localImage = File(picked.path));
  }

  void _showUploadDialog() {
    final theme = context.read<ThemeProvider>().theme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Profile Photo', style: TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: theme.accent),
              title: Text('Upload from Gallery', style: TextStyle(color: theme.text)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            if (_localImage != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.danger),
                title: Text('Remove Photo', style: TextStyle(color: theme.danger)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profile_image_path');
                  setState(() => _localImage = null);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut() {
    final theme = context.read<ThemeProvider>().theme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.card,
        title: Text('Sign Out?', style: TextStyle(color: theme.text)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: theme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              context.read<GoalsProvider>().clear();
              await context.read<AuthProvider>().logout();
            },
            child: Text('Sign Out', style: TextStyle(color: theme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final profile = auth.profile;
    final name = profile?.name ?? 'User';
    final email = profile?.email ?? '';
    final initials = profile?.initials ?? '?';
    final photoUrl = auth.user?.photoURL;

    return Scaffold(
      backgroundColor: theme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: theme.background,
            title: Text(
              'Settings',
              style: TextStyle(color: theme.text, fontWeight: FontWeight.bold),
            ),
          ),

          // Profile card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: theme.linearGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showUploadDialog,
                      onLongPress: _showUploadDialog,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            backgroundImage: _localImage != null
                                ? FileImage(_localImage!) as ImageProvider
                                : (photoUrl != null ? NetworkImage(photoUrl) : null),
                            child: (_localImage == null && photoUrl == null)
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 11, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'FREE PLAN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: _showUploadDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Premium banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Text('👑', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                                color: theme.text, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Unlock unlimited goals & AI features',
                            style: TextStyle(
                                color: theme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: theme.linearGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Notifications
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Section(
                theme: theme,
                title: 'Notifications',
                children: [
                  _SwitchTile(
                    theme: theme,
                    title: 'Daily Reminders',
                    subtitle: '8:00 AM every day',
                    value: _dailyReminders,
                    onChanged: (v) => setState(() => _dailyReminders = v),
                  ),
                  _SwitchTile(
                    theme: theme,
                    title: 'Goal Nudges',
                    subtitle: 'When you\'re falling behind',
                    value: _goalNudges,
                    onChanged: (v) => setState(() => _goalNudges = v),
                  ),
                  _SwitchTile(
                    theme: theme,
                    title: 'Weekly AI Summary',
                    subtitle: 'Every Sunday evening',
                    value: _weeklySummary,
                    onChanged: (v) => setState(() => _weeklySummary = v),
                  ),
                ],
              ),
            ),
          ),

          // Themes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text('Light',
                        style: TextStyle(color: theme.textMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['emerald', 'rose', 'violet'].map((id) {
                        final t = allThemes[id]!;
                        final selected = themeProvider.themeId == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => themeProvider.setTheme(id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: t.gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? theme.accent
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: t.accent.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Center(
                                      child: Icon(Icons.check,
                                          color: Colors.white, size: 20))
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Dark',
                        style: TextStyle(color: theme.textMuted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['obsidian', 'midnight'].map((id) {
                        final t = allThemes[id]!;
                        final selected = themeProvider.themeId == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => themeProvider.setTheme(id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: t.gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? theme.accent
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: t.accent.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Center(
                                      child: Icon(Icons.check,
                                          color: Colors.white, size: 20))
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Privacy
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Section(
                theme: theme,
                title: 'Privacy & Data',
                children: [
                  _LinkTile(
                    theme: theme,
                    title: 'Data Privacy',
                    icon: Icons.privacy_tip_outlined,
                  ),
                  _LinkTile(
                    theme: theme,
                    title: 'Export My Data',
                    icon: Icons.download_outlined,
                  ),
                  _LinkTile(
                    theme: theme,
                    title: 'Delete Account',
                    icon: Icons.delete_forever_outlined,
                    danger: true,
                  ),
                ],
              ),
            ),
          ),

          // Sign out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: _confirmSignOut,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: theme.danger, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                            color: theme.danger,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Persist v1.0.0',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final dynamic theme;
  final String title;
  final List<Widget> children;

  const _Section(
      {required this.theme, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final dynamic theme;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.text)),
                Text(subtitle,
                    style: TextStyle(color: theme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final dynamic theme;
  final String title;
  final IconData icon;
  final bool danger;

  const _LinkTile({
    required this.theme,
    required this.title,
    required this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: danger ? theme.danger : theme.textMuted),
      title:
          Text(title, style: TextStyle(color: danger ? theme.danger : theme.text)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: theme.textMuted),
      onTap: () {},
    );
  }
}
