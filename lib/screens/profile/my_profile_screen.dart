import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../routes.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _available = true;
  String _name = '';
  String _bloodType = '';
  int _totalDonations = 0;
  int _livesSaved = 0;
  double _rating = 0.0;
  bool _isVerified = false;
  bool _initialAvailable = true;
  String? _lastDonation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.getMyProfile();
    if (!mounted) return;
    setState(() {
      _name = data['full_name']?.toString() ?? 'Donor';
      _bloodType = data['blood_type']?.toString() ?? '--';
      _totalDonations = data['total_donations'] is int ? data['total_donations'] : 0;
      _livesSaved = data['lives_saved'] is int ? data['lives_saved'] : 0;
      _rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
      _isVerified = data['is_verified'] == true;
      _available = data['is_available'] == true;
      _initialAvailable = _available;
      _lastDonation = data['last_donation']?.toString();
      _isLoading = false;
    });
    _checkAndAutoUpdateAvailability();
  }

  Future<void> _checkAndAutoUpdateAvailability() async {
    if (_lastDonation == null || _lastDonation!.isEmpty) return;
    try {
      final last = DateTime.parse(_lastDonation!);
      final eligible = last.add(const Duration(days: 56));
      final now = DateTime.now();
      if (eligible.isBefore(now) && !_available) {
        await ApiService.updateProfile(isAvailable: true);
        if (!mounted) return;
        setState(() {
          _available = true;
          _initialAvailable = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 56 din guzar gaye — aap automatic Available ho gaye!'),
              backgroundColor: Color(0xFF1A3A1A),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    final result = await ApiService.updateProfile(isAvailable: _available);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _initialAvailable = _available;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['error'] != null ? 'Save failed' : 'Saved')),
    );
  }

  String get _nextEligible {
    if (_lastDonation == null || _lastDonation!.isEmpty) return 'N/A';
    try {
      final last = DateTime.parse(_lastDonation!);
      final eligible = last.add(const Duration(days: 56));
      final now = DateTime.now();
      if (eligible.isBefore(now)) return 'Now';
      return '${eligible.day} ${_monthName(eligible.month)} ${eligible.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts[0][0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.red,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildAvailabilityCard(),
                    _buildAchievementsCard(),
                    _buildBottomButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.red, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Center(
                    child: Text(_initials,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(_isVerified ? 'Verified Donor' : 'Your Donor Profile',
                      style: const TextStyle(fontSize: 11, color: Color(0xBFFFFFFF))),
                  const SizedBox(height: 5),
                  Row(children: [
                    Icon(Icons.circle, color: _available ? AppColors.green : AppColors.textMuted, size: 8),
                    const SizedBox(width: 5),
                    Text(_available ? 'Available to Donate' : 'Not Available',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ]),
              GestureDetector(
                onTap: () async {
                  final updated = await Navigator.pushNamed(context, AppRoutes.editProfile);
                  if (updated == true) _loadProfile();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Edit',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Text(_bloodType,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Donated', style: TextStyle(fontSize: 10, color: Color(0xBFFFFFFF))),
              Text('$_totalDonations Times', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
            Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Next Eligible', style: TextStyle(fontSize: 10, color: Color(0xBFFFFFFF))),
              Text(_nextEligible, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                _myStat('$_totalDonations', 'Donations'),
                _myStat('$_livesSaved', 'Lives Saved'),
                _myStat(_rating.toStringAsFixed(1), 'Rating'),
                _myStat(_isVerified ? 'Yes' : 'No', 'Verified'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _myStat(String num, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Colors.white12)),
        ),
        child: Column(children: [
          Text(num,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Color(0xBFFFFFFF))),
        ]),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVAILABILITY',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Status', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            Row(children: [
              Text(_available ? 'Available' : 'Unavailable',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _available ? AppColors.green : AppColors.textMuted)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _available = !_available),
                child: Container(
                  width: 42,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _available ? AppColors.green : AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _available ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
          const Divider(color: AppColors.border, height: 20),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Notify me for', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text('All blood types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Max distance', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text('10 km', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    // ✅ FIX: pehle ye badges hardcoded the (har user ko "3 Donations",
    // "Verified" dikhta tha chahe unka asal data kuch bhi ho). Ab real
    // profile data (_isVerified, _totalDonations) se badges banate hain.
    final badges = <Widget>[
      _badge(
        _isVerified ? '✓ Verified' : '○ Not Verified',
        _isVerified ? AppColors.green : AppColors.textMuted,
        _isVerified ? const Color(0xFF0A2A1A) : AppColors.card2,
      ),
      _badge(
        '🎖 $_totalDonations Donation${_totalDonations == 1 ? '' : 's'}',
        AppColors.blue,
        const Color(0xFF001A2A),
      ),
      _badge(
        _totalDonations >= 10 ? '🏆 Top Donor' : '🏆 Top Donor (Locked)',
        _totalDonations >= 10 ? AppColors.orange : AppColors.textMuted,
        _totalDonations >= 10 ? const Color(0xFF2A1A00) : AppColors.card2,
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACHIEVEMENTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: badges),
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

  Widget _buildBottomButtons() {
    final hasChanges = _available != _initialAvailable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('⚙ Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: (hasChanges && !_isSaving) ? _saveAvailability : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: hasChanges ? AppColors.green : AppColors.card2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A2A1A)),
                    )
                  : Text(hasChanges ? 'Save Changes ✓' : 'No Changes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: hasChanges ? const Color(0xFF0A2A1A) : AppColors.textMuted)),
            ),
          ),
        ),
      ]),
    );
  }
}
