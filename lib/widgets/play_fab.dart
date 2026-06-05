import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'icons.dart';

class PlayFAB extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  final int index;
  final int total;

  const PlayFAB({
    super.key,
    required this.playing,
    required this.onTap,
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
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.colors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '${index + 1}/$total',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: theme.colors.ink,
                ),
              ),
            ),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: const Cubic(0.32, 0.72, 0, 1),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.accent,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E000000),
                    blurRadius: 40,
                    offset: Offset(0, 12),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: playing
                    ? IconPause(size: 24, color: theme.onAccent)
                    : Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: IconPlay(size: 24, color: theme.onAccent),
                      ),
              ),
            ),
          ),
        ],
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colors.border),
            ),
            child: Center(
              child: IconLayers(size: 28, color: theme.colors.inkFaint),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty ? 'No matches' : 'No cards yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            query.isNotEmpty
                ? 'Try a different search term.'
                : 'Tap the mic below to dictate your first phrase.',
            style: TextStyle(
              fontSize: 13.5,
              color: theme.colors.inkSoft,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
