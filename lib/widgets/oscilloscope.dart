import 'dart:math';
import 'package:flutter/material.dart';

class Oscilloscope extends StatefulWidget {
  final bool active;

  const Oscilloscope({super.key, required this.active});

  @override
  State<Oscilloscope> createState() => _OscilloscopeState();
}

class _OscilloscopeState extends State<Oscilloscope> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _envelope = 0;
  double _target = 0.2;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 999),
    )..addListener(_onTick);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    final now = _controller.lastElapsedDuration?.inMilliseconds ?? 0;
    if (now % 200 < 16) {
      _target = widget.active ? (0.15 + _random.nextDouble() * 0.85) : 0.04;
    }
    _envelope += (_target - _envelope) * 0.12;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: CustomPaint(
        size: const Size(double.infinity, 64),
        painter: _OscilloscopePainter(
          envelope: _envelope,
          controller: _controller,
          accent: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _OscilloscopePainter extends CustomPainter {
  final double envelope;
  final AnimationController controller;
  final Color accent;

  _OscilloscopePainter({
    required this.envelope,
    required this.controller,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    final n = 110;
    final path = Path();
    final t = controller.value * 1000;

    for (int i = 0; i <= n; i++) {
      final x = (i / n) * w;
      final win = sin((i / n) * pi);
      final wobble =
          sin(i * 0.30 + t * 2.0) * 0.6 +
          sin(i * 0.13 - t * 1.3) * 0.3 +
          sin(i * 0.55 + t * 3.1) * 0.18;
      final y = mid + wobble * win * envelope * (h * 0.42);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter old) =>
      old.envelope != envelope || old.controller.value != controller.value || old.accent != accent;
}
