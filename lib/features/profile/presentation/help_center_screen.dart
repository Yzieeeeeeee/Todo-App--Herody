import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header Image or Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How can we help you?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find answers to common questions below or contact our support team.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
                    Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleSmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqTile(
              context,
              question: 'How do I change the theme?',
              answer:
                  'You can toggle between Dark and Light mode directly from the Profile settings section.',
            ),
            _buildFaqTile(
              context,
              question: 'How do I start a focus session?',
              answer:
                  'Navigate to the Focus tab in the bottom bar, select your desired duration, and tap Start to begin your session.',
            ),
            _buildFaqTile(
              context,
              question: 'Can I reset my password?',
              answer:
                  'Yes, if you forget your password, you can use the "Forgot Password" option on the Login screen to receive a reset link.',
            ),
            _buildFaqTile(
              context,
              question: 'How does the Priority system work?',
              answer:
                  'You can tag tasks as High, Medium, or Low to organize them visually. This helps you identify what to tackle first.',
            ),
            const SizedBox(height: 32),
            // Contact Us Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Contact Support coming soon!',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.email_outlined, color: Colors.white),
                label: Text(
                  'Contact Support',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor:
              Theme.of(context).iconTheme.color?.withValues(alpha: 0.5) ??
              Colors.grey.shade400,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
