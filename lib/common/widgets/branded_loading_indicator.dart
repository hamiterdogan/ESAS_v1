import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class BrandedLoadingIndicator extends StatefulWidget {
  static const String defaultLogoAssetPath = 'assets/images/logo_icon.png';

  final double size;
  final double strokeWidth;
  final String logoAssetPath;
  final bool showOverlay;
  final double blurSigma;
  final Color overlayColor;

  const BrandedLoadingIndicator({
    super.key,
    this.size = 72,
    this.strokeWidth = 4,
    this.logoAssetPath = defaultLogoAssetPath,
    this.showOverlay = true,
    this.blurSigma = 0,
    this.overlayColor = const Color(0x66FFFFFF),
  });

  @override
  State<BrandedLoadingIndicator> createState() =>
      _BrandedLoadingIndicatorState();
}

class BrandedLoadingOverlay extends StatelessWidget {
  final double blurSigma;
  final Color overlayColor;
  final double indicatorSize;
  final double strokeWidth;
  final String logoAssetPath;

  const BrandedLoadingOverlay({
    super.key,
    this.blurSigma = 0,
    this.overlayColor = const Color(0x66FFFFFF),
    this.indicatorSize = 153,
    this.strokeWidth = 24,
    this.logoAssetPath = BrandedLoadingIndicator.defaultLogoAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: blurSigma > 0
                ? BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(color: overlayColor),
                  )
                : Container(color: overlayColor),
          ),
          Center(
            child: BrandedLoadingIndicator(
              size: indicatorSize,
              strokeWidth: strokeWidth,
              logoAssetPath: logoAssetPath,
              showOverlay: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandedLoadingIndicatorState extends State<BrandedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _delayTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Increased logo ratio as per recent request (0.8)
    // Reduce it slightly to fit inside the ring if needed, but keeping 0.8
    // makes it nice and big. The ring is on the outside.
    // However, if the ring has significant thickness, we might need padding.
    // The previous implementation used size * 0.8.
    final logoSize = ((widget.size * 0.55).clamp(16, widget.size)).toDouble();

    final indicator = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Segmented Rotating Ring
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: CustomPaint(
                    painter: _SegmentedRingPainter(
                      strokeWidth: 6,
                      startColor: AppColors.gradientStart.withValues(
                        alpha: 1.0,
                      ),
                      endColor: AppColors.gradientEnd.withValues(alpha: 0.3),
                      segmentCount: 3,
                    ),
                  ),
                );
              },
            ),
          ),
          // Centered Logo
          SizedBox(
            width: logoSize,
            height: logoSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(logoSize / 5),
              child: Image.asset(
                widget.logoAssetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.gradientStart,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    return Visibility(
      visible: _isVisible,
      replacement: const SizedBox.shrink(),
      child: indicator,
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final double strokeWidth;
  final Color startColor;
  final Color endColor;
  final int segmentCount;

  _SegmentedRingPainter({
    required this.strokeWidth,
    required this.startColor,
    required this.endColor,
    this.segmentCount = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 2 * pi for full circle
    const fullCircle = 2 * math.pi;
    final segmentAngle = fullCircle / segmentCount;
    // 17px gap = 17 / radius (arc length formula)
    final gapAngle = (17.0 / radius).clamp(0.3, segmentAngle * 0.5);
    final sweepAngle = segmentAngle - gapAngle;

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = (i * segmentAngle);

      // Create gradient for each segment: start opacity 1.0, end opacity 0.2
      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      segmentPaint.shader = SweepGradient(
        colors: [
          startColor.withValues(alpha: 1.0),
          endColor.withValues(alpha: 0.2),
        ],
        tileMode: TileMode.clamp,
      ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);
    }
  }

  @override
  bool shouldRepaint(_SegmentedRingPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor ||
        oldDelegate.segmentCount != segmentCount;
  }
}
