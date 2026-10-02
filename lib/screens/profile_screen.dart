import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finance/state/app_state.dart';
import 'package:finance/utils/app_theme.dart';
import 'package:finance/utils/formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    AppState.instance.removeListener(_rebuild);
    super.dispose();
  }

  // ── Profile picture ──────────────────────────────────────────────────────

  void _showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final state = AppState.instance;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Profile Picture',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (state.hasValidProfileImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  title: const Text('Remove photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    AppState.instance.removeProfileImage();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        await AppState.instance.saveProfile(
          newName: AppState.instance.name,
          newEmail: AppState.instance.email,
          newPhone: AppState.instance.phone,
          newImagePath: picked.path,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not access camera/gallery.')),
        );
      }
    }
  }

  // ── Edit profile dialog ──────────────────────────────────────────────────

  void _openEditProfile() {
    final state = AppState.instance;
    final nameCtrl = TextEditingController(text: state.name);
    final emailCtrl = TextEditingController(text: state.email);
    final phoneCtrl = TextEditingController(text: state.phone);
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
                  if (!emailReg.hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await AppState.instance.saveProfile(
                  newName: nameCtrl.text.trim(),
                  newEmail: emailCtrl.text.trim(),
                  newPhone: phoneCtrl.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Currency picker ──────────────────────────────────────────────────────

  void _openCurrencyPicker() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: kCurrencies.map((c) {
            final selected = AppState.instance.currencyCode == c.code;
            return ListTile(
              leading: Text(c.symbol,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              title: Text(c.name),
              subtitle: Text(c.code),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () async {
                await AppState.instance.setCurrency(c.code);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Monthly budget dialog ────────────────────────────────────────────────

  void _editMonthlyBudget() {
    final ctrl = TextEditingController(
        text: AppState.instance.monthlyBudget > 0
            ? AppState.instance.monthlyBudget.toStringAsFixed(2)
            : '');
    final sym = AppState.instance.currencySymbol;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '$sym ',
            hintText: '0.00',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
              await AppState.instance.setMonthlyBudget(val);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Clear data ───────────────────────────────────────────────────────────

  Future<void> _clearDataAction(BuildContext ctx) async {
    await AppState.instance.clearAllTransactions();
    if (!mounted) return;
    if (ctx.mounted) Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All transactions deleted.'),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClearData() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete all transactions. Profile and settings are kept.\n\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => _clearDataAction(ctx),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sym = state.currencySymbol;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────
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

            // ── Profile card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              backgroundImage: state.hasValidProfileImage
                                  ? FileImage(File(state.profileImagePath))
                                  : null,
                              child: state.hasValidProfileImage
                                  ? null
                                  : const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 34),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 12, color: AppColors.primary),
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
                              state.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                            if (state.email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(state.email,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70)),
                            ],
                            if (state.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(state.phone,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Financial summary ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Balance',
                        value: formatAmount(state.balance, symbol: sym),
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Income',
                        value: formatAmount(state.totalIncome, symbol: sym),
                        color: AppColors.income,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Expenses',
                        value: formatAmount(state.totalExpenses, symbol: sym),
                        color: AppColors.expense,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Preferences ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader('Preferences', isDark: isDark),
                    const SizedBox(height: 8),

                    // Dark mode
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark Mode',
                      color: AppColors.accent,
                      isDark: isDark,
                      trailing: Switch(
                        value: state.isDarkMode,
                        onChanged: (v) => AppState.instance.setDarkMode(v),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor:
                            AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),

                    // Currency
                    _SettingsTile(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Currency',
                      subtitle: '${state.currency.name} (${state.currencySymbol})',
                      color: AppColors.income,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                      onTap: _openCurrencyPicker,
                    ),

                    // Notifications
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      color: AppColors.warning,
                      isDark: isDark,
                      trailing: Switch(
                        value: state.notificationsEnabled,
                        onChanged: (v) =>
                            AppState.instance.setNotifications(v),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor:
                            AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),

                    // Monthly budget
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Monthly Budget',
                      subtitle: state.monthlyBudget > 0
                          ? formatAmount(state.monthlyBudget, symbol: sym)
                          : 'Not set',
                      color: AppColors.primary,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                      onTap: _editMonthlyBudget,
                    ),

                    const SizedBox(height: 20),
                    _SectionHeader('Data Management', isDark: isDark),
                    const SizedBox(height: 8),

                    // Clear transactions
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear All Transactions',
                      subtitle:
                          '${state.transactions.length} transactions',
                      color: AppColors.expense,
                      isDark: isDark,
                      trailing: const Icon(Icons.chevron_right_rounded,
                          size: 20),
                      onTap: _confirmClearData,
                    ),

                    const SizedBox(height: 20),
                    _SectionHeader('About', isDark: isDark),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatBox(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader(this.label, {required this.isDark});

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
  final String? subtitle;
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
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight))
              : null,
          trailing: trailing,
        ),
      ),
    );
  }
}
