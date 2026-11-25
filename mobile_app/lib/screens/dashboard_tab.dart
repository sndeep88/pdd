import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import 'invest_sheet.dart';
import 'notifications_screen.dart';

/// Clean, beginner-friendly User Dashboard:
/// - Simple greeting
/// - One clear Balance Card with "Buy a Plan" + "Withdraw"
/// - Website-matching Telegram buttons ("Buy Now" & "24/7 Help" + IT Support)
/// - Live Investment Plans with clean wrapped RegionSelector
class DashboardTab extends StatefulWidget {
  final ValueChanged<int> onNavigateTab;
  final Map<String, dynamic>? initialInvestPlan;

  const DashboardTab({
    super.key,
    required this.onNavigateTab,
    this.initialInvestPlan,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _scrollCtrl = ScrollController();
  final _plansKey = GlobalKey();

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _selectedRegion = '';
  bool _openedInitialPlan = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('dashboard');
      if (!mounted) return;
      final grouped = (res['plans_grouped'] as Map<String, dynamic>? ?? {});
      final ordered = sortRegionsActiveFirst(grouped);
      setState(() {
        _data = res;
        if (_selectedRegion.isEmpty || !grouped.containsKey(_selectedRegion)) {
          _selectedRegion = ordered.isNotEmpty ? ordered.first : '';
        }
        _loading = false;
      });
      if (!_openedInitialPlan && widget.initialInvestPlan != null) {
        _openedInitialPlan = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openInvest(widget.initialInvestPlan!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToPlans() {
    final ctx = _plansKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openInvest(Map<String, dynamic> plan) async {
    final invested = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvestSheet(plan: plan),
    );
    if (invested == true) {
      _load();
    }
  }

  void _openConverter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CurrencyConverterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = (_data?['user'] as Map<String, dynamic>?) ??
        ApiClient.instance.cachedUser ??
        {};
    final stats = (_data?['stats'] as Map<String, dynamic>?) ?? {};
    final unread = (stats['unread_notifications_count'] as num? ?? 0).toInt();
    final buyFabTitle = (_data?['it_support_title'] ?? 'BUY PLAN').toString();
    final buyFabSubtitle = (_data?['it_support_subtitle'] ??
            'For more information, please contact @mrmantelo')
        .toString();
    final buyFabUrl =
        (_data?['it_support_url'] ?? 'https://t.me/mrmantelo').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('☘️ ', style: TextStyle(fontSize: 20)),
            Text('Paddyusdt'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Currency Converter',
            icon: const Icon(Icons.currency_exchange, size: 20),
            onPressed: _openConverter,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  _load();
                },
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: TelegramBuyPlanFab(
        title: buyFabTitle,
        subtitle: buyFabSubtitle,
        url: buyFabUrl,
      ),
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
                      const Icon(Icons.cloud_off, size: 52, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : _buildSimpleBody(user, stats),
      ),
    );
  }

  Widget _buildSimpleBody(Map<String, dynamic> user, Map<String, dynamic> stats) {
    final fullName = (user['full_name'] ?? 'Friend').toString();
    final firstName = fullName.split(' ').first;
    final walletBalance = (stats['wallet_balance'] as num? ?? 0).toDouble();
    final walletAvail = (stats['wallet_available'] as num? ?? 0).toDouble();
    final totalInvested = (stats['total_invested'] as num? ?? 0).toDouble();
    final availProfit = (stats['available_profit'] as num? ?? 0).toDouble();
    final activeCount = (stats['active_investments_count'] as num? ?? 0).toInt();

    final grouped = (_data?['plans_grouped'] as Map<String, dynamic>? ?? {});
    final regions = sortRegionsActiveFirst(grouped);
    final regionPlans = sortPlansActiveFirst(grouped[_selectedRegion] as List<dynamic>? ?? []);

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
      children: [
        // Simple Greeting
        FadeSlideIn(
          child: Text(
            'Hi, $firstName 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),

        // ONE Clean, Crystal-Clear Balance Card
        FadeSlideIn(
          delayMs: 50,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF06291A), AppColors.irishGreenDeep, AppColors.irishGreen],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.irishGreenDeep.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deposited Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (walletAvail > 0.009)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${formatUsdt(walletAvail)} free',
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedUsdtText(
                  value: walletBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                // Just 2 simple numbers: Invested & Profit Ready
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNavigateTab(2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Plans ($activeCount)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatUsdt(totalInvested),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onNavigateTab(3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profit Ready',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatUsdt(availProfit),
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Just 2 clear buttons: Buy a Plan & Withdraw
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _scrollToPlans,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Buy a Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldLight,
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onNavigateTab(3),
                        icon: const Icon(Icons.outbox_rounded, size: 18),
                        label: const Text('Withdraw'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Simple Investment Plans Section
        Row(
          key: _plansKey,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose a Plan',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '${regionPlans.length} available',
              style: const TextStyle(
                color: AppColors.irishGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (regions.isNotEmpty)
          RegionSelector(
            regions: regions,
            selectedRegion: _selectedRegion,
            plansGrouped: grouped,
            onSelected: (r) => setState(() => _selectedRegion = r),
          ),

        const SizedBox(height: 12),

        ...regionPlans.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value as Map<String, dynamic>;
          final investable = p['investable'] == true;
          final pct = (p['weekly_return_percent'] as num? ?? 0).toDouble();
          final amt = (p['amount'] as num? ?? 0).toDouble();
          final weeklyEarn = amt * pct / 100.0;
          final unit = (p['unit'] ?? 'USDT').toString();
          final isVip = _selectedRegion.toLowerCase().contains('vip');
          final blockReason = (p['block_reason'] ?? 'Coming Soon').toString();
          final shortBlock = blockReason.toLowerCase().contains('sold out')
              ? 'Sold Out'
              : 'Soon';

          return FadeSlideIn(
            key: ValueKey('dash_${_selectedRegion}_${p['id']}'),
            delayMs: (i * 50).clamp(0, 250),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: isVip
                    ? const LinearGradient(
                        colors: [Color(0xFF141E18), Color(0xFF3E3010)],
                      )
                    : null,
                color: isVip ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isVip
                      ? AppColors.goldLight.withValues(alpha: 0.5)
                      : AppColors.irishGreen.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (p['name'] ?? 'Plan').toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isVip ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${amt.toStringAsFixed(0)} $unit',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isVip ? AppColors.goldLight : AppColors.irishGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Earn +${weeklyEarn.toStringAsFixed(0)} $unit every week ($pct%)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isVip
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: investable ? () => _openInvest(p) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !investable
                            ? Colors.grey.shade200
                            : (isVip ? AppColors.goldLight : AppColors.irishGreen),
                        foregroundColor: !investable
                            ? Colors.grey.shade600
                            : (isVip ? AppColors.ink : Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      child: Text(investable ? 'Buy Now' : shortBlock),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
