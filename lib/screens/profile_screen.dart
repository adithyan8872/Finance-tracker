import 'package:flutter/material.dart';
import 'package:finance/utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),

            // Avatar + name
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'My Wallet',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Checking Account •• 4290',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Settings
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(label: 'Preferences', isDark: isDark),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark Mode',
                      color: AppColors.accent,
                      isDark: isDark,
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: onThemeToggle,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      color: AppColors.warning,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      label: 'Currency & Language',
                      color: AppColors.income,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(label: 'Data', isDark: isDark),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.file_download_outlined,
                      label: 'Export as CSV',
                      color: AppColors.primary,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Export as PDF',
                      color: AppColors.expense,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear All Data',
                      color: AppColors.expense,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                      onTap: () {},
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(label: 'About', isDark: isDark),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Version 1.0.0',
                      color: AppColors.textSecondaryLight,
                      isDark: isDark,
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
