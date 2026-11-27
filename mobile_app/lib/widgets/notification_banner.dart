import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/notification_center.dart';
import '../theme/notification_style.dart';

/// Animated, gradient "toast" that drops from the top of the screen.
/// Swipe up or tap the X to dismiss; tap the card to open the inbox.
class NotificationBanner {
  static OverlayEntry? _entry;

  static void show(OverlayState overlay, AppNotification n, {VoidCallback? onTap}) {
    dismiss();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerView(
        notification: n,
        onTap: onTap,
        onClosed: () {
          if (_entry == entry) _entry = null;
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    final e = _entry;
    _entry = null;
    try {
      e?.remove();
    } catch (_) {}
  }
}

class _BannerView extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback onClosed;

  const _BannerView({required this.notification, required this.onClosed, this.onTap});

  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  Timer? _auto;
  bool _closing = false;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _in.forward();
    _auto = Timer(const Duration(seconds: 7), _close);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _auto?.cancel();
    await _in.animateBack(0, duration: const Duration(milliseconds: 280), curve: Curves.easeIn);
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final s = notifStyleFor(n.type);
    final slide = Tween<Offset>(begin: const Offset(0, -1.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _in, curve: Curves.elasticOut, reverseCurve: Curves.easeIn));

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SlideTransition(
            position: slide,
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: GestureDetector(
                onVerticalDragUpdate: (d) => setState(() => _drag = math.min(0, _drag + d.delta.dy)),
                onVerticalDragEnd: (d) {
                  if (_drag < -24 || (d.primaryVelocity ?? 0) < -300) {
                    _close();
                  } else {
                    setState(() => _drag = 0);
                  }
                },
                onTap: () {
                  widget.onTap?.call();
                  _close();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [s.color, s.deep],
                      ),
                      border: Border.all(color: const Color(0xFFFFE08A).withValues(alpha: 0.55), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: s.color.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 1, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // shimmer sweep + sparkles
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _loop,
                              builder: (_, __) => CustomPaint(
                                painter: _ShinePainter(_loop.value, s.sparkle),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _IconBubble(style: s, pulse: _loop),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              s.label.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Paddyusdt  •  now',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.75),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        n.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                      ),
                                      if (n.message.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          n.message,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.92),
                                            fontSize: 13,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: _close,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.close_rounded, size: 18, color: Colors.white.withValues(alpha: 0.8)),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final NotifStyle style;
  final Animation<double> pulse;

  const _IconBubble({required this.style, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final t = (math.sin(pulse.value * 2 * math.pi) + 1) / 2; // 0..1
        return SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 46 + 8 * t,
                height: 46 + 8 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16 * (1 - t) + 0.05),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF3C4), Color(0xFFF0C040)],
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.6), blurRadius: 10),
                  ],
                ),
                child: Transform.rotate(
                  angle: math.sin(pulse.value * 2 * math.pi) * 0.12,
                  child: Icon(style.icon, color: style.deep, size: 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Diagonal light sweep + (optional) rising golden sparkles.
class _ShinePainter extends CustomPainter {
  final double t;
  final bool sparkle;

  _ShinePainter(this.t, this.sparkle);

  @override
  void paint(Canvas canvas, Size size) {
    // shine sweep
    final x = (t * 1.6 - 0.3) * size.width;
    final rect = Rect.fromLTWH(x - 40, 0, 80, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.save();
    canvas.drawRect(rect, paint);
    canvas.restore();

    if (!sparkle) return;
    final star = Paint()..color = const Color(0xFFFFE08A);
    for (var i = 0; i < 7; i++) {
      final p = (t + i / 7) % 1.0;
      final dx = size.width * (0.18 + 0.7 * ((i * 37) % 100) / 100);
      final dy = size.height * (1.05 - p * 1.1);
      final r = 1.2 + (i % 3) * 0.9;
      star.color = const Color(0xFFFFE08A).withValues(alpha: (1 - p) * 0.85);
      canvas.drawCircle(Offset(dx, dy), r, star);
    }
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.t != t || old.sparkle != sparkle;
}
