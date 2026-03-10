import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app_herody/core/responsive.dart';
import 'package:to_do_app_herody/features/auth/presentation/auth_provider.dart';
import 'package:to_do_app_herody/features/tasks/presentation/task_provider.dart';
import 'package:to_do_app_herody/core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ─────────────────────────────────────
  late AnimationController _entryController;
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _pulseController;

  late Animation<double> _headerScale;
  late Animation<double> _avatarScale;
  late Animation<double> _pulseAnim;

  // ── Settings State ────────────────────────────────────────────
  bool _appLockOnFocus = false;
  bool _notificationsEnabled = true;
  bool _dailyReminder = false;
  bool _soundEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  // ── Stats Animation ───────────────────────────────────────────
  late AnimationController _counterController;
  late Animation<double> _counterAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _counterAnim = CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    );

    // Delay stats animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _statsController.forward();
        _counterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _headerController.dispose();
    _statsController.dispose();
    _pulseController.dispose();
    _counterController.dispose();
    super.dispose();
  }

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
    Offset begin = const Offset(0, 0.3),
  }) => Tween<Offset>(begin: begin, end: Offset.zero).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ),
  );

  // ── Logout ────────────────────────────────────────────────────
  void _handleLogout() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => _buildDialog(
        icon: Icons.logout_rounded,
        iconColor: Colors.red.shade400,
        iconBg: Colors.red.shade50,
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        confirmLabel: 'Logout',
        confirmColor: Colors.red.shade400,
        onConfirm: () async {
          Navigator.pop(ctx);
          await context.read<AuthProvider>().signOut();
          context.read<TaskProvider>().clear();
          if (mounted) context.go('/login');
        },
      ),
    );
  }

  // ── App Lock Focus Dialog ─────────────────────────────────────
  void _showAppLockInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFFB923C)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Focus App Lock',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'When enabled, the app will prevent you from leaving the Focus screen during an active focus session. This helps you stay on track and avoid distractions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Feature list
            ...[
              ('Blocks back navigation during focus', Icons.block_rounded),
              (
                'Shows warning if you try to leave',
                Icons.warning_amber_rounded,
              ),
              ('Auto unlocks when timer ends', Icons.lock_open_rounded),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.$2,
                        color: const Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Toggle inside sheet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _appLockOnFocus
                    ? const Color(0xFFFFEDED)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _appLockOnFocus
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _appLockOnFocus
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    color: _appLockOnFocus
                        ? const Color(0xFFEF4444)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appLockOnFocus ? 'Lock Enabled' : 'Lock Disabled',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _appLockOnFocus
                                ? const Color(0xFFEF4444)
                                : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          _appLockOnFocus
                              ? 'Focus sessions are protected'
                              : 'Tap to enable focus protection',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _appLockOnFocus,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      setState(() => _appLockOnFocus = val);
                      Navigator.pop(ctx);
                      _showToast(
                        val
                            ? '🔒 Focus Lock Enabled'
                            : '🔓 Focus Lock Disabled',
                      );
                    },
                    activeColor: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Daily Reminder Time Picker ────────────────────────────────
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      _showToast('⏰ Reminder set for ${picked.format(context)}');
    }
  }

  // ── Toast ─────────────────────────────────────────────────────
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Reusable Dialog ───────────────────────────────────────────
  Widget _buildDialog({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final hPad = Responsive.horizontalPadding(context);
    final contentBottom = Responsive.contentBottomPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Responsive.centeredContent(
          context: context,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, contentBottom),
            child: Column(
              children: [
                // ── Hero Header ────────────────────────────────
                ScaleTransition(
                  scale: _headerScale,
                  child: FadeTransition(
                    opacity: _fade(0.0, 0.4),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6C63FF),
                            Color(0xFF3B82F6),
                            Color(0xFF06B6D4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Avatar with pulse ──────────────
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (ctx, child) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: child,
                            ),
                            child: ScaleTransition(
                              scale: _avatarScale,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.6),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: auth.userPhoto != null
                                        ? ClipOval(
                                            child: Image.network(
                                              auth.userPhoto!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              (auth.userName?.isNotEmpty ==
                                                      true)
                                                  ? auth.userName![0]
                                                        .toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),

                                  // Online dot
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            auth.userName ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              auth.userEmail ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Mini Stats Row inside header ──
                          Row(
                            children: [
                              _miniStat('${tasks.totalTasks}', 'Total'),
                              _verticalDivider(),
                              _miniStat('${tasks.completedCount}', 'Done'),
                              _verticalDivider(),
                              _miniStat('${tasks.pendingCount}', 'Pending'),
                              _verticalDivider(),
                              _miniStat(
                                '${(tasks.completionPercentage * 100).toInt()}%',
                                'Progress',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Animated Stats Cards ───────────────────────
                FadeTransition(
                  opacity: _fade(0.25, 0.6),
                  child: SlideTransition(
                    position: _slide(0.25, 0.6),
                    child: Row(
                      children: [
                        _statCard(
                          value: tasks.totalTasks,
                          label: 'Total Tasks',
                          icon: Icons.task_alt_rounded,
                          gradientColors: [
                            const Color(0xFF6C63FF),
                            const Color(0xFF9F97FF),
                          ],
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          value: tasks.completedCount,
                          label: 'Completed',
                          icon: Icons.check_circle_rounded,
                          gradientColors: [
                            const Color(0xFF10B981),
                            const Color(0xFF34D399),
                          ],
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          value: tasks.pendingCount,
                          label: 'Pending',
                          icon: Icons.pending_actions_rounded,
                          gradientColors: [
                            const Color(0xFFF59E0B),
                            const Color(0xFFFBBF24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Progress Card ──────────────────────────────
                FadeTransition(
                  opacity: _fade(0.35, 0.7),
                  child: SlideTransition(
                    position: _slide(0.35, 0.7),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEDFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.trending_up_rounded,
                                  color: Color(0xFF6C63FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Overall Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              AnimatedBuilder(
                                animation: _counterAnim,
                                builder: (ctx, _) => Text(
                                  '${(_counterAnim.value * tasks.completionPercentage * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: tasks.completionPercentage,
                              ),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF6C63FF),
                                    ),
                                    minHeight: 10,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tasks.totalTasks == 0
                                ? 'Add your first task to get started!'
                                : '${tasks.completedCount} of ${tasks.totalTasks} tasks completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Focus Settings ─────────────────────────────
                FadeTransition(
                  opacity: _fade(0.45, 0.8),
                  child: SlideTransition(
                    position: _slide(0.45, 0.8),
                    child: _sectionCard(
                      title: 'Focus Settings',
                      icon: Icons.timer_rounded,
                      iconColor: const Color(0xFFEF4444),
                      children: [
                        _toggleTile(
                          icon: Icons.lock_clock_rounded,
                          iconColor: const Color(0xFFEF4444),
                          iconBg: const Color(0xFFFFEDED),
                          title: 'App Lock on Focus',
                          subtitle: _appLockOnFocus
                              ? 'Blocks distractions during focus'
                              : 'Tap info to learn more',
                          value: _appLockOnFocus,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _appLockOnFocus = val);
                            _showToast(
                              val
                                  ? '🔒 Focus Lock Enabled'
                                  : '🔓 Focus Lock Disabled',
                            );
                          },
                          trailing: GestureDetector(
                            onTap: _showAppLockInfo,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF6C63FF),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        _divider(),
                        _toggleTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBg: const Color(0xFFEFF6FF),
                          title: 'Focus Sounds',
                          subtitle: 'Play sound when timer ends',
                          value: _soundEnabled,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _soundEnabled = val);
                            _showToast(
                              val ? '🔊 Sound enabled' : '🔇 Sound disabled',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Notifications ──────────────────────────────
                FadeTransition(
                  opacity: _fade(0.5, 0.85),
                  child: SlideTransition(
                    position: _slide(0.5, 0.85),
                    child: _sectionCard(
                      title: 'Notifications',
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFF6C63FF),
                      children: [
                        _toggleTile(
                          icon: Icons.notifications_active_rounded,
                          iconColor: const Color(0xFF6C63FF),
                          iconBg: const Color(0xFFEEEDFF),
                          title: 'Push Notifications',
                          subtitle: 'Task reminders and updates',
                          value: _notificationsEnabled,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _notificationsEnabled = val);
                            _showToast(
                              val
                                  ? '🔔 Notifications on'
                                  : '🔕 Notifications off',
                            );
                          },
                        ),
                        _divider(),
                        _toggleTile(
                          icon: Icons.alarm_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFFFF8E7),
                          title: 'Daily Reminder',
                          subtitle: _dailyReminder
                              ? 'Reminds at ${_reminderTime.format(context)}'
                              : 'Get a daily task nudge',
                          value: _dailyReminder,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _dailyReminder = val);
                            if (val) _pickReminderTime();
                          },
                        ),
                        if (_dailyReminder) ...[
                          _divider(),
                          _actionTile(
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            iconBg: const Color(0xFFFFF8E7),
                            title: 'Reminder Time',
                            subtitle: _reminderTime.format(context),
                            onTap: _pickReminderTime,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Appearance ─────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.55, 0.9),
                  child: SlideTransition(
                    position: _slide(0.55, 0.9),
                    child: _sectionCard(
                      title: 'Appearance',
                      icon: Icons.palette_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      children: [
                        _toggleTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF1F2937),
                          iconBg: const Color(0xFFF3F4F6),
                          title: 'Dark Mode',
                          subtitle: 'Easy on the eyes at night',
                          value: themeProvider.isDarkMode,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            themeProvider.toggleTheme(val);
                            _showToast(
                              val
                                  ? '🌙 Dark mode enabled'
                                  : '☀️ Light mode enabled',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Account Section ────────────────────────────
                FadeTransition(
                  opacity: _fade(0.6, 0.95),
                  child: SlideTransition(
                    position: _slide(0.6, 0.95),
                    child: _sectionCard(
                      title: 'Account',
                      icon: Icons.manage_accounts_rounded,
                      iconColor: const Color(0xFF10B981),
                      children: [
                        _actionTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFE8FDF5),
                          title: 'Privacy Policy',
                          subtitle: 'How we use your data',
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        _divider(),
                        _actionTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          iconBg: const Color(0xFFEFF6FF),
                          title: 'Help & Support',
                          subtitle: 'Get assistance anytime',
                          onTap: () => context.push('/help-center'),
                        ),
                        _divider(),
                        _actionTile(
                          icon: Icons.star_outline_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFFFF8E7),
                          title: 'Rate the App',
                          subtitle: 'Love TODO? Let us know!',
                          onTap: () => context.push('/rate-app'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Logout Button ──────────────────────────────
                FadeTransition(
                  opacity: _fade(0.75, 1.0),
                  child: SlideTransition(
                    position: _slide(0.75, 1.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade400,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: Colors.red.shade100,
                              width: 1.5,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Version ────────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.85, 1.0),
                  child: Text(
                    'Todo v2.5.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
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

  // ── Mini stat inside header ───────────────────────────────────
  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() =>
      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2));

  // ── Animated stat card ────────────────────────────────────────
  Widget _statCard({
    required int value,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _counterAnim,
              builder: (ctx, _) => Text(
                '${(_counterAnim.value * value).toInt()}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: gradientColors[0],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Card ──────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Toggle Tile ───────────────────────────────────────────────
  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing, const SizedBox(width: 6)],
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Tile ───────────────────────────────────────────────
  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 70,
    endIndent: 16,
    color: Colors.grey.shade100,
  );
}
