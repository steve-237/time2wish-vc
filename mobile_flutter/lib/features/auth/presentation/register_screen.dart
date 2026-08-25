import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Inscription échouée. Cet email est peut-être déjà utilisé.';
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentPink],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPink.withValues(alpha: 0.5),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Glassmorphism Form Card
                  GlassCard(
                    blurAmount: 20,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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

                          // Full Name Field
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Nom complet',
                              labelStyle: const TextStyle(color: AppColors.textMutedDark),
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMutedDark),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Veuillez entrer votre nom';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

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
                              if (val == null || val.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authService.isLoading ? null : _submitRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 8,
                                shadowColor: AppColors.accentPurple.withValues(alpha: 0.5),
                              ),
                              child: authService.isLoading
                                  ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                                  : const Text(
                                      'Créer mon compte',
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
                        'Déjà un compte ? ',
                        style: TextStyle(color: AppColors.textMutedDark),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text(
                          'Se connecter',
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
