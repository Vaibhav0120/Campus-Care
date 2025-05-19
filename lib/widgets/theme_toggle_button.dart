import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_care/providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  
  const ThemeToggleButton({
    Key? key,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return PopupMenuButton<String>(
      icon: Icon(
        isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: theme.appBarTheme.foregroundColor,
      ),
      tooltip: 'Change theme',
      onSelected: (String value) {
        switch (value) {
          case 'system':
            themeProvider.setSystemTheme();
            break;
          case 'light':
            themeProvider.setLightTheme();
            break;
          case 'dark':
            themeProvider.setDarkTheme();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'system',
          child: Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 8),
              const Text('System'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'light',
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 8),
              const Text('Light'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'dark',
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 8),
              const Text('Dark'),
            ],
          ),
        ),
      ],
    );
  }
}
