import 'package:flutter/material.dart';
import '../models/card.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import 'icons.dart';

class PlayDOT extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;

  const PlayDOT({super.key, required this.playing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: const Cubic(0.32, 0.72, 0, 1),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: playing ? theme.accent : theme.colors.surface2,
          shape: BoxShape.circle,
          border: Border.all(
            color: playing ? Colors.transparent : theme.colors.borderStrong,
          ),
        ),
        child: Center(
          child: playing
              ? IconPause(size: 20, color: theme.onAccent)
              : IconSpeaker(size: 20, color: theme.colors.ink),
        ),
      ),
    );
  }
}

class Shimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const Shimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 6,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [theme.colors.surface3, theme.colors.surface2, theme.colors.surface3],
              stops: const [0.25, 0.37, 0.63],
              transform: _GradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _GradientTransform extends GradientTransform {
  final double value;
  const _GradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues((value - 0.5) * 400 - 180, 0, 0);
  }
}

class MetaRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final bool mono;

  const MetaRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: icon,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: theme.colors.inkSoft),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: theme.colors.ink,
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class ActionBtn extends StatefulWidget {
  final Widget icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const ActionBtn({
    super.key,
    required this.icon,
    required this.label,
    this.danger = false,
    required this.onTap,
  });

  @override
  State<ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<ActionBtn> {
  bool _hover = false;

  void _setHover(bool v) {
    if (mounted) setState(() => _hover = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setHover(true),
        onTapUp: (_) => _setHover(false),
        onTapCancel: () => _setHover(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: const Cubic(0.32, 0.72, 0, 1),
          height: 44,
          decoration: BoxDecoration(
            color: _hover
                ? (widget.danger ? theme.colors.ink : theme.colors.surface3)
                : theme.colors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colors.borderStrong),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 17,
                height: 17,
                child: widget.icon,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hover && widget.danger ? theme.colors.surface : theme.colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TranslationCardWidget extends StatelessWidget {
  final TranslationCard card;
  final bool expanded;
  final bool current;
  final bool playing;
  final VoidCallback onToggle;
  final VoidCallback onPlay;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  const TranslationCardWidget({
    super.key,
    required this.card,
    required this.expanded,
    required this.current,
    required this.playing,
    required this.onToggle,
    required this.onPlay,
    required this.onArchive,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    final pad = 18.0 * theme.density;
    final isProcessing = card.status == CardStatus.processing;

    return GestureDetector(
      onTap: isProcessing ? null : () => onToggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.32, 0.72, 0, 1),
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: current ? theme.colors.surface2 : theme.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: current ? theme.accent : theme.colors.border,
            width: 1,
          ),
          boxShadow: current
              ? [
                  BoxShadow(color: theme.accent, blurRadius: 0, spreadRadius: 1),
                  BoxShadow(color: theme.accent, blurRadius: 0, spreadRadius: 1),
                  const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                    spreadRadius: 0,
                  ),
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: const Cubic(0.32, 0.72, 0, 1),
          alignment: Alignment.topCenter,
          child: isProcessing ? _buildProcessing(theme) : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildProcessing(LingoTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Shimmer(width: null, height: 24, borderRadius: 7),
        const SizedBox(height: 9),
        const Shimmer(width: null, height: 24, borderRadius: 7),
        const SizedBox(height: 12),
        Text(
          card.en,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: theme.colors.inkSoft,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Spinner(accent: theme.accent, borderStrong: theme.colors.borderStrong),
            const SizedBox(width: 8),
            Text(
              'Translating to Japanese…',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.66,
                color: theme.colors.inkSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(LingoTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.jp,
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: theme.colors.ink,
                      letterSpacing: 0.01,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.en,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: theme.colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            PlayDOT(playing: playing, onTap: () => onPlay()),
          ],
        ),
        if (card.archived && !expanded)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconArchive(size: 13, color: theme.colors.inkFaint),
                  const SizedBox(width: 5),
                  Text(
                    'Archived',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 0.63,
                      color: theme.colors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!expanded)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: 0.55,
                child: IconChevron(size: 16, color: theme.colors.inkFaint),
              ),
            ),
          ),
        if (expanded) _buildExpanded(theme),
      ],
    );
  }

  Widget _buildExpanded(LingoTheme theme) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Divider(height: 1, thickness: 1, color: theme.colors.border),
        const SizedBox(height: 6),
        MetaRow(
          icon: IconType(size: 16, color: theme.colors.inkFaint),
          label: 'Reading',
          value: card.romaji,
          mono: true,
        ),
        MetaRow(
          icon: IconClock(size: 16, color: theme.colors.inkFaint),
          label: 'Created',
          value: fullTime(card.createdAt),
        ),
        MetaRow(
          icon: IconSpeaker(size: 16, color: theme.colors.inkFaint),
          label: 'Played',
          value: '${card.plays} times',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (card.archived)
              ActionBtn(
                icon: IconRestore(size: 17, color: theme.colors.ink),
                label: 'Restore',
                onTap: () => onRestore(),
              )
            else
              ActionBtn(
                icon: IconArchive(size: 17, color: theme.colors.ink),
                label: 'Archive',
                onTap: () => onArchive(),
              ),
            const SizedBox(width: 10),
            ActionBtn(
              icon: IconTrash(size: 17, color: theme.colors.ink),
              label: 'Delete',
              danger: true,
              onTap: () => onDelete(),
            ),
          ],
        ),
      ],
    );
  }
}

class _Spinner extends StatefulWidget {
  final Color accent;
  final Color borderStrong;

  const _Spinner({required this.accent, required this.borderStrong});

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(
        value: null,
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
        backgroundColor: widget.borderStrong,
      ),
    );
  }
}
