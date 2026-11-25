import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('wallet');
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = (_data?['wallet'] as Map<String, dynamic>?) ?? {};
    final entries = (_data?['entries'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.irishGreen,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 60),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.ink, AppColors.irishGreenDeep],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paddyusdt Wallet (Lifetime Deposits)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatUsdt((wallet['balance'] as num?) ?? 0),
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Available: ${formatUsdt((wallet['available'] as num?) ?? 0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Allocated: ${formatUsdt((wallet['allocated'] as num?) ?? 0)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Wallet Ledger',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (entries.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No wallet entries yet.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ),
                        )
                      else
                        ...entries.map((raw) {
                          final r = raw as Map<String, dynamic>;
                          final amtUsdt = (r['amount_usdt'] as num? ?? 0).toDouble();
                          final isNeg = amtUsdt < 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isNeg
                                    ? const Color(0xFFFEE2E2)
                                    : AppColors.mist,
                                child: Icon(
                                  isNeg ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isNeg
                                      ? AppColors.danger
                                      : AppColors.irishGreen,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatUsdt(amtUsdt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isNeg ? AppColors.danger : AppColors.ink,
                                    ),
                                  ),
                                  statusPill((r['status'] ?? 'waiting').toString()),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${r['coin_label'] ?? r['currency']} · ${r['created_at'] ?? ''}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if ((r['txn_id'] ?? '').toString().isNotEmpty)
                                    Text(
                                      'Ref: ${r['txn_id']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
