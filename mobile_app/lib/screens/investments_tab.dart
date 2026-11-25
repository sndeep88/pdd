import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class InvestmentsTab extends StatefulWidget {
  final VoidCallback onWithdrawTap;
  const InvestmentsTab({super.key, required this.onWithdrawTap});

  @override
  State<InvestmentsTab> createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends State<InvestmentsTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('investments');
      if (!mounted) return;
      setState(() {
        _items = (res['investments'] as List<dynamic>? ?? []);
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Investments')),
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
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(28),
                        children: const [
                          SizedBox(height: 60),
                          Icon(
                            Icons.trending_up,
                            size: 56,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No investments yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Choose any investment plan from the Home tab to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) {
                          final inv = _items[i] as Map<String, dynamic>;
                          final isActive = inv['is_active'] == true;
                          final pct = (inv['progress_percent'] as num? ?? 0)
                              .toDouble()
                              .clamp(0.0, 100.0);
                          final availProfit =
                              (inv['available_profit'] as num? ?? 0).toDouble();
                          final lifetime =
                              (inv['lifetime_earned'] as num? ?? 0).toDouble();
                          final weekly =
                              (inv['weekly_profit'] as num? ?? 0).toDouble();
                          final weeks =
                              (inv['weeks_credited'] as num? ?? 0).toInt();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (inv['plan_name'] ?? 'Plan')
                                                .toString(),
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            formatUsdt(
                                              (inv['amount'] as num?) ?? 0,
                                            ),
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: isActive
                                                  ? AppColors.irishGreen
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      statusPill(
                                        (inv['status'] ?? '').toString(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _kv(
                                          'Weekly Return',
                                          '${inv['weekly_return_percent']}% (${formatUsdt(weekly)})',
                                        ),
                                      ),
                                      Expanded(
                                        child: _kv(
                                          'Next Credit',
                                          (inv['next_credit_at'] ?? '-')
                                              .toString()
                                              .substring(
                                                0,
                                                (inv['next_credit_at'] ?? '')
                                                            .toString()
                                                            .length >=
                                                        16
                                                    ? 16
                                                    : (inv['next_credit_at'] ??
                                                            '')
                                                        .toString()
                                                        .length,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.mist,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Available Profit',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                            Text(
                                              formatUsdt(availProfit),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.irishGreenDeep,
                                              ),
                                            ),
                                            Text(
                                              'Lifetime ${formatUsdt(lifetime)} · $weeks wk${weeks == 1 ? '' : 's'}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (availProfit > 0.01)
                                          ElevatedButton(
                                            onPressed: widget.onWithdrawTap,
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                            ),
                                            child: const Text('Withdraw'),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: pct / 100.0,
                                        minHeight: 7,
                                        backgroundColor: AppColors.mist,
                                        color: AppColors.emerald,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cycle progress: ${pct.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
