import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@time2wish.app');
  final _passwordController = TextEditingController(text: 'password123');
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin([String? email, String? password]) async {
    if (email != null && password != null) {
      _emailController.text = email;
      _passwordController.text = password;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF311042),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Header Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.accentPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withValues(alpha: 0.5),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text('🎂', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFFA855F7)],
                    ).createShader(bounds),
                    child: const Text(
                      'Time2Wish',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'N\'oubliez plus jamais un anniversaire',
                    style: TextStyle(color: AppColors.textMutedDark, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism Form Card
                  GlassCard(
                    blurAmount: 20,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: AppColors.textMutedDark),
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMutedDark),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty || !val.contains('@')) {
                                return 'Veuillez entrer un email valide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              labelStyle: const TextStyle(color: AppColors.textMutedDark),
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMutedDark),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 4) {
                                return 'Le mot de passe doit contenir au moins 4 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authService.isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 8,
                                shadowColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                              ),
                              child: authService.isLoading
                                  ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                                  : const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(color: AppColors.textMutedDark),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
