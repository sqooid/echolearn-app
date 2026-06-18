import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings.dart';
import '../utils/theme.dart';
import '../viewmodels/cards_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../services/backup_service.dart';
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
            _Section(
              title: 'Shadow pause',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StepButton(
                        icon: IconMinus(size: 16, sw: 2.5, color: theme.colors.ink),
                        onTap: () {
                          final v = (settings.delaySeconds - 0.5).clamp(0.0, double.infinity).toDouble();
                          onChange(settings.copyWith(delaySeconds: v));
                        },
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: TextField(
                          controller: _DelayController(settings.delaySeconds.toString()),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            final d = double.tryParse(v.replaceAll(',', '.'));
                            if (d != null && d >= 0) {
                              onChange(settings.copyWith(delaySeconds: d));
                            }
                          },
                          style: TextStyle(fontSize: 14.5, color: theme.colors.ink),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colors.borderStrong)),
                            suffixText: 's',
                            suffixStyle: TextStyle(fontSize: 13, color: theme.colors.inkSoft),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StepButton(
                        icon: IconPlus(size: 16, sw: 2.5, color: theme.colors.ink),
                        onTap: () {
                          final v = settings.delaySeconds + 0.5;
                          onChange(settings.copyWith(delaySeconds: v));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Add clip length', style: TextStyle(fontSize: 14, color: theme.colors.ink)),
                      const Spacer(),
                      Toggle(
                        on: settings.delayAddClip,
                        onChange: (v) => onChange(settings.copyWith(delayAddClip: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Pause between cards during playback. Increments by 0.5s.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: theme.colors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Behavior',
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Confirm before delete', style: TextStyle(fontSize: 14, color: theme.colors.ink)),
                      const Spacer(),
                      Toggle(
                        on: settings.confirmDelete,
                        onChange: (v) => onChange(settings.copyWith(confirmDelete: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Scroll to currently playing card', style: TextStyle(fontSize: 14, color: theme.colors.ink)),
                      const Spacer(),
                      Toggle(
                        on: settings.scrollToPlaying,
                        onChange: (v) => onChange(settings.copyWith(scrollToPlaying: v)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Backup & Restore',
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => BackupService.exportBackup(),
                      icon: Icon(Icons.upload, size: 18, color: theme.colors.ink),
                      label: Text('Export backup', style: TextStyle(fontSize: 14, color: theme.colors.ink)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colors.borderStrong),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final path = await BackupService.pickBackupFile();
                        if (path == null) return;
                        await BackupService.restoreBackup(path);
                        if (!context.mounted) return;
                        final cardsVm = context.read<CardsViewModel>();
                        final settingsVm = context.read<SettingsViewModel>();
                        await settingsVm.load();
                        cardsVm.repository.setApiKey(settingsVm.settings.apiKey);
                        await cardsVm.load();
                        onChange(settingsVm.settings);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup restored')),
                        );
                      },
                      icon: Icon(Icons.download, size: 18, color: theme.colors.ink),
                      label: Text('Restore backup', style: TextStyle(fontSize: 14, color: theme.colors.ink)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colors.borderStrong),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              title: 'API key',
              child: TextField(
                obscureText: true,
                controller: _ApiKeyController(settings.apiKey),
                onChanged: (v) => onChange(settings.copyWith(apiKey: v)),
                style: TextStyle(fontSize: 14.5, color: theme.colors.ink, height: 1.3),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Enter API key…',
                  hintStyle: TextStyle(fontSize: 14.5, color: theme.colors.inkFaint),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colors.borderStrong)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colors.borderStrong)),
                  suffixIcon: settings.apiKey.isNotEmpty
                      ? IconButton(
                          icon: IconClose(size: 16, color: theme.colors.inkFaint),
                          onPressed: () => onChange(settings.copyWith(apiKey: '')),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/sqooid/echolearn-app/issues/new'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Send feedback \u2192',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colors.inkSoft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '0.1';
                return Text(
                  'EchoLearn · v$version',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 0.55,
                    color: theme.colors.inkFaint,
                  ),
                );
              },
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

class _ApiKeyController extends TextEditingController {
  _ApiKeyController(String text) : super(text: text);
}

class _DelayController extends TextEditingController {
  _DelayController(String text) : super(text: text);
}

class _StepButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = LingoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colors.borderStrong),
          color: theme.colors.surface2,
        ),
        child: Center(child: icon),
      ),
    );
  }
}
