import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "PaddyPay" teaser: a coming-soon announcement for the upcoming PaddyPay card.
class PaddyPayTab extends StatefulWidget {
  const PaddyPayTab({super.key});

  @override
  State<PaddyPayTab> createState() => _PaddyPayTabState();
}

class _PaddyPayTabState extends State<PaddyPayTab>
    with TickerProviderStateMixin {
  static const _neon = Color(0xFF39FF88);

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // Manual tilt while the user drags the card (radians).
  double _tiltX = 0;
  double _tiltY = 0;
  double _fromX = 0;
  double _fromY = 0;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() {
      final k = Curves.elasticOut.transform(_settle.value);
      setState(() {
        _tiltX = _fromX * (1 - k);
        _tiltY = _fromY * (1 - k);
      });
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _loop.dispose();
    _settle.dispose();
    super.dispose();
  }

  Widget _reveal(double start, double end, Widget child) {
    final anim = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020A06), Color(0xFF04271A), Color(0xFF020A06)],
        ),
      ),
      child: Stack(
        children: [
          // ambient glows + drifting particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) =>
                  CustomPaint(painter: _AmbientPainter(_loop.value)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                children: [
                  _reveal(0.0, 0.4, _header()),
                  const SizedBox(height: 26),
                  _reveal(0.1, 0.65, _heroCard()),
                  const SizedBox(height: 30),
                  _reveal(0.35, 0.8, _headline()),
                  const SizedBox(height: 24),
                  _reveal(0.5, 0.95, _features()),
                  const SizedBox(height: 26),
                  _reveal(0.65, 1.0, _footer()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39FF88), Color(0xFF00A651)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _neon.withValues(alpha: 0.5),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF021A0F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PaddyPay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ComingSoonPill(controller: _loop),
      ],
    );
  }

  // ------------------------------------------------------------------ card

  Widget _heroCard() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return GestureDetector(
          onPanStart: (_) => _settle.stop(),
          onPanUpdate: (d) {
            setState(() {
              _tiltY = (_tiltY + d.delta.dx * 0.012).clamp(-0.5, 0.5);
              _tiltX = (_tiltX - d.delta.dy * 0.012).clamp(-0.5, 0.5);
            });
          },
          onPanEnd: (_) {
            _fromX = _tiltX;
            _fromY = _tiltY;
            _settle.forward(from: 0);
          },
          child: AnimatedBuilder(
            animation: _loop,
            builder: (_, __) {
              final t = _loop.value * 2 * math.pi;
              final floatY = math.sin(t) * 7;
              final swayY = math.sin(t) * 0.10;
              final swayX = math.cos(t) * 0.04;
              final glow = 0.45 + 0.2 * math.sin(t * 2);
              return Transform.translate(
                offset: Offset(0, floatY),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // glow plate
                    Container(
                      width: w * 0.86,
                      height: w * 0.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _neon.withValues(alpha: glow * 0.55),
                            blurRadius: 60,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFF00A651,
                            ).withValues(alpha: glow * 0.5),
                            blurRadius: 90,
                            spreadRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateX(_tiltX + swayX)
                        ..rotateY(_tiltY + swayY),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(w * 0.045),
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/images/paddy_card.jpg',
                              width: w,
                              fit: BoxFit.fitWidth,
                              filterQuality: FilterQuality.high,
                            ),
                            // moving light reflection
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _ShinePainter(_loop.value, _tiltY),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------- headline

  Widget _headline() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Colors.white, Color(0xFF8CFFBC), Color(0xFFFFE08A)],
          ).createShader(r),
          child: const Text(
            'Spend your crypto\nlike cash. Anywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Meet the PaddyPay Card, the smartest way to turn your USDT earnings into everyday '
          'spending. Tap, swipe and shop worldwide, powered by your Paddyusdt wallet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- features

  Widget _features() {
    const items = [
      (
        Icons.public_rounded,
        'Spend Worldwide',
        'Pay at millions of stores and online merchants.',
      ),
      (
        Icons.flash_on_rounded,
        'Instant Top-Up',
        'Fund your card straight from your wallet.',
      ),
      (
        Icons.verified_user_rounded,
        'Bank-Grade Security',
        'Protected with 2FA and smart safeguards.',
      ),
      (
        Icons.tune_rounded,
        'Total Control',
        'Freeze, unfreeze and manage limits in a tap.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final f in items)
              SizedBox(
                width: w,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: _neon.withValues(alpha: 0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              _neon.withValues(alpha: 0.32),
                              _neon.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: Icon(f.$1, color: _neon, size: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        f.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.$3,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- footer

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE8C547).withValues(alpha: 0.22),
            const Color(0xFFE8C547).withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFE8C547).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: Color(0xFFFFE08A),
            size: 26,
          ),
          const SizedBox(height: 8),
          const Text(
            'Something big is on the way',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'PaddyPay is launching soon. Keep notifications on and we will alert you the moment it goes live.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================ small widgets

class _ComingSoonPill extends StatelessWidget {
  final Animation<double> controller;

  const _ComingSoonPill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (math.sin(controller.value * 2 * math.pi * 3) + 1) / 2;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE08A), Color(0xFFE8C547)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8C547).withValues(alpha: 0.3 + 0.3 * t),
                blurRadius: 10 + 8 * t,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFF7A5C0A),
                    const Color(0xFF00A651),
                    t,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'COMING SOON',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Soft green glows and tiny drifting dots behind everything.
class _AmbientPainter extends CustomPainter {
  final double t;

  _AmbientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset c, double r, Color color) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    final a = t * 2 * math.pi;
    glow(
      Offset(size.width * (0.2 + 0.05 * math.sin(a)), size.height * 0.18),
      size.width * 0.7,
      const Color(0xFF00A651).withValues(alpha: 0.28),
    );
    glow(
      Offset(size.width * (0.85 - 0.05 * math.cos(a)), size.height * 0.62),
      size.width * 0.65,
      const Color(0xFF39FF88).withValues(alpha: 0.12),
    );

    final dot = Paint();
    for (var i = 0; i < 22; i++) {
      final p = (t + i / 22) % 1.0;
      final x = size.width * (((i * 53) % 100) / 100);
      final y = size.height * (1.02 - p * 1.05);
      final r = 0.8 + (i % 3) * 0.6;
      dot.color = const Color(
        0xFF8CFFBC,
      ).withValues(alpha: math.sin(p * math.pi) * 0.55);
      canvas.drawCircle(Offset(x, y), r, dot);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.t != t;
}

/// Diagonal light band sliding over the card (also reacts to tilt).
class _ShinePainter extends CustomPainter {
  final double t;
  final double tilt;

  _ShinePainter(this.t, this.tilt);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = (t * 1.0 + tilt * 0.6) % 1.0;
    final x = (phase * 1.8 - 0.4) * size.width;
    final rect = Rect.fromLTWH(
      x - size.width * 0.18,
      0,
      size.width * 0.36,
      size.height,
    );
    canvas.save();
    canvas.translate(x, 0);
    canvas.skew(-0.35, 0);
    canvas.translate(-x, 0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.t != t || old.tilt != tilt;
}
