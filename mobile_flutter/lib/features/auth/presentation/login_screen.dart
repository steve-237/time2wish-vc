import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscurePassword = true;

  // Staggered fade-in animations
  late AnimationController _animController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 4 staggered elements: logo, title, form card, register link
    _fadeAnims = List.generate(4, (i) {
      final start = (i * 0.2).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(4, (i) {
      final start = (i * 0.2).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 30),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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

  void _showOfflineLoginModal(BuildContext context, bool isDark, AuthService authService) {
    final usernameController = TextEditingController(text: 'Invité Time2Wish');
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          child: GlassCard(
            blurAmount: 24,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_off_rounded, color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connexion Hors-ligne 🚀',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textMainLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stockage 100% autonome sur votre appareil',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Entrez votre prénom ou pseudo. Toutes vos données seront enregistrées localement sans dépendance réseau.',
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                const SizedBox(height: 16),

                // Username input
                TextField(
                  controller: usernameController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                  decoration: InputDecoration(
                    labelText: 'Nom d\'utilisateur ou Prénom',
                    labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    prefixIcon: Icon(Icons.person_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF141B26) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // Email local (optionnel)
                TextField(
                  controller: emailController,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                  decoration: InputDecoration(
                    labelText: 'Email local (optionnel)',
                    hintText: 'ex: invite@time2wish.local',
                    hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark.withValues(alpha: 0.6) : AppColors.textMutedLight.withValues(alpha: 0.6), fontSize: 13),
                    labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    prefixIcon: Icon(Icons.email_outlined, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF141B26) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),

                // Button submit
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final name = usernameController.text.trim();
                      final email = emailController.text.trim();
                      Navigator.pop(ctx);
                      final success = await authService.loginOffline(
                        username: name.isNotEmpty ? name : 'Invité Local',
                        email: email.isNotEmpty ? email : null,
                      );
                      if (success && mounted) {
                        context.go('/dashboard');
                      }
                    },
                    icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Démarrer en Mode Hors-ligne',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedChild(int index, Widget child) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) => Opacity(
        opacity: _fadeAnims[index].value,
        child: Transform.translate(
          offset: _slideAnims[index].value,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settings = Provider.of<SettingsService>(context);
    final isDark = settings.isDarkMode;

    final primaryColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
    final textMain = isDark ? Colors.white : AppColors.textMainLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final inputBg = isDark ? const Color(0xFF141B26) : const Color(0xFFF8FAFC);
    final borderCol = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder;

    return Scaffold(
      body: Container(
        color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _animatedChild(
                    0,
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: AppColors.accentPurple.withValues(alpha: 0.25),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/branding/time2wish_icon_192.png',
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text('🎂', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  _animatedChild(
                    1,
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                          ).createShader(bounds),
                          child: Text(
                            'Time2Wish',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 34,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'N\'oubliez plus jamais un anniversaire',
                          style: TextStyle(color: textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Card
                  _animatedChild(
                    2,
                    GlassCard(
                      blurAmount: 24,
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Connexion',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPink.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accentPink.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.accentPink, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: AppColors.accentPink, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textMain),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: textMuted),
                                prefixIcon: Icon(Icons.email_outlined, color: textMuted),
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderCol),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderCol),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: primaryColor, width: 1.5),
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

                            // Password Field with toggle
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: textMain),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle: TextStyle(color: textMuted),
                                prefixIcon: Icon(Icons.lock_outline, color: textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderCol),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderCol),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: primaryColor, width: 1.5),
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

                            // Gradient Submit Button
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: authService.isLoading ? null : _submitLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
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
                            const SizedBox(height: 10),

                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _emailController.text = 'demo@time2wish.app';
                                    _passwordController.text = 'password123';
                                  });
                                },
                                icon: const Icon(Icons.bolt_rounded, color: AppColors.wishCoinsAmber, size: 18),
                                label: Text(
                                  'Remplir le compte démo',
                                  style: TextStyle(color: textMuted, fontSize: 13),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Separator
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.white12 : AppColors.lightBorder)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'OU SANS COMPTE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.white12 : AppColors.lightBorder)),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Offline Mode Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.45)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                foregroundColor: primaryColor,
                              ),
                              onPressed: () => _showOfflineLoginModal(context, isDark, authService),
                              icon: const Icon(Icons.wifi_off_rounded, size: 18),
                              label: const Text(
                                'Mode Hors-ligne (Invité) 🚀',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Register link
                  _animatedChild(
                    3,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ? ',
                          style: TextStyle(color: textMuted),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
