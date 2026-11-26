import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// Smooth staggered fade + upward slide entrance animation.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 22,
    this.duration = const Duration(milliseconds: 480),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delayMs == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Smooth count-up currency display for balances & profits.
class AnimatedUsdtText extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String suffix;

  const AnimatedUsdtText({
    super.key,
    required this.value,
    required this.style,
    this.suffix = ' USDT',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutExpo,
      builder: (_, v, __) =>
          Text('${v.toStringAsFixed(2)}$suffix', style: style),
    );
  }
}

/// Live breathing status dot.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({
    super.key,
    this.color = AppColors.emeraldSoft,
    this.size = 8,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 0.85 + (_ctrl.value * 0.35);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.65 * _ctrl.value),
                blurRadius: 6 * scale,
                spreadRadius: 1.5 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

String regionEmoji(String region) {
  final r = region.toLowerCase();
  if (r.contains('ireland')) return '🇮🇪';
  if (r.contains('spain')) return '🇪🇸';
  if (r.contains('dubai') || r.contains('uae')) return '🇦🇪';
  if (r.contains('los angeles') || r.contains('usa')) return '🇺🇸';
  if (r.contains('uk') || r.contains('united kingdom')) return '🇬🇧';
  if (r.contains('vip')) return '👑';
  return '☘️';
}

/// Returns true if a region has at least one currently investable (active) plan.
bool regionHasActivePlan(Map<String, dynamic> plansGrouped, String region) {
  final list = plansGrouped[region] as List<dynamic>? ?? const [];
  return list.any((p) => p is Map && p['investable'] == true);
}

/// Orders regions so regions with active/buyable plans appear FIRST,
/// and sold-out / coming-soon regions appear AFTER.
List<String> sortRegionsActiveFirst(Map<String, dynamic> plansGrouped) {
  final active = <String>[];
  final inactive = <String>[];
  for (final r in plansGrouped.keys) {
    if (regionHasActivePlan(plansGrouped, r)) {
      active.add(r);
    } else {
      inactive.add(r);
    }
  }
  return [...active, ...inactive];
}

/// Orders plans within a region so investable plans appear before sold-out/soon plans.
List<dynamic> sortPlansActiveFirst(List<dynamic> plans) {
  final active = <dynamic>[];
  final inactive = <dynamic>[];
  for (final p in plans) {
    if (p is Map && p['investable'] == true) {
      active.add(p);
    } else {
      inactive.add(p);
    }
  }
  return [...active, ...inactive];
}

/// Beautiful wrapped region selector — all regions always visible, zero cutoff.
class RegionSelector extends StatelessWidget {
  final List<String> regions;
  final String selectedRegion;
  final Map<String, dynamic> plansGrouped;
  final ValueChanged<String> onSelected;

