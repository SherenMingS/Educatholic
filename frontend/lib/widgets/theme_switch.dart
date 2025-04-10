import 'package:flutter/material.dart';
import 'package:frontend/main.dart'; // Pastikan ini ada untuk akses themeNotifier

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
        Switch(
          value: isDarkMode,
          onChanged: (value) {
            MyApp.themeNotifier.value =
                value ? ThemeMode.dark : ThemeMode.light;
          },
        ),
      ],
    );
  }
}
