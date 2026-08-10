import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/navigation/main_nav_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Time2WishApp());
}

class Time2WishApp extends StatelessWidget {
  const Time2WishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(context.read<ApiService>()),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          final GoRouter router = GoRouter(
            initialLocation: '/dashboard',
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
            ],
            redirect: (context, state) {
              final loggingIn = state.matchedLocation == '/login' ||
                  state.matchedLocation == '/register';

              if (!authService.isAuthenticated && !loggingIn) {
                return '/login';
              }
              if (authService.isAuthenticated && loggingIn) {
                return '/dashboard';
              }
              return null;
            },
          );

          return MaterialApp.router(
            title: 'Time2Wish Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
