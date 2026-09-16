import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/section_header.dart';
import '../../routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String _name = '';
  String _bloodType = '';
  String _city = '';
  List<dynamic> _urgentRequests = [];
  int _totalDonations = 0;
  int _livesSaved = 0;
  String _lastDonation = '';
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ApiService.getMyProfile(),
      ApiService.getRequests(),
      ApiService.getMyNotifications(),
    ]);
    final data = results[0] as Map<String, dynamic>;
    final requests = results[1] as List<dynamic>;
    final notifications = results[2] as List<dynamic>;
    if (!mounted) return;
    setState(() {
      _name = data['full_name']?.toString() ?? 'Donor';
      _bloodType = data['blood_type']?.toString() ?? '--';
      _city = data['city']?.toString() ?? '';
      _totalDonations = data['total_donations'] is int ? data['total_donations'] : 0;
      _livesSaved = data['lives_saved'] is int ? data['lives_saved'] : 0;
      _lastDonation = data['last_donation']?.toString() ?? '';
      _notificationCount = notifications.length;
      _urgentRequests = requests
          .where((r) {
            final status = r['status']?.toString().toLowerCase() ?? '';
            final urgency = r['urgency']?.toString().toLowerCase() ?? '';
            return status == 'searching' || urgency == 'urgent' || urgency == 'critical';
          })
          .take(5)
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.red))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.red,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildStatsRow(),
                    SectionHeader(
                      title: 'Urgent Requests',
                      actionText: 'View All',
                      onActionTap: () => Navigator.pushNamed(context, AppRoutes.request),
                    ),
                    if (_urgentRequests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: EmptyStateWidget(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Koi urgent request nahi hai',
                          subtitle: 'Jab kisi ko blood ki zaroorat hogi, yahan show hogi.',
                        ),
                      )
                    else
                      ..._urgentRequests.map((r) {
                        final blood = r['blood_type']?.toString() ?? '--';
                        final hospital = r['hospital']?.toString() ?? 'Unknown Hospital';
                        final units = r['units_needed']?.toString() ?? '1';
                        final urgency = r['urgency']?.toString() ?? '';
                        final isUrgent = urgency.toLowerCase() == 'urgent' || urgency.toLowerCase() == 'critical';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildUrgentCard(context, blood, hospital,
                              '$units units needed', isUrgent: isUrgent),
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.red, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ FIX: yeh Column pehle unconstrained tha — jab naam lamba
              // hota ya font scale zyada hoti, poori Row screen se "RIGHT
              // OVERFLOWED BY N PIXELS" ke sath bahar nikal jati (real layout
              // bug, Flutter ka debug banner nahi tha — us wo debugShowCheckedModeBanner
              // false hai app mein). Expanded + ellipsis se yeh hamesha fit rahega.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()}, $_name 🔥',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(
                        [
                          if (_city.isNotEmpty) _city,
                          _lastDonation.isNotEmpty ? 'Last donated $_lastDonation' : 'No donations yet',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xBFFFFFFF))),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.notifications);
                      if (mounted) _loadData();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white38, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                        if (_notificationCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_notificationCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: Center(
                      child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_bloodType,
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1)),
                    const SizedBox(height: 2),
                    const Text('Your blood type',
                        style: TextStyle(fontSize: 10, color: Color(0xBFFFFFFF))),
                  ],
                ),
                if (_lastDonation.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Next eligible',
                          style: TextStyle(fontSize: 10, color: Color(0xBFFFFFFF))),
                      const SizedBox(height: 3),
                      Text(_nextEligibleDate(),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFD0D0))),
                      const SizedBox(height: 4),
                      const Text('🩸', style: TextStyle(fontSize: 18)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    // ✅ FIX: pehle sirf 3 ranges thay (hour < 12 = "Good morning"), isliye
    // raat 12:00–4:59 AM mein bhi "Good morning" dikhta tha. Ab raat ke
    // liye alag range hai.
    if (hour >= 0 && hour < 5) return 'Working late';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _nextEligibleDate() {
    try {
      final last = DateTime.parse(_lastDonation);
      final eligible = last.add(const Duration(days: 56));
      final now = DateTime.now();
      if (eligible.isBefore(now)) return 'Eligible now';
      final diff = eligible.difference(now).inDays;
      return 'In $diff days';
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: _StatCard('$_totalDonations', 'Total Donations', 'Lifetime', AppColors.green)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard('$_livesSaved', 'Lives Saved', 'Active', AppColors.orange)),
        ],
      ),
    );
  }

  Widget _buildUrgentCard(BuildContext context, String blood, String name, String sub,
      {bool isUrgent = false}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.request),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(blood,
                style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('URGENT',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final String badge;
  final Color badgeColor;

  const _StatCard(this.number, this.label, this.badge, this.badgeColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(number,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(badge,
              style: TextStyle(fontSize: 9, color: badgeColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
