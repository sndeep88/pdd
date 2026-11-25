import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Animated launch screen: shamrock pops in, rings pulse, gold sparkles float,
/// brand name + tagline slide in and a loader fills before handing over.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _loop;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _sparks = List.generate(
      26,
      (_) => _Spark(
        x: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        size: 1.5 + rnd.nextDouble() * 3.5,
        speed: 0.5 + rnd.nextDouble() * 0.9,
        drift: (rnd.nextDouble() - 0.5) * 0.12,
      ),
    );

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: int.fromEnvironment('SPLASH_MS', defaultValue: 3000),
      ),
    )..forward().whenComplete(() {
        if (mounted) widget.onFinished();
      });

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  Animation<double> _interval(double a, double b, [Curve curve = Curves.easeOut]) {
    return CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: curve));
  }

  @override
  Widget build(BuildContext context) {
    final logoScale = Tween<double>(begin: 0.3, end: 1).animate(
      _interval(0.0, 0.45, Curves.elasticOut),
    );
    final logoFade = _interval(0.0, 0.2);
    final logoTurn = Tween<double>(begin: -0.12, end: 0).animate(
      _interval(0.0, 0.45, Curves.easeOutCubic),
    );
    final titleAnim = _interval(0.35, 0.65, Curves.easeOutCubic);
    final tagAnim = _interval(0.55, 0.8);
    final loaderAnim = _interval(0.15, 0.95, Curves.easeInOut);
    final exitFade = Tween<double>(begin: 1, end: 0).animate(
      _interval(0.94, 1.0, Curves.easeIn),
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _loop]),
        builder: (context, _) {
          final screen = MediaQuery.of(context).size;
          final size = Size(math.min(screen.width, screen.height * 0.55), screen.height);
          return Opacity(
            opacity: exitFade.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF003D1F),
                    AppColors.irishGreen,
                    Color(0xFF004D2C),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Soft glow behind the logo.
                  Align(
                    alignment: const Alignment(0, -0.18),
                    child: Container(
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.22 * logoFade.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating gold sparkles.
                  CustomPaint(
                    painter: _SparkPainter(_sparks, _loop.value, logoFade.value),
                  ),
                  // Pulse rings.
                  Align(
                    alignment: const Alignment(0, -0.18),
                    child: CustomPaint(
                      size: Size.square(size.width * 0.8),
                      painter: _RingPainter(_loop.value, logoFade.value),
                    ),
                  ),
                  // Logo.
                  Align(
                    alignment: const Alignment(0, -0.18),
                    child: Opacity(
                      opacity: logoFade.value,
                      child: Transform.rotate(
                        angle: logoTurn.value * math.pi,
                        child: Transform.scale(
                          scale: logoScale.value *
                              (1 + 0.03 * math.sin(_loop.value * 2 * math.pi)),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                  blurRadius: 50,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/shamrock.png',
                              width: size.width * 0.38,
                              height: size.width * 0.38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Brand name + tagline.
                  Align(
                    alignment: const Alignment(0, 0.42),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: titleAnim.value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - titleAnim.value)),
                            child: ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                colors: [
                                  AppColors.goldLight,
                                  AppColors.gold,
                                  AppColors.goldLight,
                                ],
                              ).createShader(rect),
                              child: Text(
                                'Paddyusdt',
                                style: GoogleFonts.outfit(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1 + 3 * (1 - titleAnim.value),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: tagAnim.value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - tagAnim.value)),
                            child: Text(
                              'Invest smart  •  Earn every week',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.6,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Loader.
                  Align(
                    alignment: const Alignment(0, 0.82),
                    child: Opacity(
                      opacity: tagAnim.value,
                      child: SizedBox(
                        width: 120,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(color: Colors.white.withValues(alpha: 0.16)),
                              FractionallySizedBox(
                                widthFactor: loaderAnim.value,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.goldDark, AppColors.goldLight],
                                    ),
                                  ),
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
            ),
          );
        },
      ),
    );
  }
}

class _Spark {
  _Spark({
    required this.x,
    required this.phase,
    required this.size,
    required this.speed,
    required this.drift,
  });

  final double x;
  final double phase;
  final double size;
  final double speed;
  final double drift;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.sparks, this.t, this.visibility);

  final List<_Spark> sparks;
  final double t;
  final double visibility;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final p = (t * s.speed + s.phase) % 1.0;
      final y = size.height * (1.05 - p * 1.1);
      final x = size.width * (s.x + s.drift * math.sin(p * 2 * math.pi));
      final fade = math.sin(p * math.pi).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.7 * fade * visibility)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.size * 0.7);
      canvas.drawCircle(Offset(x, y), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.t != t || old.visibility != visibility;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.visibility);

  final double t;
  final double visibility;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final p = (t * 1.5 + i / 3) % 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.gold.withValues(alpha: 0.35 * (1 - p) * visibility);
      canvas.drawCircle(center, maxR * (0.35 + 0.65 * p), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.t != t || old.visibility != visibility;
}
