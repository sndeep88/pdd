import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/notification_center.dart';
import '../theme/app_theme.dart';
import '../theme/notification_style.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = _items.isEmpty);
    try {
      final res = await ApiClient.instance.get('notifications');
      if (!mounted) return;
      setState(() {
        _items = ((res['notifications'] as List<dynamic>?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
        _loading = false;
      });
      NotificationCenter.instance.setUnread((res['unread_count'] as num?)?.toInt() ?? _items.where((n) => !n.isRead).length);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.post('notifications', {'action': 'mark_all_read'});
      _load();
    } catch (_) {}
  }

  Future<void> _open(AppNotification n) async {
    if (n.isRead) return;
    setState(() {
      _items = _items
          .map((x) => x.id == n.id
              ? AppNotification(
                  id: x.id,
                  type: x.type,
                  title: x.title,
                  message: x.message,
                  sound: x.sound,
                  imageUrl: x.imageUrl,
                  isRead: true,
                  createdAt: x.createdAt,
                )
              : x)
          .toList();
    });
    await NotificationCenter.instance.markRead(n.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.irishGreen,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.muted),
                      SizedBox(height: 12),
                      Center(
                        child: Text('No notifications yet.', style: TextStyle(color: AppColors.muted)),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _NotificationTile(
                      n: _items[i],
                      onTap: () => _open(_items[i]),
                    ),
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;

  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = notifStyleFor(n.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : s.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: n.isRead ? const Color(0xFFE2E8F0) : s.color.withValues(alpha: 0.4),
            ),
            boxShadow: n.isRead
                ? null
                : [BoxShadow(color: s.color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [s.color, s.deep],
                  ),
                ),
                child: Icon(s.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: const TextStyle(fontSize: 13.5, height: 1.35, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.label,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: s.color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          n.createdAt,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
