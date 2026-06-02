import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AdaptiveThemeMode selectedTheme = AdaptiveTheme.of(context).mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Text('Dark mode', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SegmentedButton<AdaptiveThemeMode>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: .compact,
                          tapTargetSize: .shrinkWrap,
                          textStyle: .all(TextStyle(fontSize: 12)),
                        ),
                        segments: [
                          ButtonSegment(
                            label: Text('Light'),
                            value: AdaptiveThemeMode.light,
                          ),
                          ButtonSegment(
                            label: Text('System'),
                            value: AdaptiveThemeMode.system,
                          ),
                          ButtonSegment(
                            label: Text('Dark'),
                            value: AdaptiveThemeMode.dark,
                          ),
                        ],
                        selected: {selectedTheme},
                        onSelectionChanged:
                            (Set<AdaptiveThemeMode> newSelection) {
                              setState(() {
                                selectedTheme = newSelection.first;
                              });

                              AdaptiveTheme.of(
                                context,
                              ).setThemeMode(selectedTheme);
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
