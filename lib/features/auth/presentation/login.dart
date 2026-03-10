import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app_herody/features/auth/presentation/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  late AnimationController _entryController;
  late AnimationController _lottieController;
  late AnimationController _shakeController;

  // ── Form ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _lottieController = AnimationController(vsync: this);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _lottieController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Animation helpers ─────────────────────────────────────────
  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );

  Animation<Offset> _slide(
    double start,
    double end, {
    Offset from = const Offset(0, 0.25),
  }) => Tween<Offset>(begin: from, end: Offset.zero).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ),
  );

  // ── Shake animation for error ─────────────────────────────────
  Animation<double> get _shakeAnim => Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
  );

  void _triggerShake() {
    _shakeController.reset();
    _shakeController.forward();
    HapticFeedback.mediumImpact();
  }

  // ── Login ─────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _triggerShake();
      return;
    }
    context.read<AuthProvider>().clearError();
    HapticFeedback.lightImpact();

    final success = await context.read<AuthProvider>().loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go('/home');
    } else {
      _triggerShake();
    }
  }

  // ── Google Sign In ────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    context.read<AuthProvider>().clearError();
    HapticFeedback.lightImpact();

    final success = await context.read<AuthProvider>().signInWithGoogle();
    if (success && mounted) context.go('/home');
  }

  // ── Forgot Password ───────────────────────────────────────────
  void _handleForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reset Password',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your email and we'll send you a reset link.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: GoogleFonts.poppins(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6) ??
                      Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color:
                            Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                            Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailCtrl.text.isNotEmpty) {
                        Navigator.pop(ctx);
                        final success = await context
                            .read<AuthProvider>()
                            .sendPasswordResetEmail(emailCtrl.text);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reset link sent! Check your email.',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: const Color(0xFF6C63FF),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Send Link',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1035), Color(0xFF2D1B69), Color(0xFF1E3A5F)],
          ),
        ),
        child: Stack(
          children: [
            // ── Blob decorations ───────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: _blob(200, const Color(0xFF6C63FF), 0.15),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _blob(220, const Color(0xFF3B82F6), 0.10),
            ),

            // ── Main scroll content ────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Lottie Animation ───────────────────
                    FadeTransition(
                      opacity: _fade(0.0, 0.45),
                      child: SlideTransition(
                        position: _slide(
                          0.0,
                          0.45,
                          from: const Offset(0, -0.2),
                        ),
                        child: _buildLottieSection(size),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Title block ────────────────────────
                    FadeTransition(
                      opacity: _fade(0.2, 0.55),
                      child: SlideTransition(
                        position: _slide(0.2, 0.55),
                        child: _buildTitleBlock(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Form card ──────────────────────────
                    FadeTransition(
                      opacity: _fade(0.35, 0.75),
                      child: SlideTransition(
                        position: _slide(0.35, 0.75),
                        child: AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (ctx, child) => Transform.translate(
                            offset: Offset(
                              _shakeController.isAnimating
                                  ? 8 * Math.sin(_shakeAnim.value * 3 * 3.14159)
                                  : 0,
                              0,
                            ),
                            child: child,
                          ),
                          child: _buildFormCard(auth),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Sign up link ───────────────────────
                    FadeTransition(
                      opacity: _fade(0.65, 1.0),
                      child: _buildSignupLink(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LOTTIE SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildLottieSection(Size size) {
    return SizedBox(
      height: size.height * 0.26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Glow behind lottie ───────────────────────
          Container(
            width: size.width * 0.7,
            height: size.height * 0.22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.25),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // ── Lottie ───────────────────────────────────
          Lottie.asset(
            'lottie/Welcome.json',
            controller: _lottieController,
            fit: BoxFit.contain,
            width: size.width * 0.82,
            onLoaded: (composition) {
              _lottieController
                ..duration = composition.duration
                ..repeat();
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TITLE BLOCK
  // ─────────────────────────────────────────────────────────────
  Widget _buildTitleBlock() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFB8B5FF), Color(0xFF7DD3FC)],
          ).createShader(bounds),
          child: Text(
            'Welcome Back!',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '✦  Sign in to TaskFlow',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FORM CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildFormCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Error banner ─────────────────────────────
            if (auth.errorMessage != null) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                builder: (ctx, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, -10 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Email ────────────────────────────────────
            _fieldLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onChanged: (_) => context.read<AuthProvider>().clearError(),
              decoration: _inputDecoration(
                hint: 'you@example.com',
                icon: Icons.email_outlined,
              ),
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please enter your email';
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(val))
                  return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 18),

            // ── Password ──────────────────────────────────
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onChanged: (_) => context.read<AuthProvider>().clearError(),
              decoration: _inputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                suffix: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color:
                        Theme.of(
                          context,
                        ).iconTheme.color?.withValues(alpha: 0.5) ??
                        Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please enter your password';
                if (val.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 10),

            // ── Forgot password ───────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Login button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey.shade200,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: auth.isLoading
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: auth.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.login_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── OR divider ────────────────────────────────
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Google button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).textTheme.titleSmall?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SIGNUP LINK
  // ─────────────────────────────────────────────────────────────
  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/signup');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Sign Up',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(opacity),
    ),
  );

  Widget _fieldLabel(String label) => Text(
    label,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).textTheme.titleSmall?.color,
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}

// ── Math helper ───────────────────────────────────────────────────
class Math {
  static double sin(double x) {
    // Simple sine approximation for shake
    double result = 0;
    double term = x;
    for (int i = 0; i < 5; i++) {
      result += term;
      term *= -x * x / ((2 * i + 2) * (2 * i + 3));
    }
    return result;
  }
}
