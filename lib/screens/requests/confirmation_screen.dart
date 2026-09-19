import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

class ConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const ConfirmationScreen({super.key, required this.requestData});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  late Map<String, dynamic> _data;
  Timer? _pollTimer;
  bool _isPolling = false;
  bool _isMarkingComplete = false;

  @override
  void initState() {
    super.initState();
    _data = widget.requestData;
    _startPollingIfNeeded();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPollingIfNeeded() {
    final status = _data['status']?.toString() ?? 'Searching';
    if (status != 'Searching') return;

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    final id = _data['id'];
    if (id == null || _isPolling) return;
    _isPolling = true;

    final result = await ApiService.getRequest(id is int ? id : int.parse(id.toString()));
    _isPolling = false;
    if (!mounted) return;

    if (result['error'] != null) return;

    final newStatus = result['status']?.toString();
    if (newStatus != null && newStatus != _data['status']) {
      setState(() => _data = result);
      if (newStatus != 'Searching') {
        _pollTimer?.cancel();
        if (newStatus == 'Confirmed') {
          _showConfirmedSnackbar();
        }
      }
    } else {
      setState(() => _data = result);
    }
  }

  // ✅ NEW: donor ko blood mil jaane ke baad requester yahan se donation ko
  // "Completed" mark karta hai. Backend is par donor ki profile stats
  // (Total Donations, Lives Saved, Last Donation) automatic update kar deta hai.
  Future<void> _markComplete() async {
    final id = _data['id'];
    if (id == null || _isMarkingComplete) return;
    setState(() => _isMarkingComplete = true);
    final result = await ApiService.updateRequestStatus(
      requestId: id is int ? id : int.parse(id.toString()),
      status: 'Completed',
    );
    if (!mounted) return;
    setState(() => _isMarkingComplete = false);
    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${result['error']}')),
      );
      return;
    }
    setState(() => _data = {..._data, 'status': 'Completed'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Donation complete mark ho gayi — shukriya!'),
        backgroundColor: Color(0xFF1A3A1A),
      ),
    );
  }

  void _showConfirmedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Ek donor ne accept kar liya hai!'),
        backgroundColor: Color(0xFF1A3A1A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloodType = _data['blood_type']?.toString() ?? '--';
    final units = _data['units_needed']?.toString() ?? '-';
    final patientName = _data['patient_name']?.toString() ?? '--';
    final patientAge = _data['patient_age'];
    final patientGender = _data['patient_gender']?.toString();
    final hospital = _data['hospital']?.toString() ?? '--';
    final urgency = _data['urgency']?.toString() ?? '--';
    final status = _data['status']?.toString() ?? 'Searching';
    final refNumber = _data['ref_number']?.toString() ?? '--';
    final requiredBy = _data['required_by']?.toString();
    final donorName = _data['donor_name']?.toString();
    final donorPhone = _data['donor_phone']?.toString();

    final patientLabel = [
      patientName,
      if (patientAge != null) '$patientAge',
      if (patientGender != null && patientGender.isNotEmpty) patientGender[0],
    ].join(', ');

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Column(
        children: [
          _buildProgressBar(status),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTop(bloodType, refNumber, status),
                  if (status == 'Confirmed' && donorName != null)
                    _buildDonorFoundCard(donorName, donorPhone),
                  _buildInfoCard(
                    patientLabel: patientLabel,
                    bloodType: bloodType,
                    units: units,
                    hospital: hospital,
                    urgency: urgency,
                    requiredBy: requiredBy,
                    status: status,
                  ),
                  const SizedBox(height: 24),
                  _buildButtons(context, status),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final isConfirmed = status != 'Searching';
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      child: Row(
        children: [
          _progressStep('✓', 'Sent', true),
          Expanded(child: Container(height: 1, color: AppColors.red)),
          _progressStep(isConfirmed ? '✓' : '●', 'Finding', true),
          Expanded(child: Container(height: 1, color: isConfirmed ? AppColors.red : AppColors.border)),
          _progressStep(isConfirmed ? '✓' : '3', 'Confirmed', isConfirmed),
        ],
      ),
    );
  }

  Widget _progressStep(String icon, String label, bool done) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: done ? AppColors.red : AppColors.textMuted, width: 2),
          ),
          child: Center(
            child: Text(icon,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.red : AppColors.textMuted)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: done ? AppColors.red : AppColors.textMuted)),
      ],
    );
  }

  Widget _buildTop(String bloodType, String refNumber, String status) {
    final isConfirmed = status == 'Confirmed';
    final isCompleted = status == 'Completed';
    final title = isConfirmed
        ? 'Donor Mil Gaya! 🎉'
        : isCompleted
            ? 'Donation Complete'
            : 'Request Submitted';
    final badgeColor = isConfirmed || isCompleted ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A0A), AppColors.dark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF2A0A0A),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.red, width: 2),
          ),
          child: Center(
            child: Text(bloodType,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.red)),
          ),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Ref: $refNumber',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A0A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, color: badgeColor, size: 8),
            const SizedBox(width: 6),
            Text(status,
                style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.w700)),
            if (status == 'Searching') ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.red),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildDonorFoundCard(String donorName, String? donorPhone) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A1A),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            child: Center(
              child: Text(donorName.isNotEmpty ? donorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.green)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(donorPhone != null && donorPhone.isNotEmpty ? donorPhone : 'Contact via app',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (donorPhone != null && donorPhone.isNotEmpty)
            GestureDetector(
              onTap: () => _callDonor(donorPhone),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _callDonor(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildInfoCard({
    required String patientLabel,
    required String bloodType,
    required String units,
    required String hospital,
    required String urgency,
    required String? requiredBy,
    required String status,
  }) {
    final rows = [
      ['Patient', patientLabel],
      ['Blood Type', '$bloodType — $units Units'],
      ['Hospital', hospital],
      ['Urgency', urgency],
      if (requiredBy != null && requiredBy.isNotEmpty) ['Required by', requiredBy],
      ['Status', status],
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.map((r) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r[0], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Flexible(
                  child: Text(r[1],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: r[0] == 'Urgency' ? AppColors.orange
                              : r[0] == 'Status' ? (status == 'Searching' ? AppColors.yellow : AppColors.green)
                              : AppColors.textPrimary)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _buildShareText() {
    final bloodType = _data['blood_type']?.toString() ?? '--';
    final units = _data['units_needed']?.toString() ?? '-';
    final hospital = _data['hospital']?.toString() ?? '--';
    final urgency = _data['urgency']?.toString() ?? 'Urgent';
    final refNumber = _data['ref_number']?.toString() ?? '--';
    return '🚨 $urgency Blood Request\n'
        'Blood Type: $bloodType ($units units)\n'
        'Hospital: $hospital\n'
        'Ref: $refNumber\n'
        'Please contact us or share this with potential donors!';
  }

  // ✅ FIX: pehle yeh default (plain, dark-grey, thin) SnackBar tha jo black
  // background pe barely dikhta tha aur 4 sec mein ghayab ho jata — screenshots
  // 007/008/009 mein yehi wajah thi ke message "chupa hua" sa lag raha tha.
  // Ab: bold icon + colored border + floating (bottom nav se upar) + 3.5 sec.
  void _showAppSnackbar(BuildContext context, String message,
      {required bool success}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 90),
        duration: const Duration(milliseconds: 3500),
        backgroundColor: success ? const Color(0xFF123A1E) : const Color(0xFF3A1414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: success ? AppColors.green : AppColors.red, width: 1.4),
        ),
        content: Row(
          children: [
            Icon(success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? AppColors.green : AppColors.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(_buildShareText());
    final url = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showAppSnackbar(context, 'WhatsApp install nahi hai', success: false);
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    final text = _buildShareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      _showAppSnackbar(context, 'Request copy ho gayi — paste karke share karo!',
          success: true);
    }
  }

  Widget _buildButtons(BuildContext context, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          if (status == 'Confirmed')
            GestureDetector(
              onTap: _isMarkingComplete ? null : _markComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isMarkingComplete
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('✅ Blood Mil Gaya — Donation Complete Karo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          if (status == 'Completed')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green),
              ),
              child: const Text('🎉 Donation Complete — Shukriya!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
            ),
          if (status == 'Searching')
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0808),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency, color: AppColors.red, size: 16),
                      SizedBox(width: 6),
                      Text('🚨 SOS — Jaldi Share Karo',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _shareOnWhatsApp(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF075E54),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('📱 WhatsApp',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _copyLink(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text('🔗 Copy Karo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('🏠 Back to Home',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}