  const RegionSelector({
    super.key,
    required this.regions,
    required this.selectedRegion,
    required this.plansGrouped,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.irishGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.irishGreenDeep.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: regions.map((r) {
          final sel = r == selectedRegion;
          final isVip = r.toLowerCase().contains('vip');
          final isActiveRegion = regionHasActivePlan(plansGrouped, r);
          final count = (plansGrouped[r] as List<dynamic>? ?? []).length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: sel
                  ? LinearGradient(
                      colors: isVip
                          ? [const Color(0xFF1A1A1A), AppColors.goldDark]
                          : [AppColors.irishGreenDeep, AppColors.irishGreen],
                    )
                  : null,
              color: sel
                  ? null
                  : (isVip
                        ? const Color(0xFFFFFBEB)
                        : (isActiveRegion
                              ? AppColors.bg
                              : Colors.grey.shade100)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel
                    ? (isVip ? AppColors.goldLight : AppColors.irishGreen)
                    : (isVip
                          ? AppColors.gold.withValues(alpha: 0.45)
                          : (isActiveRegion
                                ? AppColors.irishGreen.withValues(alpha: 0.25)
                                : Colors.grey.shade300)),
                width: sel ? 1.2 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color:
                            (isVip ? AppColors.goldDark : AppColors.irishGreen)
                                .withValues(alpha: 0.24),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(regionEmoji(r), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      r,
                      style: TextStyle(
                        color: sel
                            ? Colors.white
                            : (isVip
                                  ? AppColors.goldDark
                                  : (isActiveRegion
                                        ? AppColors.ink
                                        : AppColors.muted)),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.white.withValues(alpha: 0.22)
                            : (isVip
                                  ? AppColors.gold.withValues(alpha: 0.18)
                                  : (isActiveRegion
                                        ? AppColors.irishGreen.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.grey.shade200)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: sel
                              ? Colors.white
                              : (isVip
                                    ? AppColors.goldDark
                                    : (isActiveRegion
                                          ? AppColors.irishGreen
                                          : AppColors.muted)),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Shared bottom-sheet frame: never taller than the visible screen, scrolls when
/// content is long, lifts above the keyboard and clears the phone's navigation bar.
class SheetFrame extends StatelessWidget {
  final Widget child;
  final double radius;

  const SheetFrame({super.key, required this.child, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final navBar = mq.viewPadding.bottom;
    final maxHeight = mq.size.height - mq.viewPadding.top - keyboard - 12;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24 + (keyboard > 0 ? 0 : navBar),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Live Currency Converter Bottom Sheet backed by /api/mobile/rates.
class CurrencyConverterSheet extends StatefulWidget {
  const CurrencyConverterSheet({super.key});

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  final _amtCtrl = TextEditingController(text: '1000');
  Map<String, double> _rates = {
    'EUR': 1.0,
    'USD': 1.08,
    'GBP': 0.85,
    'AED': 3.97,
  };
  String _from = 'USD';
  String _to = 'EUR';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    try {
      final res = await ApiClient.instance.get('rates');
      final data = res['data'] as Map<String, dynamic>?;
      final rawRates = data?['rates'] as Map<String, dynamic>?;
      if (rawRates != null && rawRates.isNotEmpty && mounted) {
        final parsed = <String, double>{'EUR': 1.0};
        rawRates.forEach((k, v) {
          if (v is num) parsed[k.toString().toUpperCase()] = v.toDouble();
        });
        setState(() {
          _rates = parsed;
          if (!_rates.containsKey(_from)) _from = _rates.keys.first;
          if (!_rates.containsKey(_to)) _to = 'EUR';
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double get _converted {
    final amt = double.tryParse(_amtCtrl.text.trim()) ?? 0;
    final fromRate = _rates[_from] ?? 1.0;
    final toRate = _rates[_to] ?? 1.0;
    if (fromRate <= 0) return 0;
    return (amt / fromRate) * toRate;
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _rates.keys.toList()..sort();

    return SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.currency_exchange, color: AppColors.irishGreen),
              SizedBox(width: 8),
              Text(
                'Live Currency Converter',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _from,
                    decoration: const InputDecoration(labelText: 'From'),
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _from = v ?? _from),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        final tmp = _from;
                        _from = _to;
                        _to = tmp;
                      });
                    },
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: AppColors.irishGreen,
                    ),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _to,
                    decoration: const InputDecoration(labelText: 'To'),
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _to = v ?? _to),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.irishGreenDeep, AppColors.irishGreen],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Converted Amount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_converted.toStringAsFixed(2)} $_to',
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Website-matching Telegram quick buttons: "Buy Now" + "24/7 Help".
class TelegramQuickRow extends StatelessWidget {
  final String buyUrl;
  final String buyHandle;
  final String helpUrl;
  final String helpLabel;

  const TelegramQuickRow({
    super.key,
    required this.buyUrl,
    required this.buyHandle,
    required this.helpUrl,
    required this.helpLabel,
  });

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _open(buyUrl),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0088CC),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0088CC).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buy Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          buyHandle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _open(helpUrl),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.irishGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.irishGreen.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helpLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Telegram 24×7',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact, sleek floating bottom-right Telegram button ("Buy Plan Support").
class TelegramBuyPlanFab extends StatelessWidget {
  final String title;
  final String subtitle;
  final String url;

  const TelegramBuyPlanFab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shadowColor: const Color(0xFF0088CC).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0088CC), Color(0xFF006EA6)],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 15),
              SizedBox(width: 7),
              Text(
                'Buy Plan Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
