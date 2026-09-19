import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state_widget.dart';
import 'chat_screen.dart';

// ✅ NEW SCREEN: Inbox — pehle app mein "Message" bhejne ka button to tha,
// lekin bheje/aaye hue messages kahin dikhte hi nahi the (koi Inbox screen
// exist hi nahi karti thi). Yeh screen har conversation ka aakhri message
// aur unread count dikhati hai, tap karne par poora chat thread khulta hai.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations = data;
      _isLoading = false;
    });
  }

  String _timeLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (sameDay) {
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        title: const Text('Messages', style: AppTextStyles.heading3),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.red,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.red))
            : _conversations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const EmptyStateWidget(
                          icon: Icons.mail_outline_rounded,
                          title: 'Abhi koi message nahi hai',
                          subtitle: 'Kisi donor ko message bhejein, wo yahan conversation ki tarah dikhega.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) => _buildCard(_conversations[i]),
                  ),
      ),
    );
  }

  Widget _buildCard(dynamic c) {
    final otherId = c['other_user_id'] is int ? c['other_user_id'] as int : 0;
    final name = c['other_user_name']?.toString() ?? 'Unknown';
    final lastMessage = c['last_message']?.toString() ?? '';
    final unread = c['unread_count'] is int ? c['unread_count'] as int : 0;
    final time = _timeLabel(c['last_message_at']?.toString());

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(otherUserId: otherId, otherUserName: name),
          ),
        );
        if (mounted) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: unread > 0 ? AppColors.red : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2A0A0A),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.red, width: 1.5),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: unread > 0 ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                if (unread > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
