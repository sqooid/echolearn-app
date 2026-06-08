import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/theme.dart';
import 'icons.dart';
import 'oscilloscope.dart';

enum _Phase { warming, listening, stopped, editing, captured, error }

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
  final _textKey = GlobalKey();
  final _focusNode = FocusNode();
  final _editController = TextEditingController();
  String _recognized = '';
  _Phase _phase = _Phase.warming;
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
        if (error.errorMsg == 'error_no_match' || error.errorMsg == 'error_speech_timeout') {
          if (_phase == _Phase.warming || _phase == _Phase.listening || _phase == _Phase.stopped) {
            setState(() => _phase = _Phase.stopped);
          }
          return;
        }
        setState(() {
          _error = error.errorMsg;
          _phase = _Phase.error;
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        switch (status) {
          case 'ready_for_speech':
          case 'listening':
            if (_phase == _Phase.warming) {
              setState(() => _phase = _Phase.listening);
            }
            break;
          case 'notListening':
          case 'done':
            if (_phase == _Phase.listening) {
              setState(() => _phase = _Phase.stopped);
            }
            break;
        }
      },
    );
    if (!mounted) return;
    if (!available) {
      setState(() {
        _error = 'Speech recognition not available';
        _phase = _Phase.error;
      });
      return;
    }
    _startListening();
  }

  void _startListening() {
    _speech.listen(
      onResult: (result) {
        if (!mounted || _phase != _Phase.listening) return;
        setState(() {
          _recognized = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(
        autoPunctuation: true,
        partialResults: true,
        localeId: 'en_US',
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _finish() {
    if (_phase == _Phase.captured || _phase == _Phase.error) return;
    final wasEditing = _phase == _Phase.editing;
    setState(() => _phase = _Phase.captured);
    _speech.stop();
    _focusNode.unfocus();
    final text = (wasEditing ? _editController.text : _recognized).trim();
    Future.delayed(const Duration(milliseconds: 240), () {
      widget.onCommit(text);
    });
  }

  void _onTextTap(TapDownDetails details) {
    if (_phase == _Phase.captured || _phase == _Phase.error) return;
    _speech.stop();
    _editController.text = _recognized;
    if (_recognized.isNotEmpty) {
      final renderBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localOffset = renderBox.globalToLocal(details.globalPosition);
        final textStyle = TextStyle(
          fontSize: 21,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: LingoTheme.of(context).colors.ink,
        );
        final textPainter = TextPainter(
          text: TextSpan(text: _recognized, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: renderBox.size.width);
        final textPosition = textPainter.getPositionForOffset(localOffset);
        _editController.selection = TextSelection.collapsed(offset: textPosition.offset);
      }
    } else {
      _editController.selection = const TextSelection.collapsed(offset: 0);
    }
    setState(() => _phase = _Phase.editing);
    _focusNode.requestFocus();
  }

  TextStyle get _textStyle => TextStyle(
        fontSize: 21,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: _recognized.isEmpty && _phase == _Phase.listening
            ? LingoTheme.of(context).colors.inkFaint
            : LingoTheme.of(context).colors.ink,
      );

  @override
  void dispose() {
    _speech.stop();
    _focusNode.dispose();
    _editController.dispose();
    super.dispose();
  }

  String get _statusText {
    switch (_phase) {
      case _Phase.warming:
        return 'Loading speech model\u2026';
      case _Phase.listening:
        return 'Listening \u2022 English';
      case _Phase.stopped:
        return 'Stopped \u2022 English';
      case _Phase.editing:
        return 'Editing \u2022 English';
      case _Phase.captured:
        return 'Captured';
      case _Phase.error:
        return 'Error';
    }
  }

  bool get _isListening => _phase == _Phase.listening;
  bool get _canFinish => _phase != _Phase.captured && _phase != _Phase.error;

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
                              _PulsingDot(active: _isListening, accent: theme.accent),
                              const SizedBox(width: 8),
                              Text(
                                _statusText,
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
                          GestureDetector(
                            onTapDown: _onTextTap,
                            child: SizedBox(
                              key: _textKey,
                              height: 64,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _phase == _Phase.editing
                                    ? TextField(
                                        controller: _editController,
                                        focusNode: _focusNode,
                                        style: _textStyle,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        maxLines: 3,
                                      )
                                    : Text.rich(
                                        TextSpan(
                                          children: [
                                            if (_phase == _Phase.error)
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
                                                text: _recognized.isEmpty && _isListening
                                                    ? 'Start speaking\u2026'
                                                    : _recognized,
                                                style: _textStyle,
                                              ),
                                              if (_isListening)
                                                WidgetSpan(
                                                  child: _Cursor(accent: theme.accent),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Oscilloscope(active: _isListening),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _canFinish ? _finish : null,
                            child: AnimatedOpacity(
                              opacity: _canFinish ? 1.0 : 0.5,
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
                                      _phase == _Phase.captured ? 'Adding\u2026' : 'Done',
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
