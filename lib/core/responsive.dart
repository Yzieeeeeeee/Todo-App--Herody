import 'package:flutter/material.dart';


/// Breakpoints:
///   mobile  → width < 600
///   tablet  → 600 ≤ width < 1024
///   web     → width ≥ 1024
class Responsive {
  // ── Breakpoint booleans ─────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }

  static bool isWeb(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  /// Returns horizontal page padding that scales with screen width.
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return w * 0.18; // web: generous side margins
    if (w >= 600) return w * 0.08; // tablet
    return 20.0; // mobile
  }

  /// EdgeInsets padding for symmetric horizontal use.
  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: horizontalPadding(context));

  // ── Bottom nav padding (accounts for device home indicator) ─────
  /// Bottom padding for the nav bar pill — adds device safe-area bottom
  /// so it floats correctly above the home indicator on any device.
  static double navBottomPadding(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Base gap below the pill
    const base = 14.0;
    return safeBottom > 0 ? safeBottom + 6 : base;
  }

  /// Bottom padding for scrollable content so it clears the floating nav.
  /// 72 = nav bar height, plus the nav's bottom padding, plus a small gap.
  static double contentBottomPadding(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return 72 + navBottomPadding(context) + safeBottom + 16;
  }

  // ── Maximum content width (for web / tablet centering) ──────────
  static double maxContentWidth(BuildContext context) {
    if (isWeb(context)) return 720;
    if (isTablet(context)) return 560;
    return double.infinity;
  }

  /// Wraps [child] in a centred, max-width container for wide screens.
  static Widget centeredContent({
    required BuildContext context,
    required Widget child,
  }) {
    if (!isWide(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: child,
      ),
    );
  }
}
