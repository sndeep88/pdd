import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Public landing screen shown immediately on app open:
/// - Compact Login button at top-right
/// - Eye-catching animated emerald & gold hero
/// - ALL live investment plans from live DB grouped by region (Ireland, Spain, Dubai, LA, VIP)
/// - Live Currency Converter + Cash ↔ Crypto Exchange highlight
class ExplorePlansScreen extends StatefulWidget {
  final void Function({Map<String, dynamic>? pendingPlan}) onAuthenticated;

  const ExplorePlansScreen({super.key, required this.onAuthenticated});

  @override
  State<ExplorePlansScreen> createState() => _ExplorePlansScreenState();
}

class _ExplorePlansScreenState extends State<ExplorePlansScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _selectedRegion = '';
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('public-plans');
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openLogin({Map<String, dynamic>? pendingPlan}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onLoginSuccess: () {
            Navigator.of(context).pop();
            widget.onAuthenticated(pendingPlan: pendingPlan);
          },
        ),
      ),
    );
  }

  void _openRegister({Map<String, dynamic>? pendingPlan}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          onRegisterSuccess: () {
            Navigator.of(context).pop();
            widget.onAuthenticated(pendingPlan: pendingPlan);
          },
        ),
      ),
    );
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
    final grouped = (_data?['plans_grouped'] as Map<String, dynamic>? ?? {});
    final regions = sortRegionsActiveFirst(grouped);
    final plans = sortPlansActiveFirst(grouped[_selectedRegion] as List<dynamic>? ?? []);
    final feeCash = (_data?['fee_cash_to_crypto'] ?? '5%–11%').toString();
    final feeCrypto = (_data?['fee_crypto_to_cash'] ?? '3%–7%').toString();
    final tgUrl = (_data?['support_telegram_url'] ?? 'https://t.me/Paddyitsupport').toString();
    final buyFabTitle = (_data?['it_support_title'] ?? 'BUY PLAN').toString();
    final buyFabSubtitle = (_data?['it_support_subtitle'] ??
            'For more information, please contact @mrmantelo')
        .toString();
    final buyFabUrl =
        (_data?['it_support_url'] ?? 'https://t.me/mrmantelo').toString();

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: TelegramBuyPlanFab(
        title: buyFabTitle,
        subtitle: buyFabSubtitle,
        url: buyFabUrl,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.irishGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sleek Sticky Top Bar with compact Login button
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.irishGreenDeep,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Center(
                      child: Text('☘️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paddyusdt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Row(
                        children: [
                          PulseDot(size: 6),
                          SizedBox(width: 5),
                          Text(
                            'Live Plans',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Currency Converter',
                  icon: const Icon(Icons.currency_exchange, size: 20),
                  onPressed: _openConverter,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: InkWell(
                      onTap: () => _openLogin(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login, size: 15, color: AppColors.ink),
                            SizedBox(width: 5),
                            Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Animated Emerald & Gold Hero Banner
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, child) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.irishGreenDeep,
                        Color.lerp(
                          AppColors.irishGreen,
                          const Color(0xFF007D47),
                          _glowCtrl.value,
                        )!,
                        const Color(0xFF063B24),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                        delayMs: 40,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.goldLight.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            '✨ Trusted Crypto Exchange & Weekly Yield',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FadeSlideIn(
                        delayMs: 100,
                        child: Text(
                          'Smart Crypto Plans.\nWeekly Returns.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delayMs: 160,
                        child: Text(
                          'Browse live investment plans across Ireland, Spain, Dubai, Los Angeles & VIP — synced directly with Paddyusdt.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delayMs: 220,
                        child: Row(
                          children: [
                            _heroStat('Weekly', 'Auto Profit'),
                            const SizedBox(width: 8),
                            _heroStat('On-Chain', 'USDT / USDC'),
                            const SizedBox(width: 8),
                            _heroStat('Instant', 'Withdrawals'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading / Error / Plans Content
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.irishGreen),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              // Region Tabs Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Investment Plans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${plans.length} plan${plans.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.irishGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Wrapped Region Selector — all regions visible, zero cutoff
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: RegionSelector(
                    regions: regions,
                    selectedRegion: _selectedRegion,
                    plansGrouped: grouped,
                    onSelected: (r) => setState(() => _selectedRegion = r),
                  ),
                ),
              ),

              // Live Plan Cards with Staggered Animation
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                sliver: SliverList.builder(
                  itemCount: plans.length,
                  itemBuilder: (_, i) {
                    final p = plans[i] as Map<String, dynamic>;
                    return FadeSlideIn(
                      key: ValueKey('${_selectedRegion}_${p['id']}'),
                      delayMs: (i * 70).clamp(0, 350),
                      child: _PlanShowcaseCard(
                        plan: p,
                        isVip: _selectedRegion.toLowerCase().contains('vip'),
                        onInvestTap: () => _openLogin(pendingPlan: p),
                      ),
                    );
                  },
                ),
              ),

              // Exchange & Quick Tools Footer Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                  child: Column(
                    children: [
                      // Cash <-> Crypto Exchange Highlight
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.ink, AppColors.irishGreenDeep],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.swap_horiz, color: AppColors.goldLight),
                                SizedBox(width: 8),
                                Text(
                                  'Cash ↔ Crypto Exchange',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cash → Crypto: $feeCash   ·   Crypto → Cash: $feeCrypto',
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _openRegister(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.goldLight,
                                      foregroundColor: AppColors.ink,
                                    ),
                                    child: const Text('Create Free Account'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () => launchUrl(
                                    Uri.parse(tgUrl),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Icon(Icons.support_agent, size: 20),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String top, String bottom) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              top,
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              bottom,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanShowcaseCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isVip;
  final VoidCallback onInvestTap;

  const _PlanShowcaseCard({
    required this.plan,
    required this.isVip,
    required this.onInvestTap,
  });

  @override
  Widget build(BuildContext context) {
    final investable = plan['investable'] == true;
    final name = (plan['name'] ?? 'Investment Plan').toString();
    final amount = (plan['amount'] as num? ?? 0).toDouble();
    final unit = (plan['unit'] ?? 'USDT').toString();
    final pct = (plan['weekly_return_percent'] as num? ?? 0).toDouble();
    final weeklyProfit = (plan['weekly_profit'] as num? ?? (amount * pct / 100)).toDouble();
    final monthlyEst = (plan['monthly_est_profit'] as num? ?? (weeklyProfit * 4)).toDouble();
    final blockReason = (plan['block_reason'] ?? 'Coming Soon').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: isVip
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF141E18), Color(0xFF0A2E1D), Color(0xFF3E3010)],
              )
            : null,
        color: isVip ? null : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isVip
              ? AppColors.goldLight.withValues(alpha: 0.55)
              : AppColors.irishGreen.withValues(alpha: 0.12),
          width: isVip ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isVip ? AppColors.goldDark : AppColors.irishGreenDeep)
                .withValues(alpha: 0.09),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isVip ? Colors.white : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${amount.toStringAsFixed(0)} $unit',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isVip ? AppColors.goldLight : AppColors.irishGreen,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isVip
                          ? [AppColors.goldLight, AppColors.gold]
                          : [AppColors.irishGreen, AppColors.emerald],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 1)}% / wk',
                    style: TextStyle(
                      color: isVip ? AppColors.ink : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.mist,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Profit',
                          style: TextStyle(
                            fontSize: 11,
                            color: isVip
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.muted,
                          ),
                        ),
                        Text(
                          '+${weeklyProfit.toStringAsFixed(2)} $unit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isVip ? AppColors.goldLight : AppColors.irishGreenDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Est. 4 Weeks',
                          style: TextStyle(
                            fontSize: 11,
                            color: isVip
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.goldDark,
                          ),
                        ),
                        Text(
                          '+${monthlyEst.toStringAsFixed(2)} $unit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isVip ? Colors.white : AppColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: investable ? onInvestTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: !investable
                      ? Colors.grey.shade300
                      : (isVip ? AppColors.goldLight : AppColors.irishGreen),
                  foregroundColor: !investable
                      ? Colors.grey.shade600
                      : (isVip ? AppColors.ink : Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        investable
                            ? 'Buy Plan & Start Earning'
                            : (blockReason.toLowerCase().contains('sold out')
                                ? 'Sold Out'
                                : (blockReason.toLowerCase().contains('coming soon')
                                    ? 'Coming Soon'
                                    : blockReason)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (investable) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
