import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'icons.dart';

class NavButton extends StatefulWidget {
  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Opacity(
        opacity: _pressed ? 0.7 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: const Cubic(0.32, 0.72, 0, 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: widget.active ? theme.colors.ink : theme.colors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  final String page;
  final VoidCallback onNavMain;
  final VoidCallback onNavSettings;
  final VoidCallback onMic;
  final bool micActive;

  const BottomBar({
    super.key,
    required this.page,
    required this.onNavMain,
    required this.onNavSettings,
    required this.onMic,
    required this.micActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 14,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: NavButton(
                    icon: IconHome(size: 24, sw: page == 'main' ? 2.1 : 1.8, color: page == 'main' ? theme.colors.ink : theme.colors.inkFaint),
                    label: 'Cards',
                    active: page == 'main',
                    onTap: onNavMain,
                  ),
                ),
                const SizedBox(width: 84),
                Expanded(
                  child: NavButton(
                    icon: IconSettings(size: 24, sw: page == 'settings' ? 2.1 : 1.8, color: page == 'settings' ? theme.colors.ink : theme.colors.inkFaint),
                    label: 'Settings',
                    active: page == 'settings',
                    onTap: onNavSettings,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -16,
            child: Center(
              child: GestureDetector(
                onTap: onMic,
                child: AnimatedScale(
                  scale: micActive ? 0.94 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: const Cubic(0.32, 0.72, 0, 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: const Cubic(0.32, 0.72, 0, 1),
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: micActive ? theme.colors.ink : theme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colors.surface, width: 3),
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
                      child: IconMic(
                        size: 28,
                        sw: 2,
                        color: micActive ? theme.colors.surface : theme.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
