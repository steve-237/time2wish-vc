import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _themeKey = 'app_theme_mode';
  static const _langKey = 'app_language';

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'fr'; // 'fr', 'en', or 'de'
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
    if (lang != 'fr' && lang != 'en' && lang != 'de') return;
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
      'select_language': 'Choisir la langue',
      'french': 'Français 🇫🇷',
      'english': 'English 🇬🇧',
      'german': 'Deutsch 🇩🇪',
      'ai_wish': 'Générer un vœu avec l\'IA ✨',
      'ai_gifts': 'Idées Cadeaux par l\'IA 💡',
      'fundraiser': 'Cagnotte Collective 💰',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'add': 'Ajouter',
      'add_birthday': 'Ajouter un anniversaire',
      'contribute': 'Participer',
      'logout': 'Déconnexion',
      'search_hint': 'Rechercher un anniversaire, une catégorie...',
      'filter_all': 'Tous',
      'filter_favorites': 'Favoris',
      'filter_friends': 'Amis',
      'filter_family': 'Famille',
      'filter_work': 'Travail',
      'today': 'Aujourd\'hui ! 🎂',
      'days_remaining': 'jours restants',
      'day_remaining': 'jour restant',
      'next_celebration': 'Prochain anniversaire',
      'no_birthdays': 'Aucun anniversaire trouvé',
      'no_birthdays_sub': 'Appuyez sur le bouton + pour en ajouter un',
      'wish_button': 'Vœu IA ✨',
      'sort_by': 'Trier par',
      'sort_date': 'Date la plus proche',
      'sort_name': 'Nom (A-Z)',
      'sort_favorites': 'Favoris d\'abord',
      'wishcoins': 'WishCoins',
      'offline_status': '100% Autonome & Hors-Ligne',
      'sync_pending': 'action(s) hors-ligne en attente',
      'sync_now': 'Synchroniser',
      'view_all': 'Voir tout',
      'this_month': 'Ce mois',
      'total_birthdays': 'Total',
      'days_unit': 'Jours',
      'hours_unit': 'Heures',
      'app_subtitle': 'Birthday Manager · AI Reminder',
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
      'select_language': 'Select Language',
      'french': 'Français 🇫🇷',
      'english': 'English 🇬🇧',
      'german': 'Deutsch 🇩🇪',
      'ai_wish': 'Generate wish with AI ✨',
      'ai_gifts': 'AI Gift Suggestions 💡',
      'fundraiser': 'Group Fundraiser 💰',
      'save': 'Save',
      'cancel': 'Cancel',
      'add': 'Add',
      'add_birthday': 'Add Birthday',
      'contribute': 'Contribute',
      'logout': 'Log Out',
      'search_hint': 'Search birthday, category...',
      'filter_all': 'All',
      'filter_favorites': 'Favorites',
      'filter_friends': 'Friends',
      'filter_family': 'Family',
      'filter_work': 'Work',
      'today': 'Today! 🎂',
      'days_remaining': 'days left',
      'day_remaining': 'day left',
      'next_celebration': 'Next Celebration',
      'no_birthdays': 'No birthdays found',
      'no_birthdays_sub': 'Tap the + button to add one',
      'wish_button': 'AI Wish ✨',
      'sort_by': 'Sort by',
      'sort_date': 'Earliest date',
      'sort_name': 'Name (A-Z)',
      'sort_favorites': 'Favorites first',
      'wishcoins': 'WishCoins',
      'offline_status': '100% Autonomous & Offline',
      'sync_pending': 'pending offline action(s)',
      'sync_now': 'Sync',
      'view_all': 'View all',
      'this_month': 'This month',
      'total_birthdays': 'Total',
      'days_unit': 'Days',
      'hours_unit': 'Hours',
      'app_subtitle': 'Birthday Manager · AI Reminder',
    },
    'de': {
      'dashboard': 'Dashboard',
      'birthdays': 'Geburtstage',
      'contacts': 'Kontakte',
      'messages': 'Nachrichten',
      'profile': 'Profil',
      'settings': 'Einstellungen',
      'appearance': 'Erscheinungsbild & Thema',
      'dark_mode': 'Dunkler Modus (Glassmorphismus)',
      'light_mode': 'Heller Modus (Pastell)',
      'language': 'Sprache',
      'select_language': 'Sprache wählen',
      'french': 'Français 🇫🇷',
      'english': 'English 🇬🇧',
      'german': 'Deutsch 🇩🇪',
      'ai_wish': 'Wunsch mit KI generieren ✨',
      'ai_gifts': 'KI-Geschenkideen 💡',
      'fundraiser': 'Gemeinsame Sammelkasse 💰',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'add': 'Hinzufügen',
      'add_birthday': 'Geburtstag hinzufügen',
      'contribute': 'Mitmachen',
      'logout': 'Abmelden',
      'search_hint': 'Geburtstag, Kategorie suchen...',
      'filter_all': 'Alle',
      'filter_favorites': 'Favoriten',
      'filter_friends': 'Freunde',
      'filter_family': 'Familie',
      'filter_work': 'Arbeit',
      'today': 'Heute! 🎂',
      'days_remaining': 'Tage verbleibend',
      'day_remaining': 'Tag verbleibend',
      'next_celebration': 'Nächster Geburtstag',
      'no_birthdays': 'Keine Geburtstage gefunden',
      'no_birthdays_sub': 'Tippe auf +, um einen hinzuzufügen',
      'wish_button': 'KI-Wunsch ✨',
      'sort_by': 'Sortieren nach',
      'sort_date': 'Nächstes Datum',
      'sort_name': 'Name (A-Z)',
      'sort_favorites': 'Favoriten zuerst',
      'wishcoins': 'WishCoins',
      'offline_status': '100% Autonom & Offline',
      'sync_pending': 'ausstehende Offline-Aktion(en)',
      'sync_now': 'Sync',
      'view_all': 'Alle anzeigen',
      'this_month': 'Diesen Monat',
      'total_birthdays': 'Gesamt',
      'days_unit': 'Tage',
      'hours_unit': 'Stunden',
      'app_subtitle': 'Birthday Manager · AI Reminder',
    },
  };
}
