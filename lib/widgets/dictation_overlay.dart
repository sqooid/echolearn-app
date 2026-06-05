import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/theme.dart';
import 'icons.dart';
import 'oscilloscope.dart';

class DictationOverlay extends StatefulWidget {
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  const DictationOverlay({
    super.key,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<DictationOverlay> createState() => _DictationOverlayState();
}

class _DictationOverlayState extends State<DictationOverlay> {
  final _speech = stt.SpeechToText();
  String _recognized = '';
  bool _listening = true;
  bool _done = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = error.errorMsg;
          _listening = false;
        });
      },
      onStatus: (status) {
        if (status == 'done' && !_done) {
          setState(() => _listening = false);
        }
      },
    );
    if (!mounted) return;
    if (!available) {
      setState(() {
        _error = 'Speech recognition not available';
        _listening = false;
      });
      return;
    }
    _startListening();
  }

  void _startListening() {
    _speech.listen(
      onResult: (result) {
        if (!mounted || _done) return;
        setState(() {
          _recognized = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(
        autoPunctuation: true,
        partialResults: true,
        localeId: 'en_US',
      ),
    );
  }

  void _finish() {
    if (_done) return;
    setState(() => _done = true);
    _speech.stop();
    final text = _recognized.trim();
    Future.delayed(const Duration(milliseconds: 240), () {
      widget.onCommit(text);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onCancel,
        child: Container(
          color: const Color(0x6B141416),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 96),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      decoration: BoxDecoration(
                        color: theme.colors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.colors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2E000000),
                            blurRadius: 40,
                            offset: Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _PulsingDot(active: _listening, accent: theme.accent),
                              const SizedBox(width: 8),
                              Text(
                                _done ? 'Captured' : (_listening ? 'Listening · English' : 'Ready'),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  letterSpacing: 0.88,
                                  color: theme.colors.inkSoft,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: widget.onCancel,
                                child: IconClose(size: 20, color: theme.colors.inkFaint),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 64,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    if (_error.isNotEmpty)
                                      TextSpan(
                                        text: _error,
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colors.inkFaint,
                                        ),
                                      )
                                    else ...[
                                      TextSpan(
                                        text: _recognized.isEmpty && _listening
                                            ? 'Start speaking…'
                                            : _recognized,
                                        style: TextStyle(
                                          fontSize: 21,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                          color: _recognized.isEmpty && _listening
                                              ? theme.colors.inkFaint
                                              : theme.colors.ink,
                                        ),
                                      ),
                                      if (!_done && _listening)
                                        WidgetSpan(
                                          child: _Cursor(accent: theme.accent),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Oscilloscope(active: _listening),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: (_done || _error.isNotEmpty) ? null : _finish,
                            child: AnimatedOpacity(
                              opacity: (_done || _error.isNotEmpty) ? 0.5 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: theme.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconCheck(size: 20, sw: 2.4, color: theme.onAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      _done ? 'Adding…' : 'Done',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.onAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool active;
  final Color accent;

  const _PulsingDot({required this.active, required this.accent});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.accent,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(8, 8),
          painter: _PulsingDotPainter(
            accent: widget.accent,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _PulsingDotPainter extends CustomPainter {
  final Color accent;
  final double progress;

  _PulsingDotPainter({required this.accent, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.7 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final ringRadius = 4 + progress * 8;
    canvas.drawCircle(center, ringRadius, ringPaint);

    final dotPaint = Paint()..color = accent;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PulsingDotPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _Cursor extends StatefulWidget {
  final Color accent;

  const _Cursor({required this.accent});

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 22,
            margin: const EdgeInsets.only(left: 3),
            color: widget.accent,
          ),
        );
      },
    );
  }
}
