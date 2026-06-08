import 'package:flutter/material.dart';

class LingoIcon extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final Path Function(Size) pathBuilder;
  final bool fill;
  final Size? viewBox;

  const LingoIcon({
    super.key,
    this.size = 24,
    this.strokeWidth = 1.8,
    this.color,
    required this.pathBuilder,
    this.fill = false,
    this.viewBox,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IconPainter(
        pathBuilder: pathBuilder,
        color: color,
        strokeWidth: strokeWidth,
        fill: fill,
        viewBox: viewBox ?? const Size(24, 24),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final Path Function(Size) pathBuilder;
  final Color? color;
  final double strokeWidth;
  final bool fill;
  final Size viewBox;

  _IconPainter({
    required this.pathBuilder,
    this.color,
    required this.strokeWidth,
    required this.fill,
    required this.viewBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? const Color(0xFF000000)
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / viewBox.width;
    final scaleY = size.height / viewBox.height;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final path = pathBuilder(size);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fill != fill;
  }
}

// --- Icon builders ---

Path _micPath(Size s) => Path()
  ..addRRect(RRect.fromRectAndRadius(
    const Rect.fromLTWH(9, 2.5, 6, 12), const Radius.circular(3),
  ))
  ..moveTo(5.5, 11)
  ..arcToPoint(
    const Offset(18.5, 11),
    radius: const Radius.circular(6.5),
    largeArc: false,
    clockwise: false,
  )
  ..moveTo(12, 17.5)
  ..lineTo(12, 21);

Path _homePath(Size s) => Path()
  ..moveTo(4, 10.5)
  ..lineTo(12, 4)
  ..lineTo(20, 10.5)
  ..moveTo(5.5, 9.5)
  ..lineTo(5.5, 20)
  ..lineTo(18.5, 20)
  ..lineTo(18.5, 9.5)
  ..moveTo(10, 20)
  ..lineTo(10, 15)
  ..lineTo(14, 15)
  ..lineTo(14, 20);

Path _layersPath(Size s) => Path()
  ..moveTo(12, 3)
  ..lineTo(3, 8)
  ..lineTo(12, 13)
  ..lineTo(21, 8)
  ..close()
  ..moveTo(3, 13)
  ..lineTo(12, 18)
  ..lineTo(21, 13);

Path _settingsPath(Size s) => Path()
  ..addOval(const Rect.fromLTWH(8.8, 8.8, 6.4, 6.4))
  ..moveTo(12, 2.5)
  ..lineTo(12, 4.9)
  ..moveTo(12, 19.1)
  ..lineTo(12, 21.5)
  ..moveTo(21.5, 12)
  ..lineTo(19.1, 12)
  ..moveTo(4.9, 12)
  ..lineTo(2.5, 12)
  ..moveTo(18.7, 5.3)
  ..lineTo(17, 7)
  ..moveTo(7, 17)
  ..lineTo(5.3, 18.7)
  ..moveTo(18.7, 18.7)
  ..lineTo(17, 17)
  ..moveTo(7, 7)
  ..lineTo(5.3, 5.3);

Path _playPath(Size s) => Path()
  ..moveTo(7, 4.5)
  ..lineTo(20, 12)
  ..lineTo(7, 19.5)
  ..close();

Path _pausePath(Size s) => Path()
  ..addRRect(RRect.fromRectAndRadius(
    const Rect.fromLTWH(6.5, 5, 4, 14), const Radius.circular(1.2),
  ))
  ..addRRect(RRect.fromRectAndRadius(
    const Rect.fromLTWH(13.5, 5, 4, 14), const Radius.circular(1.2),
  ));

Path _speakerPath(Size s) => Path()
  ..moveTo(4, 9)
  ..lineTo(4, 15)
  ..lineTo(7.5, 15)
  ..lineTo(13, 19)
  ..lineTo(13, 5)
  ..lineTo(7.5, 9)
  ..close()
  ..moveTo(16.5, 8.8)
  ..arcToPoint(const Offset(16.5, 15.2), radius: const Radius.circular(4), rotation: 0, largeArc: false, clockwise: true)
  ..moveTo(18.8, 6.4)
  ..arcToPoint(const Offset(18.8, 17.6), radius: const Radius.circular(7), rotation: 0, largeArc: false, clockwise: true);

Path _trashPath(Size s) => Path()
  ..moveTo(4, 6.5)
  ..lineTo(20, 6.5)
  ..moveTo(9, 6.5)
  ..lineTo(9, 4.5)
  ..lineTo(15, 4.5)
  ..lineTo(15, 6.5)
  ..moveTo(6, 6.5)
  ..lineTo(6.8, 20)
  ..lineTo(17.2, 20)
  ..lineTo(18, 6.5)
  ..moveTo(10, 10.5)
  ..lineTo(10, 16.5)
  ..moveTo(14, 10.5)
  ..lineTo(14, 16.5);

Path _archivePath(Size s) => Path()
  ..addRRect(RRect.fromRectAndRadius(
    const Rect.fromLTWH(3.5, 4.5, 17, 4), const Radius.circular(1.2),
  ))
  ..moveTo(5, 8.5)
  ..lineTo(5, 19)
  ..lineTo(19, 19)
  ..lineTo(19, 8.5)
  ..moveTo(9.5, 12.5)
  ..lineTo(14.5, 12.5);

Path _slidersPath(Size s) => Path()
  ..moveTo(4, 8)
  ..lineTo(14, 8)
  ..moveTo(18, 8)
  ..lineTo(20, 8)
  ..moveTo(4, 16)
  ..lineTo(6, 16)
  ..moveTo(10, 16)
  ..lineTo(20, 16)
  ..addOval(const Rect.fromLTWH(13.8, 5.8, 4.4, 4.4))
  ..addOval(const Rect.fromLTWH(5.8, 13.8, 4.4, 4.4));

Path _chevronPath(Size s) => Path()
  ..moveTo(6, 9)
  ..lineTo(12, 15)
  ..lineTo(18, 9);

Path _checkPath(Size s) => Path()
  ..moveTo(4.5, 12.5)
  ..lineTo(9.5, 17.5)
  ..lineTo(19.5, 6.5);

Path _closePath(Size s) => Path()
  ..moveTo(6, 6)
  ..lineTo(18, 18)
  ..moveTo(18, 6)
  ..lineTo(6, 18);

Path _searchPath(Size s) => Path()
  ..addOval(const Rect.fromLTWH(4.5, 4.5, 13, 13))
  ..moveTo(16, 16)
  ..lineTo(20.5, 20.5);

Path _shufflePath(Size s) => Path()
  ..moveTo(3, 6.5)
  ..lineTo(6.5, 6.5)
  ..lineTo(9.5, 11)
  ..moveTo(21, 6.5)
  ..lineTo(17, 6.5)
  ..lineTo(8, 17.5)
  ..lineTo(3, 17.5)
  ..moveTo(21, 6.5)
  ..lineTo(18, 4)
  ..moveTo(21, 6.5)
  ..lineTo(18, 9)
  ..moveTo(14.5, 14)
  ..lineTo(17, 17.5)
  ..lineTo(21, 17.5)
  ..moveTo(21, 17.5)
  ..lineTo(18, 15)
  ..moveTo(21, 17.5)
  ..lineTo(18, 20);

Path _clockPath(Size s) => Path()
  ..addOval(const Rect.fromLTWH(3.5, 3.5, 17, 17))
  ..moveTo(12, 7.5)
  ..lineTo(12, 12)
  ..lineTo(15, 14);

Path _sunPath(Size s) => Path()
  ..addOval(const Rect.fromLTWH(8, 8, 8, 8))
  ..moveTo(12, 2.5)
  ..lineTo(12, 4.7)
  ..moveTo(12, 19.3)
  ..lineTo(12, 21.5)
  ..moveTo(21.5, 12)
  ..lineTo(19.3, 12)
  ..moveTo(4.7, 12)
  ..lineTo(2.5, 12)
  ..moveTo(18.4, 5.6)
  ..lineTo(16.8, 7.2)
  ..moveTo(7.2, 16.8)
  ..lineTo(5.6, 18.4)
  ..moveTo(18.4, 18.4)
  ..lineTo(16.8, 16.8)
  ..moveTo(7.2, 7.2)
  ..lineTo(5.6, 5.6);

Path _moonPath(Size s) => Path()
  ..moveTo(20, 14.5)
  ..arcToPoint(const Offset(9.5, 4), radius: const Radius.circular(8), rotation: 0, largeArc: true, clockwise: false)
  ..arcToPoint(const Offset(20, 14.5), radius: const Radius.circular(7.5), rotation: 0, largeArc: false, clockwise: true);

Path _globePath(Size s) => Path()
  ..addOval(const Rect.fromLTWH(3.5, 3.5, 17, 17))
  ..moveTo(3.5, 12)
  ..lineTo(20.5, 12)
  ..moveTo(12, 3.5)
  ..cubicTo(14.5, 5.9, 14.5, 18.1, 12, 20.5)
  ..moveTo(12, 3.5)
  ..cubicTo(9.5, 5.9, 9.5, 18.1, 12, 20.5);

Path _arrowUpPath(Size s) => Path()
  ..moveTo(12, 19)
  ..lineTo(12, 5)
  ..moveTo(6, 11)
  ..lineTo(12, 5)
  ..lineTo(18, 11);

Path _arrowDownPath(Size s) => Path()
  ..moveTo(12, 5)
  ..lineTo(12, 19)
  ..moveTo(6, 13)
  ..lineTo(12, 19)
  ..lineTo(18, 13);

Path _typePath(Size s) => Path()
  ..moveTo(5, 7)
  ..lineTo(5, 5)
  ..lineTo(19, 5)
  ..lineTo(19, 7)
  ..moveTo(12, 5)
  ..lineTo(12, 19)
  ..moveTo(9.5, 19)
  ..lineTo(14.5, 19);

Path _restorePath(Size s) => Path()
  ..moveTo(4, 8.5)
  ..lineTo(4, 19)
  ..lineTo(20, 19)
  ..lineTo(20, 8.5)
  ..addRRect(RRect.fromRectAndRadius(
    const Rect.fromLTWH(3.5, 4.5, 17, 4), const Radius.circular(1.2),
  ))
  ..moveTo(12, 16)
  ..lineTo(12, 12)
  ..moveTo(9.8, 13.8)
  ..lineTo(12, 11.6)
  ..lineTo(14.2, 13.8);

// --- Convenience widgets ---

class IconMic extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconMic({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _micPath);
}

class IconHome extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconHome({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _homePath);
}

class IconLayers extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconLayers({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _layersPath);
}

class IconSettings extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconSettings({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _settingsPath);
}

class IconPlay extends StatelessWidget {
  final double size;
  final Color? color;
  const IconPlay({super.key, this.size = 24, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, color: color, pathBuilder: _playPath, fill: true);
}

class IconPause extends StatelessWidget {
  final double size;
  final Color? color;
  const IconPause({super.key, this.size = 24, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, color: color, pathBuilder: _pausePath, fill: true);
}

class IconSpeaker extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconSpeaker({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _speakerPath);
}

class IconTrash extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconTrash({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _trashPath);
}

class IconArchive extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconArchive({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _archivePath);
}

class IconSliders extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconSliders({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _slidersPath);
}

class IconChevron extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconChevron({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _chevronPath);
}

class IconCheck extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconCheck({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _checkPath);
}

class IconClose extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconClose({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _closePath);
}

class IconSearch extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconSearch({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _searchPath);
}

class IconShuffle extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconShuffle({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _shufflePath);
}

class IconClock extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconClock({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _clockPath);
}

class IconSun extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconSun({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _sunPath);
}

class IconMoon extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconMoon({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _moonPath);
}

class IconGlobe extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconGlobe({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _globePath);
}

class IconArrowUp extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconArrowUp({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _arrowUpPath);
}

class IconArrowDown extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconArrowDown({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _arrowDownPath);
}

class IconType extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconType({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _typePath);
}

class IconRestore extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconRestore({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _restorePath);
}

Path _plusPath(Size s) => Path()
  ..moveTo(12, 5)
  ..lineTo(12, 19)
  ..moveTo(5, 12)
  ..lineTo(19, 12);

class IconPlus extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconPlus({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _plusPath);
}

Path _minusPath(Size s) => Path()
  ..moveTo(5, 12)
  ..lineTo(19, 12);

class IconMinus extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconMinus({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _minusPath);
}

Path _editPath(Size s) => Path()
  ..moveTo(15, 4.5)
  ..lineTo(19.5, 9)
  ..lineTo(11.5, 17)
  ..lineTo(7, 17)
  ..lineTo(7, 12.5)
  ..close()
  ..moveTo(13.5, 6)
  ..lineTo(18, 10.5);

class IconEdit extends StatelessWidget {
  final double size;
  final double sw;
  final Color? color;
  const IconEdit({super.key, this.size = 24, this.sw = 1.8, this.color});
  @override
  Widget build(BuildContext context) => LingoIcon(size: size, strokeWidth: sw, color: color, pathBuilder: _editPath);
}
