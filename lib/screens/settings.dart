import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_sudoku/shared/localization.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.fromRoot});

  final bool fromRoot;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String appLang = Hive.box('settings').get('language', defaultValue: 'EN');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.blue.shade900,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    appText[appLang]!['settings']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(child: Container()),
                  if (widget.fromRoot)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          String currentLang = Hive.box('settings')
                              .get('language', defaultValue: 'EN');
                          String newLang = currentLang == 'EN' ? 'TR' : 'EN';
                          Hive.box('settings').put('language', newLang);
                          setState(() {});
                        },
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.asset('assets/language_$appLang.png'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Settings List
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('settings').listenable(),
                builder: (context, value, child) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SettingsCard(
                            text: appText[appLang]!['hint_limit']!,
                            icon: Icons.lightbulb_outline,
                            settName: 'hintLimit',
                            defaultValue: true,
                            hasSlider: false,
                          ),
                          SettingsCard(
                            text: appText[appLang]!['mistake_limit']!,
                            icon: Icons.highlight_off_sharp,
                            settName: 'mistakesLimit',
                            defaultValue: true,
                            hasSlider: false,
                          ),
                          SettingsCard(
                            text: appText[appLang]!['region_high']!,
                            icon: Icons.games_rounded,
                            settName: 'regHigh',
                            defaultValue: true,
                            hasSlider: false,
                          ),
                          SettingsCard(
                            text: appText[appLang]!['number_high']!,
                            icon: Icons.numbers_outlined,
                            settName: 'numHigh',
                            defaultValue: true,
                            hasSlider: false,
                          ),
                        ],
                      ),
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

class SettingsCard extends StatefulWidget {
  const SettingsCard({
    super.key,
    required this.text,
    required this.icon,
    required this.settName,
    required this.defaultValue,
    required this.hasSlider,
    this.showTopDivider = true,
  });

  final String text;
  final IconData icon;
  final String settName;
  final bool defaultValue;
  final bool hasSlider;
  final bool showTopDivider;

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool value = Hive.box('settings').get(widget.settName, defaultValue: widget.defaultValue);
    String appLang = Hive.box('settings').get('language', defaultValue: 'EN');

    return Column(
      children: [
        if (widget.showTopDivider)
          Divider(
            height: 1,
            color: Colors.grey[200],
            indent: 16,
            endIndent: 16,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 24,
                    color: Colors.blue.shade900,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: (newValue) {
                      setState(() {
                        value = newValue;
                        Hive.box('settings').put(widget.settName, value);
                      });
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 40),
                child: Text(
                  appText[appLang]!['${widget.settName}_descr']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}