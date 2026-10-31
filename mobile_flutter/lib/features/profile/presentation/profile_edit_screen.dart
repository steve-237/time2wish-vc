import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;

  String? _selectedPhotoBase64;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    _selectedPhotoBase64 = user?.avatarUrl;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      DeviceService.playTapSound();
      DeviceService.triggerLightHaptic();

      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedPhotoBase64 = base64String;
          _avatarUrlController.text = base64String;
        });

        DeviceService.playSuccessSound();
        DeviceService.triggerSuccessHaptic();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.photo_library_rounded, color: AppColors.primaryCyan, size: 20),
                  SizedBox(width: 8),
                  Text('✓ Photo de profil chargée depuis la galerie !'),
                ],
              ),
              backgroundColor: AppColors.surfaceDark,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[ProfileEditScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder à la galerie d\'images'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    }
  }

  void _showPhotoPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photo de profil',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textMainLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Option 1: Gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryCyan),
                ),
                title: Text(
                  'Galerie du téléphone 📱',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Choisir une photo dans vos albums',
                  style: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              // Option 2: Camera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.accentPink),
                ),
                title: Text(
                  'Prendre une photo 📸',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Ouvrir l\'appareil photo',
                  style: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedPhotoBase64 != null && _selectedPhotoBase64!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.accentPink),
                  ),
                  title: const Text(
                    'Supprimer la photo',
                    style: TextStyle(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedPhotoBase64 = null;
                      _avatarUrlController.text = '';
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialFallback(String initial) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMutedDark),
      prefixIcon: Icon(icon, color: AppColors.textMutedDark, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    DeviceService.triggerMediumHaptic();

    final authService = context.read<AuthService>();
    final newAvatar = (_selectedPhotoBase64 != null && _selectedPhotoBase64!.isNotEmpty)
        ? _selectedPhotoBase64
        : (_avatarUrlController.text.trim().isNotEmpty ? _avatarUrlController.text.trim() : null);

    await authService.updateProfile(
      fullName: _nameController.text.trim(),
      avatarUrl: newAvatar,
      bio: _bioController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      DeviceService.playCelebrationSound();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
              SizedBox(width: 8),
              Text('✓ Profil et photo mis à jour avec succès'),
            ],
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final isDark = settings.isDarkMode;
    final initial = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Modifier le Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: _slideAnimation.value,
                child: child,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      blurAmount: 24,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar Picker Section
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showPhotoPicker(context, isDark),
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primaryCyan, AppColors.accentPurple],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryCyan.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: ClipOval(
                                      child: (_selectedPhotoBase64 != null && _selectedPhotoBase64!.isNotEmpty)
                                          ? AvatarImage(
                                              photoUrl: _selectedPhotoBase64!,
                                              width: 92,
                                              height: 92,
                                              fit: BoxFit.cover,
                                              fallback: _buildInitialFallback(initial),
                                            )
                                          : _buildInitialFallback(initial),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showPhotoPicker(context, isDark),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryCyan,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Button to pick directly from gallery
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryCyan,
                              backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text(
                              'Importer depuis la galerie',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(Icons.person, color: AppColors.primaryCyan, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Informations personnelles',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDecoration('Nom complet', Icons.badge_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer votre nom';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _bioController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: _fieldDecoration('Bio / Présentation (optionnel)', Icons.edit_note_outlined),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _avatarUrlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDecoration('URL de l\'avatar (ou base64)', Icons.link_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Consumer<SettingsService>(
                      builder: (context, settings, _) {
                        return GlassCard(
                          blurAmount: 24,
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                                    ),
                                    child: const Icon(Icons.palette_outlined, color: AppColors.accentPurple, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    settings.tr('appearance'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                        color: settings.isDarkMode ? AppColors.primaryCyan : AppColors.wishCoinsAmber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        settings.isDarkMode ? settings.tr('dark_mode') : settings.tr('light_mode'),
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: settings.isDarkMode,
                                    activeThumbColor: AppColors.primaryCyan,
                                    onChanged: (_) => settings.toggleDarkMode(),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.language, color: AppColors.successGreen, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        settings.tr('language'),
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('FR 🇫🇷', style: TextStyle(fontSize: 11)),
                                        selected: settings.language == 'fr',
                                        onSelected: (_) => settings.setLanguage('fr'),
                                        selectedColor: AppColors.primaryCyan,
                                      ),
                                      ChoiceChip(
                                        label: const Text('EN 🇬🇧', style: TextStyle(fontSize: 11)),
                                        selected: settings.language == 'en',
                                        onSelected: (_) => settings.setLanguage('en'),
                                        selectedColor: AppColors.primaryCyan,
                                      ),
                                      ChoiceChip(
                                        label: const Text('DE 🇩🇪', style: TextStyle(fontSize: 11)),
                                        selected: settings.language == 'de',
                                        onSelected: (_) => settings.setLanguage('de'),
                                        selectedColor: AppColors.primaryCyan,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => context.pop(),
                            child: const Text('Annuler', style: TextStyle(color: AppColors.textMutedDark, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveProfile,
                              child: _isSaving
                                  ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                                  : const Text(
                                      'Enregistrer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
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
      ),
    );
  }
}
