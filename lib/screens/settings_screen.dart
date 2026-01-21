import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/translations.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final ValueChanged<String>? onLanguageChanged;
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    this.onThemeChanged,
    this.onLanguageChanged,
    this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkTheme;
  late bool _notificationsEnabled;
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isDark = await PreferencesService.isDarkTheme();
    final notificationsEnabled = await PreferencesService.areNotificationsEnabled();
    final language = await PreferencesService.getLanguage();

    setState(() {
      _isDarkTheme = isDark;
      _notificationsEnabled = notificationsEnabled;
      _currentLanguage = language;
    });
  }

  Future<void> _handleThemeChange(bool value) async {
    await PreferencesService.setDarkTheme(value);
    setState(() {
      _isDarkTheme = value;
    });
    widget.onThemeChanged?.call(value);
  }

  Future<void> _handleNotificationsChange(bool value) async {
    await PreferencesService.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _handleLanguageChange(String? language) async {
    if (language != null) {
      await PreferencesService.setLanguage(language);
      setState(() {
        _currentLanguage = language;
      });
      widget.onLanguageChanged?.call(language);
    }
  }

  Future<void> _handleLogout() async {
    final t = (String key) => Translations.translate(key, _currentLanguage);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await PreferencesService.clearAll();
              if (mounted) {
                Navigator.pop(context);
                widget.onLogout?.call();
              }
            },
            child: Text(t('yes')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = (String key) => Translations.translate(key, _currentLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('settings')),
      ),
      body: ListView(
        children: [
          // Theme Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('theme'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: Text(_isDarkTheme ? t('darkTheme') : t('lightTheme')),
                    subtitle: Text(_isDarkTheme ? 'Dark Mode' : 'Light Mode'),
                    value: _isDarkTheme,
                    onChanged: _handleThemeChange,
                    secondary: Icon(
                      _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('notifications'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: Text(_notificationsEnabled
                        ? t('notification_enabled')
                        : t('notification_disabled')),
                    value: _notificationsEnabled,
                    onChanged: _handleNotificationsChange,
                    secondary: Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Language Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('language'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: DropdownButton<String>(
                      value: _currentLanguage,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text(t('spanish')),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(t('english')),
                        ),
                      ],
                      onChanged: _handleLanguageChange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Logout Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: Text(t('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
