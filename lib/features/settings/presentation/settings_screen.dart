import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _biometricLock = false;
  int _serviceLeadDays = 14;
  int _docLeadDays = 30;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isAdmin = user?.role == UserRole.admin;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Karthik Tatineni',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'karthik@depot.com',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                : AppTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAdmin ? 'ADMINISTRATOR' : 'STAFF',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAdmin
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Appearance Card (Theme switch)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appearance',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.settings_suggest, size: 16)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode, size: 16)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode, size: 16)),
                    ],
                    selected: {currentThemeMode},
                    onSelectionChanged: (newSelection) {
                      ref.read(themeModeProvider.notifier).state =
                          newSelection.first;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reminder Lead Times Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reminder Lead Times',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Service Reminders Lead',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                        'Notify $_serviceLeadDays days before due date',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    trailing: DropdownButton<int>(
                      value: _serviceLeadDays,
                      underline: const SizedBox.shrink(),
                      items: [7, 14, 21, 30]
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text('$d days')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _serviceLeadDays = val);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Document Expiry Lead',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text('Notify $_docLeadDays days before expiry',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    trailing: DropdownButton<int>(
                      value: _docLeadDays,
                      underline: const SizedBox.shrink(),
                      items: [15, 30, 45, 60]
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text('$d days')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _docLeadDays = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notifications Switches
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Push Notifications',
                        style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Receive alerts on device',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    value: _pushNotifications,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) =>
                        setState(() => _pushNotifications = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Daily Email Digest',
                        style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Summary of morning departure checks',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    value: _emailNotifications,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) =>
                        setState(() => _emailNotifications = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Biometric App Lock',
                        style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Fingerprint / Face ID to open app',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    value: _biometricLock,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) => setState(() => _biometricLock = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Change Password',
                        style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Password reset instructions sent to your email')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Company Settings (Admin only)
          if (isAdmin) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Company Settings',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN ONLY',
                            style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Fleet Company Name',
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text('KSRTC Intercity Operations',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // About & Support Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About & Support',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${AppStrings.appName} Client',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text('Version 0.1.0 • Build 2026.10',
                        style: TextStyle(fontSize: 11)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Help & Support',
                        style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.go('/support'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Log out Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Log out of FleetPulse'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
