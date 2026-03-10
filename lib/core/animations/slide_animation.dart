import 'package:flutter/material.dart';

enum SlideDirection { fromBottom, fromTop, fromLeft, fromRight }

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final double delay;
  final SlideDirection direction;
  final Duration duration;

  const SlideAnimation({
    super.key,
    required this.child,
    this.delay = 0.0,
    this.direction = SlideDirection.fromBottom,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double>  _fade;

  Offset get _beginOffset {
    switch (widget.direction) {
      case SlideDirection.fromBottom: return const Offset(0,  0.5);
      case SlideDirection.fromTop:    return const Offset(0, -0.5);
      case SlideDirection.fromLeft:   return const Offset(-0.5, 0);
      case SlideDirection.fromRight:  return const Offset( 0.5, 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _slide = Tween<Offset>(begin: _beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    Future.delayed(
      Duration(milliseconds: (widget.delay * 1000).toInt()),
          () { if (mounted) _controller.forward(); },
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}