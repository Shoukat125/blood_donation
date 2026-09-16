import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../routes.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  String _activeChip = 'All';
  int _activeTab = 0;
  bool _isLoading = true;
  List<_DonorData> _donors = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _chips = ['All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _tabs = ['Available Now', 'All Donors', 'Nearby 🔒'];

  static const List<Color> _avatarBgPalette = [
    Color(0xFF3A0A0A), Color(0xFF0A1A3A), Color(0xFF1A0A3A), Color(0xFF0A2A1A),
  ];
  static const List<Color> _avatarColorPalette = [
    AppColors.red, AppColors.blue, AppColors.purple, AppColors.green,
  ];

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DonorData> get _filteredDonors {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _donors;
    return _donors.where((d) {
      return d.name.toLowerCase().contains(q) ||
          d.info.toLowerCase().contains(q) ||
          d.blood.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _loadDonors() async {
    setState(() => _isLoading = true);

    final bloodTypeFilter = _activeChip == 'All' ? null : _activeChip;
    final availableOnly = _activeTab == 0;

    final raw = await ApiService.getDonors(
      bloodType: bloodTypeFilter,
      availableOnly: availableOnly,
    );

    if (!mounted) return;
    setState(() {
      _donors = List.generate(raw.length, (i) {
        final d = raw[i] as Map<String, dynamic>;
        final name = d['full_name']?.toString() ?? 'Donor';
        final city = d['city']?.toString() ?? '';
        final blood = d['blood_type']?.toString() ?? '--';
        final donations = d['total_donations'];
        final available = d['is_available'] == true;

        final initials = name.trim().isNotEmpty
            ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
            : '?';
        final info = [
          if (city.isNotEmpty) city,
          if (donations != null) 'Donated ${donations}x',
        ].join(' • ');

        return _DonorData(
          d['id'] is int ? d['id'] as int : int.tryParse('${d['id']}') ?? 0,
          initials,
          name,
          info.isEmpty ? 'No info available' : info,
          blood,
          available,
          _avatarBgPalette[i % _avatarBgPalette.length],
          _avatarColorPalette[i % _avatarColorPalette.length],
        );
      });
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.red))
                : RefreshIndicator(
                    onRefresh: _loadDonors,
                    color: AppColors.red,
                    child: _buildDonorList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(14, 52, 14, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Find Donors', style: AppTextStyles.heading2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(children: [
                  Icon(Icons.tune, size: 14, color: AppColors.textPrimary),
                  SizedBox(width: 4),
                  Text('Filter',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.search, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, city or blood type...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final chip = _chips[i];
                final active = chip == _activeChip;
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeChip = chip);
                    _loadDonors();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? AppColors.red : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.red : AppColors.border),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: active ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = _activeTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nearby feature jald aa rahi hai 🚧')),
                  );
                  return;
                }
                setState(() => _activeTab = i);
                _loadDonors();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: active ? AppColors.red : Colors.transparent, width: 2),
                  ),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.red : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDonorList() {
    final list = _filteredDonors;
    if (list.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'Koi donor nahi mila',
        subtitle: 'Mukhtalif blood type ya location search karein.',
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _DonorCard(donor: list[i]),
    );
  }
}

class _DonorData {
  final int id;
  final String initials;
  final String name;
  final String info;
  final String blood;
  final bool available;
  final Color avatarBg;
  final Color avatarColor;

  const _DonorData(this.id, this.initials, this.name, this.info, this.blood,
      this.available, this.avatarBg, this.avatarColor);
}

class _DonorCard extends StatelessWidget {
  final _DonorData donor;

  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.donorProfile,
        arguments: donor.id,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: donor.avatarBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  donor.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: donor.avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: donor.available ? AppColors.green : const Color(0xFF555555),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(donor.info,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                donor.blood,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: donor.avatarColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
