import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _notifyAllTypes = true;
  bool _isSavingNotify = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await ApiService.getMyProfile();
    if (!mounted) return;
    setState(() {
      _notifyAllTypes = data['notify_all_types'] == true;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotify(bool value) async {
    setState(() {
      _notifyAllTypes = value;
      _isSavingNotify = true;
    });
    final result = await ApiService.updateProfile(notifyAllTypes: value);
    if (!mounted) return;
    setState(() => _isSavingNotify = false);
    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save failed — please try again')),
      );
      setState(() => _notifyAllTypes = !value);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Log out?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will need to log in again to use the app.',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiService.logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Settings', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionLabel('NOTIFICATIONS'),
                const SizedBox(height: 8),
                _settingsCard(
                  child: SwitchListTile(
                    value: _notifyAllTypes,
                    onChanged: _isSavingNotify ? null : _toggleNotify,
                    activeColor: AppColors.red,
                    title: const Text('Notify me for all blood types',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    subtitle: const Text('Turn off to only get notified for your blood type',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('ACCOUNT'),
                const SizedBox(height: 8),
                _settingsCard(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.textPrimary),
                    title: const Text('Change Password',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    subtitle: const Text('Update your account password',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('ABOUT'),
                const SizedBox(height: 8),
                _settingsCard(
                  child: const ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.textMuted),
                    title: Text('Blood Donation App',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                    subtitle: Text('Version 1.0.0',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _confirmLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.red),
                    ),
                    child: const Text('Log Out',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.red)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8));
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
