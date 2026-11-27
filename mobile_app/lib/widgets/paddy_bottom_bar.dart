import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One regular tab of the bar.
class PaddyBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  const PaddyBarItem(this.icon, this.selectedIcon, this.label, this.index);
}

/// Bottom navigation with a glowing PaddyPay button in the exact centre.
/// Tab indexes are independent of the visual order, so existing screens that
/// jump to a tab by index keep working.
class PaddyBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<PaddyBarItem> left;
  final List<PaddyBarItem> right;
  final int centerIndex;

  const PaddyBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.left,
    required this.right,
    required this.centerIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.irishGreen.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(children: [for (final i in left) Expanded(child: _tab(i))]),
              ),
              SizedBox(
                width: 84,
                child: _PayButton(
                  selected: currentIndex == centerIndex,
                  onTap: () => onSelect(centerIndex),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(children: [for (final i in right) Expanded(child: _tab(i))]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(PaddyBarItem item) {
    final selected = currentIndex == item.index;
    return InkResponse(
      onTap: () => onSelect(item.index),
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.mist : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              size: 23,
              color: selected ? AppColors.irishGreen : AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppColors.irishGreen : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayButton extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;

  const _PayButton({required this.selected, required this.onTap});

  @override
  State<_PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends State<_PayButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = (math.sin(_c.value * 2 * math.pi) + 1) / 2;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF10B981), Color(0xFF004D2A), Color(0xFF021A0F)],
                      ),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: widget.selected ? 1 : 0.75),
                        width: widget.selected ? 2.2 : 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.25 + 0.3 * t),
                          blurRadius: 10 + 10 * t,
                          spreadRadius: 1 + 2 * t,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 24),
                  ),
                  Positioned(
                    top: -5,
                    right: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFE8C547)]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                      ),
                      child: const Text(
                        'SOON',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'PaddyPay',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: widget.selected ? AppColors.irishGreen : AppColors.ink,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
