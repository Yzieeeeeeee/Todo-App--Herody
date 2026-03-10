import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  late AnimationController _lottieController;
  late AnimationController _uiController;

  // ── UI Animations ─────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _loaderFade;
  late Animation<double> _dotAnim1;
  late Animation<double> _dotAnim2;
  late Animation<double> _dotAnim3;

  @override
  void initState() {
    super.initState();

    // ── Lottie controller ─────────────────────────────────────
    _lottieController = AnimationController(vsync: this);

    // ── Main UI animation controller ──────────────────────────
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // ── Background fade ───────────────────────────────────────
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // ── Lottie card scale + fade ──────────────────────────────
    _cardScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.1, 0.55, curve: Curves.elasticOut),
      ),
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
      ),
    );

    // ── Title slide + fade ────────────────────────────────────
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _uiController,
            curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.4, 0.65, curve: Curves.easeIn),
      ),
    );

    // ── Subtitle ──────────────────────────────────────────────
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _uiController,
            curve: const Interval(0.5, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.5, 0.72, curve: Curves.easeIn),
      ),
    );

    // ── Tagline ───────────────────────────────────────────────
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.62, 0.85, curve: Curves.easeIn),
      ),
    );

    // ── Loader ────────────────────────────────────────────────
    _loaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── Dot bounce animations (staggered) ─────────────────────
    _dotAnim1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.78, 1.0, curve: Curves.elasticOut),
      ),
    );
    _dotAnim2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.82, 1.0, curve: Curves.elasticOut),
      ),
    );
    _dotAnim3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _uiController,
        curve: const Interval(0.86, 1.0, curve: Curves.elasticOut),
      ),
    );

    // ── Start animations ──────────────────────────────────────
    _uiController.forward();

    // ── Navigate after 2.2 seconds ──────────────────────────────
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _uiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1035), // Deep purple-black
                Color(0xFF2D1B69), // Rich purple
                Color(0xFF1E3A5F), // Deep blue
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Decorative blobs ──────────────────────────
              Positioned(
                top: -100,
                right: -80,
                child: _blob(220, const Color(0xFF6C63FF), 0.12),
              ),
              Positioned(
                top: size.height * 0.2,
                left: -60,
                child: _blob(160, const Color(0xFF3B82F6), 0.10),
              ),
              Positioned(
                bottom: -120,
                right: -60,
                child: _blob(260, const Color(0xFF06B6D4), 0.08),
              ),
              Positioned(
                bottom: size.height * 0.2,
                left: size.width * 0.3,
                child: _blob(100, const Color(0xFFA78BFA), 0.08),
              ),

              // ── Grid dots pattern ─────────────────────────
              Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

              // ── Main Content ───────────────────────────────
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // ── Lottie Card ────────────────────────
                    ScaleTransition(
                      scale: _cardScale,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Container(
                          width: size.width * 0.52,
                          height: size.width * 0.52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF6C63FF).withValues(alpha: 0.25),
                                const Color(0xFF3B82F6).withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withValues(alpha: 0.35),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Lottie.asset(
                              'lottie/splashscreen.json',
                              controller: _lottieController,
                              fit: BoxFit.contain,
                              onLoaded: (composition) {
                                _lottieController
                                  ..duration = composition.duration
                                  ..repeat();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── App Name ───────────────────────────
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFB8B5FF),
                              Color(0xFF7DD3FC),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'To do',
                            style: GoogleFonts.poppins(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.0,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Badge ──────────────────────────────
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '✦  Smart Task Manager',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tagline ────────────────────────────
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Organise · Focus · Achieve',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // ── Loading dots ───────────────────────
                    FadeTransition(
                      opacity: _loaderFade,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _bounceDot(_dotAnim1, const Color(0xFF6C63FF)),
                              const SizedBox(width: 8),
                              _bounceDot(_dotAnim2, const Color(0xFF3B82F6)),
                              const SizedBox(width: 8),
                              _bounceDot(_dotAnim3, const Color(0xFF06B6D4)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Getting things ready...',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Version ────────────────────────────
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'v1.0.0',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.2),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Blob decoration ───────────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  // ── Bounce dot ────────────────────────────────────────────────
  Widget _bounceDot(Animation<double> anim, Color color) {
    return ScaleTransition(
      scale: anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot grid background painter ───────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const dotRadius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}
