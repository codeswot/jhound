import 'dart:math';

import 'package:flutter/material.dart';

class ExpressiveLoader extends StatefulWidget {
  const ExpressiveLoader({super.key, this.size = 48});

  final double size;

  @override
  State<ExpressiveLoader> createState() => _ExpressiveLoaderState();
}

class _ExpressiveLoaderState extends State<ExpressiveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final t = _ctrl.value;
          final r = _radius(t);
          return Center(
            child: Transform.rotate(
              angle: t * 2 * pi,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(r),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _radius(double t) {
    if (t < 0.25) return _lerp(6, 4, t / 0.25);
    if (t < 0.5) return _lerp(4, 12, (t - 0.25) / 0.25);
    if (t < 0.75) return _lerp(12, 8, (t - 0.5) / 0.25);
    return _lerp(8, 6, (t - 0.75) / 0.25);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
