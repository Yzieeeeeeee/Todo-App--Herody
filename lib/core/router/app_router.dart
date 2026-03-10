import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login.dart';
import '../../features/navigation/presentation/bottom_navigation.dart';
import '../../splash_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import 'package:to_do_app_herody/features/profile/presentation/privacy_policy_screen.dart';
import 'package:to_do_app_herody/features/profile/presentation/rate_app_screen.dart';
import 'package:to_do_app_herody/features/profile/presentation/help_center_screen.dart';

class AppRouter {
  // ✅ KEY FIX: static final — created ONCE, never recreated
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    routes: [
      // ── Splash ─────────────────────────────────────────────
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
        ),
      ),

      // ── Login ───────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      ),

      // ── Signup ──────────────────────────────────────────────
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      ),

      // ── Home ────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BottomNavigation(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
        ),
      ),

      // ── Help Center ───────────────────────────────────────────
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),

      // ── Privacy Policy ──────────────────────────────────────
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      ),

      // ── Rate App ────────────────────────────────────────────
      GoRoute(
        path: '/rate-app',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RateAppScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      ),
    ],

    // ── Error Page ────────────────────────────────────────────
    errorPageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page not found!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
