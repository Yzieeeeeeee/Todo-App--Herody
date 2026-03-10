import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app_herody/features/auth/presentation/auth_provider.dart';
import 'package:to_do_app_herody/features/tasks/presentation/task_provider.dart';
import 'package:to_do_app_herody/core/providers/notification_provider.dart';
import 'core/router/app_router.dart';
import 'package:to_do_app_herody/core/theme/theme_provider.dart';
import 'package:to_do_app_herody/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCwe_973qbKxP3rXRX7JLzighDXJujqj8s",
      appId: "1:804933093325:android:e964dfafaab29557eda684",
      messagingSenderId: "804933093325",
      projectId: "to-do-f6e06",
      databaseURL:
          "https://to-do-f6e06-default-rtdb.asia-southeast1.firebasedatabase.app",
    ),
  );

  // ── Init local notifications (channels + timezone) ────────────

  runApp(
    MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // 1. Auth — no dependencies
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. Notification log — no dependencies
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // 3. Tasks — depends on Auth + NotificationProvider
        ChangeNotifierProxyProvider2<
          AuthProvider,
          NotificationProvider,
          TaskProvider
        >(
          create: (_) => TaskProvider(),
          update: (_, authProvider, notifProvider, taskProvider) {
            final provider = taskProvider ?? TaskProvider();

            // Wire notification log into task provider
            provider.setNotifProvider(notifProvider);

            // ✅ microtask stops init() firing mid-build
            if (authProvider.isLoggedIn && authProvider.userId != null) {
              Future.microtask(() => provider.init(authProvider.userId!));
            } else if (!authProvider.isLoggedIn) {
              Future.microtask(() => provider.clear());
            }

            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TaskFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
