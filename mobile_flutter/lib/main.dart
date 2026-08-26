import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/birthday_service.dart';
import 'core/services/contact_service.dart';
import 'core/services/messaging_service.dart';
import 'core/services/gift_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/navigation/main_nav_shell.dart';
import 'features/birthdays/presentation/birthday_detail_screen.dart';
import 'features/birthdays/presentation/birthday_form_screen.dart';
import 'features/messaging/presentation/chat_screen.dart';
import 'features/profile/presentation/profile_edit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const Time2WishApp());
}

class Time2WishApp extends StatefulWidget {
  const Time2WishApp({super.key});

  @override
  State<Time2WishApp> createState() => _Time2WishAppState();
}

class _Time2WishAppState extends State<Time2WishApp> {
  late final ApiService _apiService;
  late final AuthService _authService;
  late final BirthdayService _birthdayService;
  late final ContactService _contactService;
  late final MessagingService _messagingService;
  late final GiftService _giftService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _authService = AuthService(_apiService);
    _birthdayService = BirthdayService(_apiService);
    _contactService = ContactService(_apiService);
    _messagingService = MessagingService(_apiService);
    _giftService = GiftService(_apiService);

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _authService,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const MainNavShell(),
        ),
        GoRoute(
          path: '/birthday/new',
          builder: (context, state) => const BirthdayFormScreen(),
        ),
        GoRoute(
          path: '/birthday/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return BirthdayDetailScreen(birthdayId: id);
          },
        ),
        GoRoute(
          path: '/birthday/:id/edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return BirthdayFormScreen(birthdayId: id);
          },
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ChatScreen(conversationId: id);
          },
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const ProfileEditScreen(),
        ),
      ],
      redirect: (context, state) {
        final isLoggedIn = _authService.isAuthenticated;
        final isOnAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn && !isOnAuth) return '/login';
        if (isLoggedIn && isOnAuth) return '/dashboard';
        return null;
      },
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _authService.dispose();
    _birthdayService.dispose();
    _contactService.dispose();
    _messagingService.dispose();
    _giftService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<BirthdayService>.value(value: _birthdayService),
        ChangeNotifierProvider<ContactService>.value(value: _contactService),
        ChangeNotifierProvider<MessagingService>.value(value: _messagingService),
        ChangeNotifierProvider<GiftService>.value(value: _giftService),
      ],
      child: MaterialApp.router(
        title: 'Time2Wish Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
