import 'package:flutter/material.dart';
import 'package:kothavada/core/constants/app_theme.dart';
import 'package:kothavada/core/utils/animation_utils.dart';
import 'dart:math' as math;

/// A card that animates when it appears
class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final Duration duration;
  final Curve curve;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
    this.borderRadius,
    this.color,
    this.duration = AnimationUtils.medium,
    this.curve = AnimationUtils.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.fadeSlide(
      duration: duration,
      curve: curve,
      child: Card(
        elevation: elevation,
        color: color ?? AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A button that animates when pressed
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool isOutlined;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.borderRadius,
    this.elevation = 2,
    this.isOutlined = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationUtils.fast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child:
            widget.isOutlined
                ? OutlinedButton(
                  onPressed: widget.onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.textColor ?? AppTheme.primaryColor,
                    side: BorderSide(
                      color: widget.color ?? AppTheme.primaryColor,
                      width: 1.5,
                    ),
                    padding: widget.padding,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          widget.borderRadius ?? BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.child,
                )
                : ElevatedButton(
                  onPressed: widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color ?? AppTheme.primaryColor,
                    foregroundColor: widget.textColor ?? Colors.white,
                    elevation: widget.elevation,
                    padding: widget.padding,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          widget.borderRadius ?? BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.child,
                ),
      ),
    );
  }
}

/// A shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A pulsing container for highlighting elements
class PulsingContainer extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const PulsingContainer({
    super.key,
    required this.child,
    this.color = AppTheme.accentColor,
    this.minOpacity = 0.2,
    this.maxOpacity = 0.5,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulsingContainer> createState() => _PulsingContainerState();
}

class _PulsingContainerState extends State<PulsingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                color: widget.color.withAlpha((_animation.value * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

/// A staggered grid view that animates items as they appear
class AnimatedStaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final Duration staggerDuration;
  final Duration animationDuration;
  final Curve curve;

  const AnimatedStaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.animationDuration = AnimationUtils.medium,
    this.curve = AnimationUtils.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: children.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return FutureBuilder(
          future: Future.delayed(staggerDuration * index),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AnimationUtils.fadeSlide(
                duration: animationDuration,
                curve: curve,
                child: children[index],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}

/// A custom page transition that slides and fades
class SlidePageTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;

  SlidePageTransition({
    required this.page,
    this.duration = AnimationUtils.medium,
    this.curve = AnimationUtils.easeOut,
    this.beginOffset = const Offset(0, 0.2),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
           );

           return FadeTransition(
             opacity: curvedAnimation,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: beginOffset,
                 end: Offset.zero,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

/// A custom loading indicator
class CustomLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const CustomLoadingIndicator({
    super.key,
    this.color = AppTheme.accentColor,
    this.size = 40,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _LoadingPainter(
                color: widget.color,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  _LoadingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withAlpha(51) // 0.2 * 255 = 51
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14159, // Start from top
      progress * 2 * 3.14159, // Full circle
      false,
      paint,
    );

    // Draw small circle at the end of the arc
    final endAngle = -0.5 * 3.14159 + progress * 2 * 3.14159;
    final endPoint = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );

    canvas.drawCircle(endPoint, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Helper function
double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);
