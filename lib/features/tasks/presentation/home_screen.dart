import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app_herody/core/responsive.dart';
import 'package:to_do_app_herody/features/auth/presentation/auth_provider.dart';
import 'package:to_do_app_herody/features/tasks/presentation/task_provider.dart';
import 'package:to_do_app_herody/features/tasks/data/task_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _fabController;

  int _selectedFilter = 0;
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _fabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
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
    Offset from = const Offset(0, 0.12),
  }) => Tween<Offset>(begin: from, end: Offset.zero).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ),
  );

  List<Task> _getFilteredTasks(TaskProvider tp) {
    List<Task> base;
    switch (_selectedFilter) {
      case 1:
        base = tp.pendingTasks;
        break;
      case 2:
        base = tp.completedTasks;
        break;
      default:
        base = tp.tasks;
    }
    if (_searchQuery.isEmpty) return base;
    return base
        .where(
          (t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.description.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  String _motivationalQuote(TaskProvider tp) {
    if (tp.totalTasks == 0) return 'Ready to be productive?';
    if (tp.completionPercentage == 1.0) return '🎉 All tasks done! Amazing!';
    if (tp.completionPercentage >= 0.7) return '🔥 Almost there, keep going!';
    if (tp.completionPercentage >= 0.4) return '💪 Great progress today!';
    return '🚀 Let\'s crush it today!';
  }

  void _showTaskSheet({Task? task}) {
    HapticFeedback.lightImpact();
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    String priority = task?.priority ?? 'medium';
    DateTime? selectedAlarm = task?.alarmTime;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            ctx,
                          ).dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            task == null
                                ? Icons.add_task_rounded
                                : Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task == null ? 'New Task' : 'Edit Task',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  ctx,
                                ).textTheme.titleLarge?.color,
                              ),
                            ),
                            Text(
                              task == null
                                  ? 'What needs to be done?'
                                  : 'Update task details',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _sheetField(
                      controller: titleCtrl,
                      label: 'Task Title',
                      hint: 'e.g. Finish project report',
                      icon: Icons.title_rounded,
                      autofocus: true,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller: descCtrl,
                      label: 'Description (optional)',
                      hint: 'Add notes or details...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Priority Level',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).textTheme.titleSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _priorityChip(
                          'low',
                          '🟢 Low',
                          const Color(0xFF10B981),
                          priority,
                          (p) => setSS(() => priority = p),
                        ),
                        const SizedBox(width: 8),
                        _priorityChip(
                          'medium',
                          '🟡 Medium',
                          const Color(0xFFF59E0B),
                          priority,
                          (p) => setSS(() => priority = p),
                        ),
                        const SizedBox(width: 8),
                        _priorityChip(
                          'high',
                          '🔴 High',
                          const Color(0xFFEF4444),
                          priority,
                          (p) => setSS(() => priority = p),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '⏰ Set Alarm / Reminder',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).textTheme.titleSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedAlarm ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme,
                            ),
                            child: child!,
                          ),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: selectedAlarm != null
                              ? TimeOfDay.fromDateTime(selectedAlarm!)
                              : TimeOfDay.now(),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme,
                            ),
                            child: child!,
                          ),
                        );
                        if (time == null) return;
                        setSS(
                          () => selectedAlarm = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selectedAlarm != null
                              ? Theme.of(
                                  ctx,
                                ).colorScheme.primary.withValues(alpha: 0.07)
                              : Theme.of(ctx).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedAlarm != null
                                ? Theme.of(
                                    ctx,
                                  ).colorScheme.primary.withValues(alpha: 0.4)
                                : Theme.of(
                                    ctx,
                                  ).dividerColor.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedAlarm != null
                                  ? Icons.alarm_on_rounded
                                  : Icons.alarm_add_rounded,
                              color: selectedAlarm != null
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Theme.of(ctx).unselectedWidgetColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedAlarm != null
                                    ? DateFormat(
                                        'EEE, MMM d • h:mm a',
                                      ).format(selectedAlarm!)
                                    : 'Tap to set alarm time',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: selectedAlarm != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selectedAlarm != null
                                      ? Theme.of(ctx).colorScheme.primary
                                      : Theme.of(ctx).unselectedWidgetColor,
                                ),
                              ),
                            ),
                            if (selectedAlarm != null)
                              GestureDetector(
                                onTap: () => setSS(() => selectedAlarm = null),
                                child: Icon(
                                  Icons.close_rounded,
                                  color:
                                      Theme.of(ctx).iconTheme.color?.withValues(
                                        alpha: 0.5,
                                      ) ??
                                      Colors.grey.shade400,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          if (task == null) {
                            await context.read<TaskProvider>().addTask(
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              priority: priority,
                              alarmTime: selectedAlarm,
                            );
                          } else {
                            await context.read<TaskProvider>().updateTask(
                              taskId: task.id,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              priority: priority,
                              alarmTime: selectedAlarm,
                              clearAlarm:
                                  selectedAlarm == null &&
                                  task.alarmTime != null,
                            );
                          }
                          HapticFeedback.mediumImpact();
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  task == null
                                      ? Icons.add_rounded
                                      : Icons.save_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  task == null ? 'Add Task' : 'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String taskId, String title) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Task?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$title" will be permanently removed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
                    Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.1),
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
                            Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6) ??
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
                      Navigator.pop(ctx);
                      await context.read<TaskProvider>().deleteTask(taskId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Task deleted',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red.shade400,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Delete',
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
    final tasks = context.watch<TaskProvider>();
    final filtered = _getFilteredTasks(tasks);
    final hPad = Responsive.horizontalPadding(context);
    final contentBottom = Responsive.contentBottomPadding(context);
    final fabBottom = Responsive.navBottomPadding(context) + 68 + 8;

    final bodyContent = Column(
      children: [
        FadeTransition(
          opacity: _fade(0.0, 0.45),
          child: SlideTransition(
            position: _slide(0.0, 0.45),
            child: _buildHeader(auth, tasks),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: _showSearch
              ? Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                  child: _buildSearchBar(),
                )
              : const SizedBox.shrink(),
        ),
        FadeTransition(
          opacity: _fade(0.3, 0.65),
          child: SlideTransition(
            position: _slide(0.3, 0.65),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _buildFilterTabs(tasks),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _fade(0.4, 0.75),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              children: [
                Text(
                  _selectedFilter == 0
                      ? 'All Tasks'
                      : _selectedFilter == 1
                      ? 'Pending'
                      : 'Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Text(
                      'Clear search',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: tasks.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading tasks...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6) ??
                              Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, contentBottom),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildTaskCard(filtered[i], i),
                ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Responsive.centeredContent(context: context, child: bodyContent),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottom),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
          ),
          child: GestureDetector(
            onTap: () => _showTaskSheet(),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Add Task',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, TaskProvider tasks) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF3B82F6), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.userName?.split(' ').first ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _motivationalQuote(tasks),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _headerBtn(
                    icon: _showSearch
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchController.clear();
                          _searchQuery = '';
                          _searchFocus.unfocus();
                        } else {
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _searchFocus.requestFocus(),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _headerBtn(
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      tasks.fetchTasks();
                    },
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 2,
                      ),
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
                              (auth.userName?.isNotEmpty == true)
                                  ? auth.userName![0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _miniStatChip(
                '${tasks.totalTasks}',
                'Total',
                Icons.list_alt_rounded,
              ),
              const SizedBox(width: 8),
              _miniStatChip(
                '${tasks.pendingCount}',
                'Pending',
                Icons.pending_actions_rounded,
              ),
              const SizedBox(width: 8),
              _miniStatChip(
                '${tasks.completedCount}',
                'Done',
                Icons.check_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tasks.totalTasks == 0
                                ? 'No tasks yet — add one!'
                                : '${tasks.completedCount} of ${tasks.totalTasks} tasks completed',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: tasks.completionPercentage,
                            ),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Text(
                              '${(v * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: tasks.completionPercentage,
                          ),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            minHeight: 7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _miniStatChip(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 15),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildSearchBar() => Container(
    height: 48,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color:
              Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
              Colors.grey.shade400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF6C63FF),
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(
                  Icons.close_rounded,
                  color:
                      Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.5) ??
                      Colors.grey.shade400,
                  size: 18,
                ),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );

  Widget _buildFilterTabs(TaskProvider tp) {
    final tabs = [
      ('All', tp.totalTasks, Icons.list_rounded),
      ('Pending', tp.pendingCount, Icons.pending_actions_rounded),
      ('Done', tp.completedCount, Icons.check_circle_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final tab = entry.value;
          final selected = _selectedFilter == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.$3,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).unselectedWidgetColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${tab.$1} (${tab.$2})',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : Theme.of(context).unselectedWidgetColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    final isHigh = task.priority == 'high';
    final isMed = task.priority == 'medium';

    final priorityColor = isHigh
        ? const Color(0xFFEF4444)
        : isMed
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);

    final priorityBg = isHigh
        ? const Color(0xFFFFEDED)
        : isMed
        ? const Color(0xFFFFF8E7)
        : const Color(0xFFE8FDF5);

    final priorityEmoji = isHigh
        ? '🔴'
        : isMed
        ? '🟡'
        : '🟢';

    final taskProvider = context.watch<TaskProvider>();
    final countdown = taskProvider.getCountdown(task);
    final isOverdue = taskProvider.isAlarmOverdue(task);

    return TweenAnimationBuilder<double>(
      key: ValueKey(task.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index * 55)),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: task.isCompleted
              ? Border.all(color: Colors.grey.shade100)
              : Border.all(color: priorityColor.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: task.isCompleted
                  ? Colors.black.withOpacity(0.03)
                  : priorityColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _showTaskSheet(task: task),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 54,
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Colors.grey.shade200
                              : priorityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.read<TaskProvider>().toggleComplete(task.id);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: task.isCompleted
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF3B82F6),
                                    ],
                                  )
                                : null,
                            color: task.isCompleted ? null : Colors.transparent,
                            border: task.isCompleted
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                          ),
                          child: task.isCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: task.isCompleted
                                    ? Colors.grey.shade400
                                    : const Color(0xFF1F2937),
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: Colors.grey.shade400,
                              ),
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.isCompleted
                                        ? Colors.grey.shade100
                                        : priorityBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$priorityEmoji ${task.priority[0].toUpperCase()}${task.priority.substring(1)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: task.isCompleted
                                          ? Colors.grey.shade400
                                          : priorityColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.isCompleted
                                        ? const Color(0xFFE8FDF5)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.isCompleted ? '✓ Done' : '• Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: task.isCompleted
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          _actionBtn(
                            icon: Icons.edit_rounded,
                            color: const Color(0xFF6C63FF),
                            bg: const Color(0xFFEEEDFF),
                            onTap: () => _showTaskSheet(task: task),
                          ),
                          const SizedBox(height: 6),
                          _actionBtn(
                            icon: Icons.delete_rounded,
                            color: Colors.red.shade400,
                            bg: const Color(0xFFFFEDED),
                            onTap: () => _confirmDelete(task.id, task.title),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (countdown != null && !task.isCompleted) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFFFEDED)
                            : const Color(0xFF6C63FF).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOverdue
                              ? const Color(0xFFEF4444).withOpacity(0.3)
                              : const Color(0xFF6C63FF).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.alarm_off_rounded
                                : Icons.alarm_rounded,
                            size: 13,
                            color: isOverdue
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6C63FF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOverdue ? '⚠️ Overdue' : '⏱ $countdown',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOverdue
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a, MMM d').format(task.alarmTime!),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isOverdue
                                  ? const Color(0xFFEF4444).withOpacity(0.7)
                                  : const Color(0xFF6C63FF).withOpacity(0.6),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.read<TaskProvider>().removeAlarm(task.id);
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: isOverdue
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 17),
    ),
  );

  Widget _buildEmptyState() {
    final isSearch = _searchQuery.isNotEmpty;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.12),
                      const Color(0xFF3B82F6).withOpacity(0.06),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearch
                      ? Icons.search_off_rounded
                      : _selectedFilter == 2
                      ? Icons.check_circle_outline_rounded
                      : Icons.task_alt_rounded,
                  size: 48,
                  color: const Color(0xFF6C63FF).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isSearch
                    ? 'No results found'
                    : _selectedFilter == 2
                    ? 'No completed tasks'
                    : _selectedFilter == 1
                    ? 'No pending tasks 🎉'
                    : 'No tasks yet!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearch
                    ? 'Try a different search term'
                    : _selectedFilter == 2
                    ? 'Mark tasks as done to see them here'
                    : _selectedFilter == 1
                    ? 'All tasks are completed!'
                    : 'Tap Add Task to get started',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                      Colors.grey.shade400,
                  height: 1.5,
                ),
              ),
              if (!isSearch && _selectedFilter == 0) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _showTaskSheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '+ Create your first task',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool autofocus = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    maxLines: maxLines,
    validator: validator,
    style: GoogleFonts.poppins(
      fontSize: 14,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    ),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        color:
            Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
            Colors.grey.shade500,
      ),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color:
            Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
            Colors.grey.shade400,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
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
    ),
  );

  Widget _priorityChip(
    String value,
    String label,
    Color color,
    String selected,
    Function(String) onTap,
  ) {
    final isSel = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSel
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSel
                  ? color
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSel ? color : Theme.of(context).unselectedWidgetColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
