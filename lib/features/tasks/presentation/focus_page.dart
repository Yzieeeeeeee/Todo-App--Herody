import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:to_do_app_herody/core/responsive.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  // ── Timer State ───────────────────────────────────────────────
  Timer? _timer;
  int _selectedMinutes = 25; // Default focus time
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isFinished = false;

  // ── Animations ────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _pulseAnim;

  final List<int> _presets = [5, 10, 15, 25, 30, 45, 60];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _remainingSeconds = _selectedMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Timer Controls ────────────────────────────────────────────
  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isFinished = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _onTimerFinished();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _onTimerFinished() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = true;
      _remainingSeconds = 0;
    });
    _showFinishedDialog();
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isFinished = false;
    });
  }

  // ── Format time MM:SS ─────────────────────────────────────────
  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ── Progress 0.0 → 1.0 ───────────────────────────────────────
  double get _progress {
    final total = _selectedMinutes * 60;
    if (total == 0) return 0;
    return 1 - (_remainingSeconds / total);
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Focus Complete! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great job! You focused for $_selectedMinutes minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
                    Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = Responsive.horizontalPadding(context);
    final contentBottom = Responsive.contentBottomPadding(context);
    // Cap the timer circle so it doesn't overflow tiny or huge screens
    final timerSize = min(size.width * 0.68, 300.0);
    final innerSize = min(size.width * 0.55, 240.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Responsive.centeredContent(
          context: context,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 24, hPad, contentBottom),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.0, 0.4),
                  child: SlideTransition(
                    position: _slide(0.0, 0.4),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Focus Mode',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stay focused, get things done.',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.6) ??
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.timer_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Circular Timer ───────────────────────────────
                FadeTransition(
                  opacity: _fade(0.2, 0.6),
                  child: SlideTransition(
                    position: _slide(0.2, 0.6),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Transform.scale(
                          scale: _isRunning ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: SizedBox(
                          width: timerSize,
                          height: timerSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // ── Outer glow ring ──────────────
                              Container(
                                width: timerSize,
                                height: timerSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(
                                        alpha: _isRunning ? 0.15 : 0.05,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),

                              // ── Progress Ring ─────────────────
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: _progress),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, _) => CustomPaint(
                                  size: Size(timerSize, timerSize),
                                  painter: _CircularProgressPainter(
                                    progress: value,
                                    isRunning: _isRunning,
                                  ),
                                ),
                              ),

                              // ── Inner Circle ──────────────────
                              Container(
                                width: innerSize,
                                height: innerSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).shadowColor.withValues(alpha: 0.06),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Time display — shrink font on small phones
                                    Text(
                                      _formattedTime,
                                      style: TextStyle(
                                        fontSize:
                                            Responsive.isMobile(context) &&
                                                size.width < 360
                                            ? 36
                                            : 48,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.color,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isFinished
                                          ? 'Complete! 🎉'
                                          : _isRunning
                                          ? 'Focusing...'
                                          : 'Ready',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isRunning
                                            ? const Color(0xFFEF4444)
                                            : (Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color
                                                      ?.withValues(
                                                        alpha: 0.6,
                                                      ) ??
                                                  Colors.grey.shade400),
                                        fontWeight: FontWeight.w600,
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

                const SizedBox(height: 36),

                // ── Control Buttons ──────────────────────────────
                FadeTransition(
                  opacity: _fade(0.4, 0.8),
                  child: SlideTransition(
                    position: _slide(0.4, 0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset Button
                        _controlButton(
                          icon: Icons.replay_rounded,
                          color:
                              Theme.of(
                                context,
                              ).iconTheme.color?.withValues(alpha: 0.5) ??
                              Colors.grey.shade400,
                          bgColor: Theme.of(context).cardColor,
                          size: 52,
                          onTap: _resetTimer,
                        ),

                        const SizedBox(width: 20),

                        // Play/Pause Button — main CTA
                        GestureDetector(
                          onTap: _isRunning ? _pauseTimer : _startTimer,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isRunning
                                    ? [
                                        const Color(0xFFF59E0B),
                                        const Color(0xFFEF4444),
                                      ]
                                    : [
                                        const Color(0xFFEF4444),
                                        const Color(0xFFF59E0B),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                key: ValueKey<bool>(_isRunning),
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Skip Button
                        _controlButton(
                          icon: Icons.skip_next_rounded,
                          color:
                              Theme.of(
                                context,
                              ).iconTheme.color?.withValues(alpha: 0.5) ??
                              Colors.grey.shade400,
                          bgColor: Theme.of(context).cardColor,
                          size: 52,
                          onTap: _onTimerFinished,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Preset Times ─────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.6, 1.0),
                  child: SlideTransition(
                    position: _slide(0.6, 1.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Focus Duration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(
                              context,
                            ).textTheme.titleSmall?.color,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _presets.map((minutes) {
                            final isSelected = _selectedMinutes == minutes;
                            return GestureDetector(
                              onTap: () => _selectPreset(minutes),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFF59E0B),
                                          ],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Theme.of(context).shadowColor
                                                .withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  '$minutes min',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).unselectedWidgetColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Focus Tips Card ───────────────────────────────
                FadeTransition(
                  opacity: _fade(0.7, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pomodoro Technique',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Work for 25 mins, then take a 5 min break for best results.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// ── Custom Circular Progress Painter ─────────────────────────────
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isRunning;

  _CircularProgressPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;
    const startAngle = -1.5708; // -90 degrees (top)

    // ── Background track ──────────────────────────────────────
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Progress arc ──────────────────────────────────────────
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * 3.14159 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.isRunning != isRunning;
}
