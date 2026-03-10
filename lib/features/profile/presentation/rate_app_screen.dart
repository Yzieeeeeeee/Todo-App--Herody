import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  late AnimationController _entryController;
  late AnimationController _starsController;
  late AnimationController _successController;

  // ── State ─────────────────────────────────────────────────────
  int _selectedRating = 0;
  int _hoveredRating = 0;
  bool _showFeedbackBox = false;
  bool _showSuccess = false;
  bool _isSubmitting = false;
  bool _alreadyRated = false;
  int _previousRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  // ── Firestore ─────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Star data ─────────────────────────────────────────────────
  final List<String> _starEmojis = ['😞', '😕', '😐', '😊', '🤩'];
  final List<String> _starLabels = [
    'Terrible',
    'Poor',
    'Okay',
    'Good',
    'Amazing!'
  ];
  final List<List<Color>> _starGradients = [
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFF6C63FF), Color(0xFF4F46E5)],
  ];

  // ── Average rating from Firestore ─────────────────────────────
  double _averageRating = 0.0;
  int _totalRatings = 0;
  Map<int, int> _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadRatingData();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _starsController.dispose();
    _successController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // ── Load existing rating + stats from Firestore ───────────────
  Future<void> _loadRatingData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Load this user's rating
      final userRatingDoc =
      await _firestore.collection('ratings').doc(uid).get();
      if (userRatingDoc.exists) {
        final data = userRatingDoc.data()!;
        setState(() {
          _alreadyRated = true;
          _selectedRating = (data['rating'] as num).toInt();
          _previousRating = _selectedRating;
          _showFeedbackBox = _selectedRating <= 3;
          if (data['feedback'] != null) {
            _feedbackController.text = data['feedback'];
          }
        });
      }

      // Load overall stats
      await _loadStats();
    } catch (e) {
      debugPrint('Error loading rating: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final statsDoc =
      await _firestore.collection('app_stats').doc('ratings').get();
      if (statsDoc.exists) {
        final data = statsDoc.data()!;
        setState(() {
          _averageRating = (data['average'] as num?)?.toDouble() ?? 0.0;
          _totalRatings = (data['total'] as num?)?.toInt() ?? 0;
          final dist = data['distribution'] as Map<String, dynamic>? ?? {};
          _ratingDistribution = {
            1: (dist['1'] as num?)?.toInt() ?? 0,
            2: (dist['2'] as num?)?.toInt() ?? 0,
            3: (dist['3'] as num?)?.toInt() ?? 0,
            4: (dist['4'] as num?)?.toInt() ?? 0,
            5: (dist['5'] as num?)?.toInt() ?? 0,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  // ── Submit rating to Firestore ────────────────────────────────
  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;

    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;
    final name = _auth.currentUser?.displayName;
    if (uid == null) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final batch = _firestore.batch();

      // ── Save user's individual rating ────────────────────────
      final userRatingRef = _firestore.collection('ratings').doc(uid);
      batch.set(userRatingRef, {
        'uid': uid,
        'email': email ?? '',
        'name': name ?? 'Anonymous',
        'rating': _selectedRating,
        'feedback': _feedbackController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': _alreadyRated
            ? FieldValue.serverTimestamp()
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ── Update aggregate stats ───────────────────────────────
      final statsRef =
      _firestore.collection('app_stats').doc('ratings');
      final statsDoc = await statsRef.get();

      if (!statsDoc.exists) {
        // First ever rating
        batch.set(statsRef, {
          'total': 1,
          'sum': _selectedRating,
          'average': _selectedRating.toDouble(),
          'distribution': {
            '1': 0,
            '2': 0,
            '3': 0,
            '4': 0,
            '5': 0,
            '$_selectedRating': 1,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final statsData = statsDoc.data()!;
        int total = (statsData['total'] as num).toInt();
        int sum = (statsData['sum'] as num).toInt();
        final dist =
        Map<String, dynamic>.from(statsData['distribution'] ?? {});

        if (_alreadyRated && _previousRating != _selectedRating) {
          // Update existing rating — adjust sum and distribution
          sum = sum - _previousRating + _selectedRating;
          dist['$_previousRating'] =
              ((dist['$_previousRating'] as num?)?.toInt() ?? 1) - 1;
          dist['$_selectedRating'] =
              ((dist['$_selectedRating'] as num?)?.toInt() ?? 0) + 1;
        } else if (!_alreadyRated) {
          // New rating
          total = total + 1;
          sum = sum + _selectedRating;
          dist['$_selectedRating'] =
              ((dist['$_selectedRating'] as num?)?.toInt() ?? 0) + 1;
        }

        batch.update(statsRef, {
          'total': total,
          'sum': sum,
          'average': total > 0 ? sum / total : 0.0,
          'distribution': dist,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _alreadyRated = true;
        _previousRating = _selectedRating;
      });

      _successController.forward();
      await _loadStats();
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('Submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit. Please try again.',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(start, end, curve: Curves.easeIn),
      ));

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: _showSuccess ? _buildSuccessScreen() : _buildRatingScreen(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RATING SCREEN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRatingScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [

          // ── Header ───────────────────────────────────────────
          FadeTransition(
            opacity: _fade(0.0, 0.4),
            child: SlideTransition(
              position: _slide(0.0, 0.4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF59E0B),
                      Color(0xFFF97316),
                      Color(0xFFEF4444),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pop();
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
                        if (_alreadyRated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '✓ You rated this',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Animated star icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (ctx, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      _alreadyRated ? 'Update Your Rating' : 'Rate Todo',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _alreadyRated
                          ? 'You previously rated us $_previousRating stars'
                          : 'How are you enjoying the app?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Community Stats ───────────────────────────────────
          if (_totalRatings > 0) ...[
            FadeTransition(
              opacity: _fade(0.2, 0.55),
              child: SlideTransition(
                position: _slide(0.2, 0.55),
                child: _buildStatsCard(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Stars Section ─────────────────────────────────────
          FadeTransition(
            opacity: _fade(0.3, 0.65),
            child: SlideTransition(
              position: _slide(0.3, 0.65),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    Text(
                      'Tap to rate',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Star Row ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starNum = i + 1;
                        final isSelected = starNum <=
                            (_hoveredRating > 0
                                ? _hoveredRating
                                : _selectedRating);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedRating = starNum;
                              _showFeedbackBox = starNum <= 3;
                              if (!_showFeedbackBox) {
                                _feedbackController.clear();
                              }
                            });
                            _starsController
                              ..reset()
                              ..forward();
                          },
                          onTapDown: (_) =>
                              setState(() => _hoveredRating = starNum),
                          onTapUp: (_) =>
                              setState(() => _hoveredRating = 0),
                          onTapCancel: () =>
                              setState(() => _hoveredRating = 0),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('star_${starNum}_$isSelected'),
                            tween: Tween(
                                begin: isSelected ? 0.7 : 1.0,
                                end: 1.0),
                            duration:
                            const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            builder: (ctx, scale, child) =>
                                Transform.scale(
                                    scale: scale, child: child),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                isSelected
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 48,
                                color: isSelected
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // ── Emoji + Label ─────────────────────────
                    if (_selectedRating > 0) ...[
                      TweenAnimationBuilder<double>(
                        key: ValueKey(_selectedRating),
                        tween: Tween(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (ctx, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Column(
                          children: [
                            Text(
                              _starEmojis[_selectedRating - 1],
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _starGradients[
                                  _selectedRating - 1],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _starLabels[_selectedRating - 1],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        '⭐⭐⭐⭐⭐',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Feedback Box (rating ≤ 3) ─────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: _showFeedbackBox
                ? Padding(
              padding: const EdgeInsets.only(top: 20),
              child: FadeTransition(
                opacity: _fade(0.5, 0.9),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFFEE2E2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
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
                              color: const Color(0xFFFFEDED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.feedback_outlined,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What went wrong?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  'Help us improve TaskFlow',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Quick reason chips ────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Too many bugs',
                          'Hard to use',
                          'Missing features',
                          'Slow performance',
                          'Sync issues',
                          'Other',
                        ].map((reason) {
                          final selected = _feedbackController.text
                              .contains(reason);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final current =
                                  _feedbackController.text;
                              if (selected) {
                                _feedbackController.text = current
                                    .replaceAll(reason, '')
                                    .replaceAll('  ', ' ')
                                    .trim();
                              } else {
                                _feedbackController.text =
                                current.isEmpty
                                    ? reason
                                    : '$current, $reason';
                              }
                              setState(() {});
                            },
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFFFF1F1),
                                borderRadius:
                                BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                reason,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // ── Text area ─────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFFECACA)),
                        ),
                        child: TextField(
                          controller: _feedbackController,
                          maxLines: 4,
                          maxLength: 300,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF374151),
                          ),
                          decoration: InputDecoration(
                            hintText:
                            'Tell us more about your experience...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                            counterStyle: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 28),

          // ── Submit + Next Time buttons ────────────────────────
          FadeTransition(
            opacity: _fade(0.6, 1.0),
            child: Column(
              children: [
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedRating == 0 || _isSubmitting
                        ? null
                        : _submitRating,
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
                        gradient: _selectedRating == 0
                            ? null
                            : LinearGradient(
                          colors: _selectedRating > 0
                              ? _starGradients[_selectedRating - 1]
                              : [
                            Colors.grey.shade300,
                            Colors.grey.shade300
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              _alreadyRated
                                  ? Icons.update_rounded
                                  : Icons.send_rounded,
                              color: _selectedRating == 0
                                  ? Colors.grey.shade400
                                  : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _alreadyRated
                                  ? 'Update Rating'
                                  : 'Submit Rating',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _selectedRating == 0
                                    ? Colors.grey.shade400
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Next time button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Maybe Next Time',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
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

  // ═══════════════════════════════════════════════════════════════
  //  COMMUNITY STATS CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Community Ratings',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Big average
              Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _averageRating),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (ctx, val, _) => Text(
                      val.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                        height: 1,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < _averageRating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalRatings ratings',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // Distribution bars
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = _ratingDistribution[star] ?? 0;
                    final pct = _totalRatings > 0
                        ? count / _totalRatings
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 10),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: pct),
                                duration: Duration(
                                    milliseconds: 800 + (i * 100)),
                                curve: Curves.easeOutCubic,
                                builder: (ctx, val, _) =>
                                    LinearProgressIndicator(
                                      value: val,
                                      backgroundColor:
                                      Colors.grey.shade100,
                                      valueColor:
                                      const AlwaysStoppedAnimation(
                                        Color(0xFFF59E0B),
                                      ),
                                      minHeight: 6,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUCCESS SCREEN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSuccessScreen() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _successController, curve: Curves.easeIn),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ── Animated checkmark ──────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (ctx, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedRating > 0
                        ? _starGradients[_selectedRating - 1]
                        : [
                      const Color(0xFF6C63FF),
                      const Color(0xFF3B82F6)
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_selectedRating > 0
                          ? _starGradients[_selectedRating - 1][0]
                          : const Color(0xFF6C63FF))
                          .withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Emoji ─────────────────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (ctx, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                _selectedRating > 0
                    ? _starEmojis[_selectedRating - 1]
                    : '🎉',
                style: const TextStyle(fontSize: 64),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _selectedRating >= 4
                  ? 'Thank You! 🎉'
                  : 'Feedback Received!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _selectedRating >= 4
                    ? 'We\'re so happy you\'re enjoying TaskFlow! Your rating helps others discover the app. We\'ll keep working hard to make it even better for you.'
                    : 'Thank you for your honest feedback. We take every review seriously and your input helps us improve. We\'re already working on making things better!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Stars display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (i * 100)),
                  curve: Curves.elasticOut,
                  builder: (ctx, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      i < _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 36,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Updated stats
            if (_totalRatings > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEE2A0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$_totalRatings people rated • avg ${_averageRating.toStringAsFixed(1)} ⭐',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'Back to Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
