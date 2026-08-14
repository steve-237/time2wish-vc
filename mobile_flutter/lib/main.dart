import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/birthday_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/navigation/main_nav_shell.dart';
import 'features/birthdays/presentation/birthday_detail_screen.dart';
import 'features/birthdays/presentation/birthday_form_screen.dart';
import 'features/profile/presentation/profile_edit_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _authService = AuthService(_apiService);
    _birthdayService = BirthdayService(_apiService);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<BirthdayService>.value(value: _birthdayService),
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
