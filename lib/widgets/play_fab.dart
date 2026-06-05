import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'icons.dart';

class PlayFAB extends StatelessWidget {
  final bool playing;
  final bool isPaused;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final int index;
  final int total;

  const PlayFAB({
    super.key,
    required this.playing,
    required this.isPaused,
    required this.onTap,
    required this.onReset,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Positioned(
      right: 18,
      bottom: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playing)
            _CounterPill(theme: theme, index: index, total: total),
          if (isPaused && !playing)
            Row(
              children: [
                _FabButton(color: theme.colors.surface, border: true, onTap: onReset, child: Icon(Icons.restart_alt_rounded, size: 20, color: theme.colors.ink)),
                const SizedBox(width: 10),
                _FabButton(color: theme.accent, onTap: onTap, child: Padding(padding: const EdgeInsets.only(left: 2), child: IconPlay(size: 24, color: theme.onAccent))),
              ],
            )
          else
            _FabButton(
              color: theme.accent,
              onTap: onTap,
              child: playing ? IconPause(size: 24, color: theme.onAccent) : Padding(padding: const EdgeInsets.only(left: 2), child: IconPlay(size: 24, color: theme.onAccent)),
            ),
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final LingoTheme theme;
  final int index;
  final int total;
  const _CounterPill({required this.theme, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.border),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Text('${index + 1}/$total', style: TextStyle(fontFamily: 'monospace', fontSize: 10.5, fontWeight: FontWeight.w500, color: theme.colors.ink)),
    );
  }
}

class _FabButton extends StatelessWidget {
  final Color color;
  final bool border;
  final VoidCallback onTap;
  final Widget child;

  const _FabButton({required this.color, this.border = false, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: border ? Border.all(color: const Color(0xFFD6D6D9), width: 1.5) : null,
          boxShadow: const [
            BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, 12)),
            BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String query;
  const EmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: theme.colors.surface2, shape: BoxShape.circle, border: Border.all(color: theme.colors.border)), child: Center(child: IconLayers(size: 28, color: theme.colors.inkFaint))),
          const SizedBox(height: 12),
          Text(query.isNotEmpty ? 'No matches' : 'No cards yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colors.ink)),
          const SizedBox(height: 4),
          Text(query.isNotEmpty ? 'Try a different search term.' : 'Tap the mic below to dictate your first phrase.', style: TextStyle(fontSize: 13.5, color: theme.colors.inkSoft, height: 1.45), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
