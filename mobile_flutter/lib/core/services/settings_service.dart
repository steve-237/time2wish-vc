import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _themeKey = 'app_theme_mode';
  static const _langKey = 'app_language';

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'fr'; // 'fr' or 'en'
  bool _isInitialized = false;

  SettingsService() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark; // Default to dark glassmorphism
    }

    _language = prefs.getString(_langKey) ?? 'fr';
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
            ? 'system'
            : 'dark';
    await prefs.setString(_themeKey, modeStr);
  }

  Future<void> toggleDarkMode() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setLanguage(String lang) async {
    if (lang != 'fr' && lang != 'en') return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  /// Translation helper
  String tr(String key) {
    final map = _translations[_language] ?? _translations['fr']!;
    return map[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'fr': {
      'dashboard': 'Tableau de bord',
      'birthdays': 'Anniversaires',
      'contacts': 'Contacts',
      'messages': 'Messages',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'appearance': 'Apparence & Thème',
      'dark_mode': 'Mode Sombre (Verre dépoli)',
      'light_mode': 'Mode Clair (Pastel)',
      'language': 'Langue',
      'french': 'Français 🇫🇷',
      'english': 'English 🇬🇧',
      'ai_wish': 'Générer un vœu avec l\'IA ✨',
      'ai_gifts': 'Idées Cadeaux par l\'IA 💡',
      'fundraiser': 'Cagnotte Collective 💰',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'add': 'Ajouter',
      'contribute': 'Participer',
      'logout': 'Déconnexion',
    },
    'en': {
      'dashboard': 'Dashboard',
      'birthdays': 'Birthdays',
      'contacts': 'Contacts',
      'messages': 'Messages',
      'profile': 'Profile',
      'settings': 'Settings',
      'appearance': 'Appearance & Theme',
      'dark_mode': 'Dark Mode (Glassmorphism)',
      'light_mode': 'Light Mode (Pastel)',
      'language': 'Language',
      'french': 'Français 🇫🇷',
      'english': 'English 🇬🇧',
      'ai_wish': 'Generate wish with AI ✨',
      'ai_gifts': 'AI Gift Suggestions 💡',
      'fundraiser': 'Group Fundraiser 💰',
      'save': 'Save',
      'cancel': 'Cancel',
      'add': 'Add',
      'contribute': 'Contribute',
      'logout': 'Log Out',
    },
  };
}
