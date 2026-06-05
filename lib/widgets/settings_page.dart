import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../utils/theme.dart';
import 'icons.dart';
import 'filter_bar.dart';

const accentOptions = [
  AccentOption(
    id: 'mono',
    name: 'Monochrome',
    accent: '#3A3A3F',
    onAccent: '#FFFFFF',
    swatch: '#0E0E10',
  ),
  AccentOption(
    id: 'blue',
    name: 'Blue',
    accent: '#3B82F6',
    onAccent: '#FFFFFF',
    swatch: '#3B82F6',
  ),
  AccentOption(
    id: 'amber',
    name: 'Amber',
    accent: '#F59E0B',
    onAccent: '#1A1407',
    swatch: '#F59E0B',
  ),
  AccentOption(
    id: 'green',
    name: 'Green',
    accent: '#10B981',
    onAccent: '#FFFFFF',
    swatch: '#10B981',
  ),
];

const _languages = [
  LanguageOption(id: 'jp', name: 'Japanese', native: '日本語', enabled: true),
  LanguageOption(id: 'ko', name: 'Korean', native: '한국어', enabled: false),
  LanguageOption(id: 'zh', name: 'Chinese', native: '中文', enabled: false),
  LanguageOption(id: 'es', name: 'Spanish', native: 'Español', enabled: false),
];

const _spacingOptions = [
  SpacingOption(id: 'compact', label: 'Compact'),
  SpacingOption(id: 'cozy', label: 'Cozy'),
  SpacingOption(id: 'comfortable', label: 'Spacious'),
];

Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class SettingsPage extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChange;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Positioned.fill(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 22),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: theme.colors.ink,
                ),
              ),
            ),
            _Section(
              title: 'Translation language',
              child: Column(
                children: _languages.map((l) {
                  final active = settings.lang == l.id;
                  return GestureDetector(
                    onTap: l.enabled ? () => onChange(settings.copyWith(lang: l.id)) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: const Cubic(0.32, 0.72, 0, 1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: active ? theme.colors.surface2 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? theme.colors.borderStrong : Colors.transparent,
                        ),
                      ),
                      child: Opacity(
                        opacity: l.enabled ? 1.0 : 0.45,
                        child: Row(
                          children: [
                            IconGlobe(
                              size: 20,
                              color: active ? theme.colors.ink : theme.colors.inkFaint,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                color: theme.colors.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.native,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colors.inkSoft,
                              ),
                            ),
                            if (!l.enabled) ...[
                              const Spacer(),
                              Text(
                                'soon',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  color: theme.colors.inkFaint,
                                ),
                              ),
                            ],
                            if (active) ...[
                              const Spacer(),
                              IconCheck(size: 19, sw: 2.4, color: theme.accent),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            _Section(
              title: 'Appearance',
              child: Column(
                children: [
                  Row(
                    children: [
                      settings.theme == 'dark'
                          ? IconMoon(size: 20, color: theme.colors.ink)
                          : IconSun(size: 20, color: theme.colors.ink),
                      const SizedBox(width: 12),
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.colors.ink,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 168,
                      child: SegmentedControl(
                            options: const [
                              SegmentedOption('light', 'Light'),
                              SegmentedOption('dark', 'Dark'),
                            ],
                          value: settings.theme,
                          onChange: (v) => onChange(settings.copyWith(theme: v)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: theme.colors.border),
                  const SizedBox(height: 16),
                  Text(
                    'Accent colour',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: accentOptions.map((a) {
                      final active = settings.accent == a.id;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onChange(settings.copyWith(accent: a.id)),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: const Cubic(0.32, 0.72, 0, 1),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _hexToColor(a.swatch),
                                  shape: BoxShape.circle,
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color: theme.colors.surface,
                                            blurRadius: 0,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: theme.colors.ink,
                                            blurRadius: 0,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: const Color(0x14000000),
                                            blurRadius: 0,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                ),
                                child: active
                                    ? Center(
                                        child: IconCheck(
                                          size: 20,
                                          sw: 2.6,
                                          color: _hexToColor(a.onAccent),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                a.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                  color: active ? theme.colors.ink : theme.colors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Card spacing',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedControl(
                    options: _spacingOptions
                        .map((s) => SegmentedOption(s.id, s.label))
                        .toList(),
                    value: settings.spacing,
                    onChange: (v) => onChange(settings.copyWith(spacing: v)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Controls padding and the gap between cards in your list.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: theme.colors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'LINGO · v1.0',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 0.55,
                  color: theme.colors.inkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: FilterLabel(text: title),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
