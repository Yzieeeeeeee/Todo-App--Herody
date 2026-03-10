import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        setState(() {
          _scrollProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeIn),
      ));

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));

  // ── Policy Sections Data ──────────────────────────────────────
  final List<_PolicySection> _sections = [
    _PolicySection(
      icon: Icons.info_outline_rounded,
      iconColor: Color(0xFF6C63FF),
      iconBg: Color(0xFFEEEDFF),
      title: 'Information We Collect',
      content:
      'We collect information you provide directly to us when you create an account, such as your name, email address, and password. We also collect task data you create within the app including task titles, descriptions, priorities, and completion status. This data is stored securely in Firebase and is only accessible by you.',
    ),
    _PolicySection(
      icon: Icons.storage_rounded,
      iconColor: Color(0xFF3B82F6),
      iconBg: Color(0xFFEFF6FF),
      title: 'How We Use Your Data',
      content:
      'Your data is used solely to provide and improve the TaskFlow experience. We use your information to: authenticate your identity, sync your tasks across devices, personalise your experience, and provide customer support. We do not sell, rent, or share your personal data with third parties for marketing purposes.',
    ),
    _PolicySection(
      icon: Icons.lock_outline_rounded,
      iconColor: Color(0xFF10B981),
      iconBg: Color(0xFFE8FDF5),
      title: 'Data Security',
      content:
      'We take the security of your data seriously. All data transmitted between your device and our servers is encrypted using industry-standard TLS encryption. Your password is never stored in plain text. We use Firebase Authentication which follows best security practices to keep your account safe.',
    ),
    _PolicySection(
      icon: Icons.share_outlined,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFFF8E7),
      title: 'Data Sharing',
      content:
      'We do not share your personal information with third parties except as necessary to provide our services (such as Firebase by Google for data storage and authentication). These service providers are contractually obligated to protect your data and may not use it for any other purpose.',
    ),
    _PolicySection(
      icon: Icons.cookie_outlined,
      iconColor: Color(0xFFEF4444),
      iconBg: Color(0xFFFFEDED),
      title: 'Cookies & Analytics',
      content:
      'To do may use anonymised analytics to understand how users interact with the app. This data is aggregated and cannot be used to identify you personally. No tracking cookies are used. Analytics data helps us improve app performance, fix bugs, and build better features for you.',
    ),
    _PolicySection(
      icon: Icons.child_care_rounded,
      iconColor: Color(0xFF8B5CF6),
      iconBg: Color(0xFFF5F3FF),
      title: "Children's Privacy",
      content:
      'Todo is not directed at children under the age of 8. We do not knowingly collect personal information from children under 8. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately so we can delete it.',
    ),
    _PolicySection(
      icon: Icons.edit_note_rounded,
      iconColor: Color(0xFF06B6D4),
      iconBg: Color(0xFFECFEFF),
      title: 'Your Rights',
      content:
      'You have the right to access, update, or delete your personal information at any time. You can update your profile information within the app settings. To request deletion of your account and all associated data, please contact us at support@todo.app. We will process your request within 30 days.',
    ),
    _PolicySection(
      icon: Icons.update_rounded,
      iconColor: Color(0xFF6C63FF),
      iconBg: Color(0xFFEEEDFF),
      title: 'Policy Updates',
      content:
      'We may update this Privacy Policy from time to time. We will notify you of any significant changes by sending an email or displaying a prominent notice in the app. Your continued use of TaskFlow after changes become effective constitutes your acceptance of the updated policy.',
    ),
    _PolicySection(
      icon: Icons.contact_mail_outlined,
      iconColor: Color(0xFF10B981),
      iconBg: Color(0xFFE8FDF5),
      title: 'Contact Us',
      content:
      'If you have any questions or concerns about this Privacy Policy or how we handle your data, please contact us at:\n\n📧 support@todo.app\n🌐 https://yzieeeeeeee.github.io/portfolio/\n📍 Todo Inc., Ponnad PO Manannchery, Alappuzha, Kerala, India',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ─────────────────────────────────────────
            FadeTransition(
              opacity: _fade(0.0, 0.4),
              child: SlideTransition(
                position: _slide(0.0, 0.4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF3B82F6),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Back button row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Last updated: Mar 2026',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Icon + Title
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.privacy_tip_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Privacy Policy',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'How we collect, use and protect your data',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Read progress bar ──────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reading progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                '${(_scrollProgress * 100).toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _scrollProgress,
                              backgroundColor:
                              Colors.white.withOpacity(0.25),
                              valueColor: const AlwaysStoppedAnimation(
                                  Colors.white),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sections List ───────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                itemCount: _sections.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == 0) {
                    // Intro card
                    return FadeTransition(
                      opacity: _fade(0.2, 0.6),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF3B82F6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Your privacy matters to us. This policy explains everything clearly and transparently.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final section = _sections[index - 1];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration:
                    Duration(milliseconds: 300 + (index * 60)),
                    curve: Curves.easeOutCubic,
                    builder: (ctx, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: _buildSectionCard(section, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(_PolicySection section, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: section.iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(section.icon, color: section.iconColor, size: 20),
          ),
          title: Text(
            section.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          trailing: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: section.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: section.iconColor,
              size: 18,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: section.iconBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                section.content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────
class _PolicySection {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String content;

  const _PolicySection({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.content,
  });
}