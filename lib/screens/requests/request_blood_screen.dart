import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../routes.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _formKey = GlobalKey<FormState>();
  String _urgency = 'Urgent';
  String _selectedBlood = 'O+';
  int _units = 2;
  int _selectedHospital = 0;
  bool _isSubmitting = false;
  bool _isLoadingHospitals = true;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<_HospitalData> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    final raw = await ApiService.getHospitals();
    if (!mounted) return;
    setState(() {
      _hospitals = raw.map((h) {
        final m = h as Map<String, dynamic>;
        final dist = m['distance_km'];
        return _HospitalData(
          name: m['name']?.toString() ?? 'Hospital',
          city: m['city']?.toString() ?? '',
          distanceLabel: dist != null ? '$dist km from you' : (m['address']?.toString() ?? ''),
        );
      }).toList();
      if (_selectedHospital >= _hospitals.length) _selectedHospital = 0;
      _isLoadingHospitals = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUrgencyRow(),
                    const SizedBox(height: 16),
                    _sectionLabel('PATIENT INFO'),
                    const SizedBox(height: 10),
                    _buildField('Patient Name *',
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Patient ka naam zaroori hai' : null),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _buildField('Age *',
                              controller: _ageController,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Age zaroori hai';
                                if (int.tryParse(v.trim()) == null) return 'Sahi number likhein';
                                return null;
                              })),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildField('Gender *',
                              controller: _genderController,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Gender zaroori hai' : null)),
                    ]),
                    const SizedBox(height: 16),
                    _sectionLabel('BLOOD REQUIRED'),
                    const SizedBox(height: 10),
                    _buildBloodSelector(),
                    const SizedBox(height: 12),
                    _sectionLabel('UNITS REQUIRED'),
                    const SizedBox(height: 10),
                    _buildUnitsCounter(),
                    const SizedBox(height: 16),
                    _sectionLabel('HOSPITAL'),
                    const SizedBox(height: 10),
                    if (_isLoadingHospitals)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: AppColors.red)),
                      )
                    else if (_hospitals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No hospitals found',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      )
                    else
                      ..._hospitals.asMap().entries.map(
                          (e) => _buildHospitalCard(e.key, e.value.name, e.value.distanceLabel)),
                    const SizedBox(height: 20),
                    _buildSubmitBtn(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 10),
          const Text('Request Blood',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(width: 3, height: 12, color: AppColors.red, margin: const EdgeInsets.only(right: 6)),
        Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textMuted, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildUrgencyRow() {
    return Row(
      children: ['Normal', 'Urgent', 'Critical'].map((u) {
        final sel = _urgency == u;
        Color selColor = u == 'Normal' ? AppColors.green : u == 'Urgent' ? AppColors.orange : AppColors.red;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _urgency = u),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: sel ? selColor.withOpacity(0.15) : AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? selColor : AppColors.border),
              ),
              child: Text(u,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? selColor : AppColors.textMuted)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(String label, {TextEditingController? controller, String? initialValue, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildBloodSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: _bloodTypes.length,
      itemBuilder: (_, i) {
        final bt = _bloodTypes[i];
        final sel = bt == _selectedBlood;
        return GestureDetector(
          onTap: () => setState(() => _selectedBlood = bt),
          child: Container(
            decoration: BoxDecoration(
              color: sel ? AppColors.red : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.red : AppColors.border),
            ),
            child: Center(
              child: Text(bt,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textPrimary)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _counterBtn(Icons.remove, () => setState(() => _units = (_units - 1).clamp(1, 10))),
          const SizedBox(width: 20),
          SizedBox(
            width: 40,
            child: Text('$_units',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 20),
          _counterBtn(Icons.add, () => setState(() => _units = (_units + 1).clamp(1, 10))),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildHospitalCard(int index, String name, String dist) {
    final sel = _selectedHospital == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedHospital = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? AppColors.red : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.redDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('🏥', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                Text(dist, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ),
            if (sel)
              const Icon(Icons.check_circle, color: AppColors.green, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_hospitals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for hospitals to load')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final selected = _hospitals[_selectedHospital];

    final result = await ApiService.createRequest(
      bloodType: _selectedBlood,
      units: _units,
      hospital: selected.name,
      urgency: _urgency,
      city: selected.city.isNotEmpty ? selected.city : 'Karachi',
      patientName: _nameController.text.trim().isEmpty ? 'Patient' : _nameController.text.trim(),
      patientAge: int.tryParse(_ageController.text.trim()),
      patientGender: _genderController.text.trim().isEmpty ? null : _genderController.text.trim(),
    );

    if (!context.mounted) return;
    setState(() => _isSubmitting = false);

    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: ${result['error']}')),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.confirmation,
      arguments: result,
    );
  }

  Widget _buildSubmitBtn(BuildContext context) {
    return GestureDetector(
      onTap: _isSubmitting ? null : () => _submitRequest(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.redBright, AppColors.redDark]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Submit Request →',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

class _HospitalData {
  final String name;
  final String city;
  final String distanceLabel;

  _HospitalData({required this.name, required this.city, required this.distanceLabel});
}
