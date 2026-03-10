import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app_herody/core/responsive.dart';
import 'package:to_do_app_herody/core/providers/notification_provider.dart';
import '../../tasks/presentation/home_screen.dart';
import '../../tasks/presentation/focus_page.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<AnimationController> _iconControllers;
  late AnimationController _indicatorController;

  final List<Widget> _pages = [
    const HomeScreen(),
    const FocusScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      gradientColors: [Color(0xFF6C63FF), Color(0xFF9F97FF)],
      bgColor: Color(0xFFEEEDFF),
    ),
    _NavItem(
      icon: Icons.timer_outlined,
      activeIcon: Icons.timer_rounded,
      label: 'Focus',
      gradientColors: [Color(0xFFEF4444), Color(0xFFFB923C)],
      bgColor: Color(0xFFFFEDED),
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      bgColor: Color(0xFFFFF8E7),
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
      bgColor: Color(0xFFE8FDF5),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _iconControllers = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _iconControllers[0].forward();
    _indicatorController.forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.lightImpact();

    _iconControllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _iconControllers[index].forward();

    _indicatorController.reset();
    _indicatorController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.03, 0),
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
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final unread = context.watch<NotificationProvider>().unreadCount;
    final isWide = Responsive.isWide(context);

    // Adaptive bottom padding — respects the device's home indicator / safe area
    final bottomPad = Responsive.navBottomPadding(context);

    // On wide screens the pill is centred with a max-width
    final navBar = Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
      child: Container(
        height: isWide ? 76 : 68,
        decoration: BoxDecoration(
          color:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _navItems.length,
              (index) => Expanded(
                child: index == 2
                    ? _buildNavItemWithBadge(index, unread)
                    : _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );

    // On wide screens, centre the bar with a max-width
    if (isWide) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: navBar,
        ),
      );
    }

    return navBar;
  }

  // ── Standard nav item ─────────────────────────────────────────
  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;
    final controller = _iconControllers[index];

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final bounce = Tween<double>(begin: 1.0, end: 1.18).evaluate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut),
          );

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon Pill ──────────────────────────────────
                Transform.scale(
                  scale: bounce,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 18 : 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: item.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: item.gradientColors[0].withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            key: ValueKey<bool>(isSelected),
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).unselectedWidgetColor,
                            size: 22,
                          ),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            fontWeight: FontWeight.w700,
                            fontSize: isSelected ? 12 : 0,
                            letterSpacing: 0.3,
                          ),
                          child: isSelected
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(item.label),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Dot Indicator ─────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    color: item.gradientColors[0],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Notifications tab with badge ──────────────────────────────
  Widget _buildNavItemWithBadge(int index, int unread) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;
    final controller = _iconControllers[index];

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final bounce = Tween<double>(begin: 1.0, end: 1.18).evaluate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut),
          );

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon Pill + badge ──────────────────────────
                Transform.scale(
                  scale: bounce,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 18 : 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: item.gradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: item.gradientColors[0].withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                key: ValueKey<bool>(isSelected),
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).unselectedWidgetColor,
                                size: 22,
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: isSelected
                                  ? Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      // ── Unread badge ────────────────────────
                      if (unread > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            scale: 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 17,
                                minHeight: 17,
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Dot Indicator ─────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    color: item.gradientColors[0],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Nav Item Model ─────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final List<Color> gradientColors;
  final Color bgColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradientColors,
    required this.bgColor,
  });
}
