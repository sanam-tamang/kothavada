import 'package:flutter/material.dart';

/// Animation utilities for the app
class AnimationUtils {
  /// Standard durations for animations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  /// Standard curves for animations
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeInOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// Slide animation
  static Widget slide({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOut,
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value * 100, // Scale the offset
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation
  static Widget scale({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  /// Combined fade and slide animation
  static Widget fadeSlide({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOut,
    double fadeBegin = 0.0,
    double fadeEnd = 1.0,
    Offset slideBegin = const Offset(0.0, 0.2),
    Offset slideEnd = Offset.zero,
  }) {
    return fadeIn(
      begin: fadeBegin,
      end: fadeEnd,
      duration: duration,
      curve: curve,
      child: slide(
        begin: slideBegin,
        end: slideEnd,
        duration: duration,
        curve: curve,
        child: child,
      ),
    );
  }

  /// Staggered list animation
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration initialDelay = Duration.zero,
    Duration staggerDuration = const Duration(milliseconds: 50),
    Duration animationDuration = medium,
    Curve curve = easeOut,
  }) {
    List<Widget> result = [];

    for (int i = 0; i < children.length; i++) {
      final delay = initialDelay + (staggerDuration * i);

      result.add(
        AnimatedBuilder(
          animation: Listenable.merge([]),
          builder: (context, _) {
            return FutureBuilder(
              future: Future.delayed(delay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return fadeSlide(
                    duration: animationDuration,
                    curve: curve,
                    child: children[i],
                  );
                } else {
                  return Opacity(opacity: 0, child: children[i]);
                }
              },
            );
          },
        ),
      );
    }

    return result;
  }

  /// Pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    // Use a simpler approach with TweenAnimationBuilder
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: duration,
      builder: (context, _, child) {
        // Use a separate animation controller with AnimatedBuilder
        return PulseAnimationWidget(
          duration: duration,
          minScale: minScale,
          maxScale: maxScale,
          child: child!,
        );
      },
      child: child,
    );
  }

  /// Hero animation wrapper
  static Widget hero({
    required String tag,
    required Widget child,
    Object? placeholderBuilder,
  }) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Extension methods for AnimatedList
extension AnimatedListExtension on Widget {
  Widget withFadeIn({
    Duration duration = AnimationUtils.medium,
    Curve curve = AnimationUtils.easeInOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return AnimationUtils.fadeIn(
      child: this,
      duration: duration,
      curve: curve,
      begin: begin,
      end: end,
    );
  }

  Widget withSlide({
    Duration duration = AnimationUtils.medium,
    Curve curve = AnimationUtils.easeOut,
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
  }) {
    return AnimationUtils.slide(
      child: this,
      duration: duration,
      curve: curve,
      begin: begin,
      end: end,
    );
  }

  Widget withScale({
    Duration duration = AnimationUtils.medium,
    Curve curve = AnimationUtils.easeOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return AnimationUtils.scale(
      child: this,
      duration: duration,
      curve: curve,
      begin: begin,
      end: end,
    );
  }

  Widget withFadeSlide({
    Duration duration = AnimationUtils.medium,
    Curve curve = AnimationUtils.easeOut,
  }) {
    return AnimationUtils.fadeSlide(
      child: this,
      duration: duration,
      curve: curve,
    );
  }

  Widget withPulse({
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return AnimationUtils.pulse(
      child: this,
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
    );
  }

  Widget withHero(String tag) {
    return AnimationUtils.hero(tag: tag, child: this);
  }
}

/// Pulse animation widget
class PulseAnimationWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimationWidget({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
    super.key,
  });

  @override
  State<PulseAnimationWidget> createState() => _PulseAnimationWidgetState();
}

class _PulseAnimationWidgetState extends State<PulseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: widget.maxScale,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.maxScale,
          end: widget.minScale,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.minScale,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
