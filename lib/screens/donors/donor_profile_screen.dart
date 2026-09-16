import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../routes.dart';

class DonorProfileScreen extends StatefulWidget {
  final int donorId;
  const DonorProfileScreen({super.key, required this.donorId});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _donor = {};

  @override
  void initState() {
    super.initState();
    _loadDonor();
  }

  Future<void> _loadDonor() async {
    final data = await ApiService.getDonor(widget.donorId);
    if (!mounted) return;
    setState(() {
      _donor = data;
      _isLoading = false;
    });
  }

  String get _name => _donor['full_name']?.toString() ?? 'Donor';
  String get _bloodType => _donor['blood_type']?.toString() ?? '--';
  String get _city => _donor['city']?.toString() ?? '';
  int get _totalDonations => _donor['total_donations'] is int ? _donor['total_donations'] : 0;
  int get _livesSaved => _donor['lives_saved'] is int ? _donor['lives_saved'] : 0;
  double get _rating => (_donor['rating'] is num) ? (_donor['rating'] as num).toDouble() : 0.0;
  bool get _isVerified => _donor['is_verified'] == true;
  bool get _isAvailable => _donor['is_available'] == true;
  String? get _lastDonation => _donor['last_donation']?.toString();

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts[0][0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  String get _nextEligible {
    if (_lastDonation == null || _lastDonation!.isEmpty) return 'N/A';
    try {
      final last = DateTime.parse(_lastDonation!);
      final eligible = DateTime(last.year, last.month + 3, last.day);
      final now = DateTime.now();
      if (eligible.isBefore(now)) return 'Now';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${eligible.day} ${months[eligible.month - 1]} ${eligible.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String get _donorSince {
    final created = _donor['created_at']?.toString();
    if (created == null || created.isEmpty) return '';
    try {
      final dt = DateTime.parse(created);
      return 'Donor since ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildBloodInfo(),
                        _buildStats(),
                        _buildAchievements(),
                        _buildPersonalDetails(),
                        const SizedBox(height: 10),
                        _buildActionButtons(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A0A), Color(0xFF2A1010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(children: [
              Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 18),
              SizedBox(width: 6),
              Text('Donors', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF3A0A0A),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.red, width: 2),
            ),
            child: Center(
              child: Text(_initials,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.red)),
            ),
          ),
          const SizedBox(height: 10),
          Text(_name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(
            [if (_city.isNotEmpty) _city, if (_donorSince.isNotEmpty) _donorSince].join(' • '),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isAvailable ? const Color(0xFF0A2A1A) : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isAvailable ? AppColors.green : AppColors.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: _isAvailable ? AppColors.green : AppColors.textMuted, size: 7),
              const SizedBox(width: 5),
              Text(
                _isAvailable ? 'Available to Donate' : 'Not Available',
                style: TextStyle(
                    fontSize: 11,
                    color: _isAvailable ? AppColors.green : AppColors.textMuted,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _infoRow('Blood Type', _bloodType, AppColors.red, isLarge: true),
        _infoRow('Last Donated', _lastDonation ?? 'N/A', AppColors.yellow),
        _infoRow('Next Eligible', _nextEligible, AppColors.green, isLast: true),
      ]),
    );
  }

  Widget _infoRow(String key, String val, Color valColor, {bool isLarge = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(key, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(val,
            style: TextStyle(
                fontSize: isLarge ? 18 : 13,
                fontWeight: FontWeight.w700,
                color: valColor)),
      ]),
    );
  }

  Widget _buildStats() {
    final stats = [
      ('$_totalDonations', 'Donations'),
      ('$_livesSaved', 'Lives Saved'),
      (_rating.toStringAsFixed(1), 'Rating'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: stats.map((s) => Expanded(
          child: Column(children: [
            Text(s.$1,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: s.$2 == 'Rating' ? AppColors.yellow : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(s.$2, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACHIEVEMENTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_isVerified) _badge('✓ Verified', AppColors.green, const Color(0xFF0A2A1A)),
              if (_totalDonations >= 1) _badge('🩸 $_totalDonations Donations', AppColors.red, const Color(0xFF2A0A0A)),
              if (_totalDonations >= 10) _badge('🏆 Top Donor', AppColors.yellow, const Color(0xFF2A1A00)),
              if (_rating >= 4.5) _badge('⭐ Top Rated', AppColors.blue, const Color(0xFF001A2A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildPersonalDetails() {
    final age = _donor['age']?.toString() ?? '';
    final gender = _donor['gender']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _infoRow('Full Name', _name, AppColors.textPrimary),
        if (age.isNotEmpty) _infoRow('Age', '$age years', AppColors.textPrimary),
        if (gender.isNotEmpty) _infoRow('Gender', gender, AppColors.textPrimary),
        _infoRow('City', _city.isNotEmpty ? _city : 'N/A', AppColors.textPrimary, isLast: true),
      ]),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showMessageDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('✉ Message',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.request),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🩸 Request This Donor',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }

  void _showMessageDialog(BuildContext context) {
    final controller = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Message $_name',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type your message...',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => isSending = true);
                      final donorId = _donor['id'] is int ? _donor['id'] as int : 0;
                      final result = await ApiService.sendMessage(
                        receiverId: donorId,
                        message: controller.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['error'] != null
                              ? 'Message failed: ${result['error']}'
                              : 'Message sent!'),
                        ),
                      );
                    },
              child: Text(isSending ? 'Sending...' : 'Send',
                  style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
