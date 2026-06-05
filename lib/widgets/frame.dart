import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  '9:41',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                ),
              ),
              Row(
                children: [
                  _SignalBars(color: theme.colors.ink),
                  const SizedBox(width: 6),
                  _WifiIcon(color: theme.colors.ink),
                  const SizedBox(width: 6),
                  _BatteryIcon(color: theme.colors.ink),
                  const SizedBox(width: 20),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 9,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFF050506),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final Color color;
  const _SignalBars({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(17, 12),
      painter: _SignalBarsPainter(color: color),
    );
  }
}

class _SignalBarsPainter extends CustomPainter {
  final Color color;
  _SignalBarsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final bars = [
      RRect.fromLTRBR(0, 8, 3, 12, const Radius.circular(1)),
      RRect.fromLTRBR(4.5, 5.5, 7.5, 12, const Radius.circular(1)),
      RRect.fromLTRBR(9, 3, 12, 12, const Radius.circular(1)),
      RRect.fromLTRBR(13.5, 0, 16.5, 12, const Radius.circular(1)),
    ];
    for (final bar in bars) {
      canvas.drawRRect(bar, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalBarsPainter old) => old.color != color;
}

class _WifiIcon extends StatelessWidget {
  final Color color;
  const _WifiIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 12),
      painter: _WifiPainter(color: color),
    );
  }
}

class _WifiPainter extends CustomPainter {
  final Color color;
  _WifiPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(8, 11.2)
      ..lineTo(1, 4.2)
      ..arcToPoint(const Offset(15, 4.2), radius: const Radius.circular(9.9), rotation: 0, largeArc: false, clockwise: true);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _WifiPainter old) => old.color != color;
}

class _BatteryIcon extends StatelessWidget {
  final Color color;
  const _BatteryIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 12),
      painter: _BatteryPainter(color: color),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final Color color;
  _BatteryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fillPaint = Paint()..color = color;
    final tipPaint = Paint()..color = color.withValues(alpha: 0.5);

    canvas.drawRRect(
      RRect.fromLTRBR(1, 1, 20, 11, const Radius.circular(2.5)),
      borderPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(2.6, 2.6, 15.6, 9.4, const Radius.circular(1.4)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(21, 4, 22.8, 8, const Radius.circular(0.9)),
      tipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter old) => old.color != color;
}

class NavPill extends StatelessWidget {
  const NavPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return SizedBox(
      height: 26,
      child: Center(
        child: Container(
          width: 128,
          height: 4.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: theme.colors.ink.withValues(alpha: 0.32),
          ),
        ),
      ),
    );
  }
}

class DeviceFrame extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const DeviceFrame({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenBg = isDark ? darkColors.screen : lightColors.screen;
    return Container(
      width: 412,
      height: 880,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(46),
        color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFCACCD0),
        border: Border.all(color: const Color(0x0F000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 100,
            offset: Offset(0, 50),
            spreadRadius: -20,
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(41),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: const Cubic(0.32, 0.72, 0, 1),
          color: screenBg,
          child: Column(
            children: [
              const StatusBar(),
              Expanded(child: child),
              const NavPill(),
            ],
          ),
        ),
      ),
    );
  }
}
