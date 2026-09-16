import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _bloodType = 'O+';

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.getMyProfile();
    if (!mounted) return;
    setState(() {
      _nameController.text = data['full_name']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _cityController.text = data['city']?.toString() ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _genderController.text = data['gender']?.toString() ?? '';
      final bt = data['blood_type']?.toString();
      if (bt != null && _bloodTypes.contains(bt)) _bloodType = bt;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final result = await ApiService.updateProfile(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
      bloodType: _bloodType,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${result['error']}')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Full Name', _nameController),
                  const SizedBox(height: 12),
                  _field('Phone Number', _phoneController, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('City', _cityController),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('Age', _ageController, keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Gender', _genderController)),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Blood Type',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bloodTypes.map((bt) {
                      final sel = bt == _bloodType;
                      return GestureDetector(
                        onTap: () => setState(() => _bloodType = bt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.red : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? AppColors.red : AppColors.border),
                          ),
                          child: Text(bt,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : AppColors.textPrimary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _isSaving ? null : _saveProfile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.redBright, AppColors.redDark]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Profile',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: const InputDecoration(isDense: true),
        ),
      ],
    );
  }
}
