import 'dart:math';

import 'package:flutter/material.dart';

class ExpressiveRefreshIndicator extends StatefulWidget {
  const ExpressiveRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    required this.scrollController,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollController scrollController;

  @override
  State<ExpressiveRefreshIndicator> createState() =>
      _ExpressiveRefreshIndicatorState();
}

class _ExpressiveRefreshIndicatorState
    extends State<ExpressiveRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _morphCtrl;
  double _pullDistance = 0;
  bool _refreshing = false;

  static const _maxPull = 100.0;
  static const _triggerThreshold = 70.0;

  @override
  void initState() {
    super.initState();
    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _morphCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_refreshing) return;
    final pos = widget.scrollController.position;
    final overscroll = pos.pixels < pos.minScrollExtent
        ? (pos.minScrollExtent - pos.pixels)
        : 0.0;
    if (!mounted) return;
    setState(() {
      _pullDistance = overscroll.clamp(0.0, _maxPull);
      _morphCtrl.value = (_pullDistance / _maxPull).clamp(0.0, 1.0);
    });
  }

  Future<void> _triggerRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _morphCtrl.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _pullDistance = 0;
        });
        _morphCtrl.stop();
        _morphCtrl.value = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        if (n.dragDetails != null && !_refreshing) {
          _onScroll();
        }
        return false;
      },
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (n) {
          n.disallowIndicator();
          return true;
        },
        child: Stack(
          children: [
            widget.child,
            if (_pullDistance > 0 || _refreshing)
              Positioned(
                top: _refreshing ? 16 : (_pullDistance - 40).clamp(0.0, 80.0),
                left: 0,
                right: 0,
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (n) {
                    if (n.dragDetails == null &&
                        _pullDistance >= _triggerThreshold &&
                        !_refreshing) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _triggerRefresh());
                    }
                    return false;
                  },
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _morphCtrl,
                      builder: (_, __) {
                        return _MorphShape(
                          t: _morphCtrl.value,
                          pullProgress: (_pullDistance / _maxPull).clamp(0.0, 1.0),
                          active: _refreshing,
                          color: scheme.primary,
                        );
                      },
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

class _MorphShape extends StatelessWidget {
  const _MorphShape({
    required this.t,
    required this.pullProgress,
    required this.active,
    required this.color,
  });

  final double t;
  final double pullProgress;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final baseSize = 24.0 + pullProgress * 16;
    final size = active ? baseSize + 6 * sin(t * 2 * pi) : baseSize;
    final cutoutRadius = active ? size * 0.28 : (pullProgress > 0.55 ? (pullProgress - 0.55) * size * 0.5 : 0.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MorphPainter(
          t: active ? t : pullProgress,
          active: active,
          color: color.withValues(alpha: active ? 1.0 : (0.4 + pullProgress * 0.6)),
          cutoutRadius: cutoutRadius,
        ),
        child: cutoutRadius > 0
            ? Center(
                child: Icon(
                  Icons.refresh,
                  size: cutoutRadius * 1.4,
                  color: color,
                ),
              )
            : null,
      ),
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({
    required this.t,
    required this.active,
    required this.color,
    required this.cutoutRadius,
  });

  final double t;
  final bool active;
  final Color color;
  final double cutoutRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rect = Offset.zero & size;
    final rrect = _buildShape(rect, t, active);

    if (cutoutRadius > 0) {
      final center = Offset(size.width / 2, size.height / 2);
      final cutoutPath = Path()..addOval(Rect.fromCircle(center: center, radius: cutoutRadius));
      final shapePath = Path()..addRRect(rrect);
      final result = Path.combine(PathOperation.difference, shapePath, cutoutPath);
      canvas.drawPath(result, paint);
    } else {
      canvas.drawRRect(rrect, paint);
    }
  }

  RRect _buildShape(Rect rect, double t, bool active) {
    if (!active) {
      final r = 4.0 + t * 14;
      return RRect.fromRectAndRadius(rect, Radius.circular(r));
    }

    final phase = (t * 5) % 1;
    if (phase < 0.2) {
      final r = ml(4, 16, phase / 0.2);
      return RRect.fromRectAndRadius(rect, Radius.circular(r));
    }
    if (phase < 0.4) {
      final p = (phase - 0.2) / 0.2;
      return RRect.fromLTRBAndCorners(
        0, 0, rect.width, rect.height,
        topLeft: Radius.circular(ml(16, 4, p)),
        topRight: Radius.circular(ml(16, 18, p)),
        bottomRight: Radius.circular(ml(16, 4, p)),
        bottomLeft: Radius.circular(ml(16, 18, p)),
      );
    }
    if (phase < 0.6) {
      final p = (phase - 0.4) / 0.2;
      return RRect.fromLTRBAndCorners(
        0, 0, rect.width, rect.height,
        topLeft: Radius.circular(ml(4, 0, p)),
        topRight: Radius.circular(ml(18, 0, p)),
        bottomRight: Radius.circular(ml(4, 0, p)),
        bottomLeft: Radius.circular(ml(18, 0, p)),
      );
    }
    if (phase < 0.8) {
      final p = (phase - 0.6) / 0.2;
      return RRect.fromLTRBAndCorners(
        0, 0, rect.width, rect.height,
        topLeft: Radius.circular(ml(0, 18, p)),
        topRight: Radius.circular(ml(0, 2, p)),
        bottomRight: Radius.circular(ml(0, 18, p)),
        bottomLeft: Radius.circular(ml(0, 2, p)),
      );
    }
    final p = (phase - 0.8) / 0.2;
    final r = ml(18, 4, p);
    return RRect.fromRectAndRadius(rect, Radius.circular(r));
  }

  double ml(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _MorphPainter oldDelegate) =>
      t != oldDelegate.t || active != oldDelegate.active || cutoutRadius != oldDelegate.cutoutRadius;
}
