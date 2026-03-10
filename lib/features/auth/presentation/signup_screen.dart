import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app_herody/features/auth/presentation/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Staggered animation helpers ──────────────────────────────
  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  // ── Sign Up Handler ──────────────────────────────────────────
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().signUp(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
    );

    if (success && mounted) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Account created successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // TODO: Replace with → context.go('/home');
      context.go('/home');
      ;
    }
  }

  // ── Google Sign Up ───────────────────────────────────────────
  Future<void> _handleGoogleSignUp() async {
    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().signInWithGoogle();

    if (success && mounted) {
      context.go('/login');
      ;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🎨 Same gradient — consistent design
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6), Color(0xFF06B6D4)],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 36),

                // ── Back Button + Title ───────────────────────
                FadeTransition(
                  opacity: _fade(0.0, 0.4),
                  child: SlideTransition(
                    position: _slide(0.0, 0.4),
                    child: Column(
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign up to start organising your tasks',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── White Card Form ───────────────────────────
                FadeTransition(
                  opacity: _fade(0.25, 0.75),
                  child: SlideTransition(
                    position: _slide(0.25, 0.75),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Error Banner ─────────────────
                            if (authProvider.errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authProvider.errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── Full Name ─────────────────────
                            Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) =>
                                  context.read<AuthProvider>().clearError(),
                              decoration: _inputDecoration(
                                hint: 'John Doe',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                if (val.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // ── Email ─────────────────────────
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) =>
                                  context.read<AuthProvider>().clearError(),
                              decoration: _inputDecoration(
                                hint: 'you@example.com',
                                icon: Icons.email_outlined,
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$',
                                ).hasMatch(val)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // ── Password ──────────────────────
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) =>
                                  context.read<AuthProvider>().clearError(),
                              decoration: _inputDecoration(
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color:
                                        Theme.of(
                                          context,
                                        ).iconTheme.color?.withOpacity(0.5) ??
                                        Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (val.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                if (!RegExp(r'[0-9]').hasMatch(val)) {
                                  return 'Include at least one number';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // ── Confirm Password ──────────────
                            Text(
                              'Confirm Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              onChanged: (_) =>
                                  context.read<AuthProvider>().clearError(),
                              decoration: _inputDecoration(
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color:
                                        Theme.of(
                                          context,
                                        ).iconTheme.color?.withOpacity(0.5) ??
                                        Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 28),

                            // ── Sign Up Button ────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Divider ───────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.6) ??
                                          Colors.grey.shade400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── Google Button ─────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleGoogleSignUp,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
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
                ),

                const SizedBox(height: 28),

                // ── Login Link ────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.6, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable Input Decoration ─────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color:
            Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ??
            Colors.grey.shade400,
      ),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      suffixIcon: suffix,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
