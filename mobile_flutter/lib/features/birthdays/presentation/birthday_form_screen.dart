import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/api_service.dart';

class BirthdayFormScreen extends StatefulWidget {
  final int? birthdayId;

  const BirthdayFormScreen({super.key, this.birthdayId});

  @override
  State<BirthdayFormScreen> createState() => _BirthdayFormScreenState();
}

class _BirthdayFormScreenState extends State<BirthdayFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String _name = '';
  DateTime? _birthdate;
  String _category = 'AUTRE';
  String _gender = 'Autre';
  String _notes = '';
  List<String> _interests = [];
  int _reminderDays = 3;
  bool _isFavorite = false;
  String? _partyLocation;
  String? _partyDescription;
  String? _photoUrl;

  bool _isLoading = false;
  bool _isInitializing = true;
  
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _partyLocationController = TextEditingController();
  final _partyDescriptionController = TextEditingController();
  final _interestController = TextEditingController();

  final List<String> _categories = ['AMIS', 'FAMILLE', 'TRAVAIL', 'AUTRE'];
  final List<String> _genders = ['Homme', 'Femme', 'Autre'];

  @override
  void initState() {
    super.initState();
    _initData();
  }
  
  Future<void> _initData() async {
    if (widget.birthdayId != null) {
      final birthdayService = Provider.of<BirthdayService>(context, listen: false);
      final birthday = birthdayService.getBirthdayById(widget.birthdayId!);
      
      if (birthday != null) {
        setState(() {
          _name = birthday.name;
          _birthdate = birthday.birthdate;
          _category = birthday.category;
          _gender = birthday.gender ?? 'Autre';
          _notes = birthday.notes ?? '';
          _interests = List.from(birthday.interests);
          _reminderDays = birthday.reminderDays;
          _isFavorite = birthday.isFavorite;
          _partyLocation = birthday.partyLocation;
          _partyDescription = birthday.partyDescription;
          _photoUrl = birthday.photoUrl;
          
          _nameController.text = _name;
          _notesController.text = _notes;
          if (_partyLocation != null) _partyLocationController.text = _partyLocation!;
          if (_partyDescription != null) _partyDescriptionController.text = _partyDescription!;
        });
      }
    }
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _partyLocationController.dispose();
    _partyDescriptionController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(DateTime.now().year - 20),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: Colors.white,
              surface: AppColors.backgroundDialogDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }
  
  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
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
          _photoUrl = base64String;
        });

        // Try upload in background if online
        _tryUploadToServer(bytes, file.name);
      }
    } catch (e) {
      debugPrint('[BirthdayFormScreen] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder aux photos'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    }
  }

  Future<void> _tryUploadToServer(Uint8List bytes, String filename) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await apiService.dio.post('/upload', data: formData);
      if (res.statusCode == 200 && res.data != null && res.data['url'] != null) {
        final serverUrl = res.data['url'] as String;
        if (mounted && _photoUrl?.startsWith('data:image') == true) {
          setState(() {
            _photoUrl = serverUrl;
          });
        }
      }
    } catch (_) {
      // Kept as base64 offline
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
                title: Text('Galerie du téléphone 📱', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontWeight: FontWeight.bold)),
                subtitle: Text('Choisir une photo de vos albums', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12)),
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
                title: Text('Prendre une photo 📸', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontWeight: FontWeight.bold)),
                subtitle: Text('Ouvrir l\'appareil photo du téléphone', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              // Option 3: URL
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded, color: Colors.blueAccent),
                ),
                title: Text('Entrer l\'URL d\'une photo', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                subtitle: Text('Lien direct web (https://...)', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog(context, isDark);
                },
              ),
              const SizedBox(height: 8),
              // Option 4: Presets
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.face_rounded, color: AppColors.accentPurple),
                ),
                title: Text('Avatars préconçus & portraits', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                subtitle: Text('Choisir parmi une sélection de portraits', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAvatarPresetSelector(context, isDark);
                },
              ),
              const SizedBox(height: 8),
              // Option 5: Monogram
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.wishCoinsAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.wishCoinsAmber),
                ),
                title: Text('Générer un avatar monogramme', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                subtitle: Text('Créé automatiquement avec les initiales', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  final nameForAvatar = _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : 'Time2Wish';
                  final encoded = Uri.encodeComponent(nameForAvatar);
                  setState(() {
                    _photoUrl = 'https://ui-avatars.com/api/?name=$encoded&background=0EA5E9&color=fff&size=256&bold=true';
                  });
                },
              ),
              if (_photoUrl != null && _photoUrl!.isNotEmpty) ...[
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
                  title: const Text('Supprimer la photo', style: TextStyle(color: AppColors.accentPink)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _photoUrl = null;
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

  void _showAvatarPresetSelector(BuildContext context, bool isDark) {
    final presets = [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=256&h=256&fit=crop',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=256&h=256&fit=crop',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256&h=256&fit=crop',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=256&h=256&fit=crop',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=256&h=256&fit=crop',
      'https://api.dicebear.com/7.x/bottts/png?seed=Birthday1',
      'https://api.dicebear.com/7.x/bottts/png?seed=Birthday2',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Party1',
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=Party2',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisir un avatar',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textMainLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    final url = presets[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _photoUrl = url;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _photoUrl == url ? AppColors.primaryCyan : (isDark ? Colors.white24 : AppColors.lightBorder),
                            width: _photoUrl == url ? 3 : 1,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(Icons.person, color: isDark ? Colors.white : AppColors.textMainLight),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context, bool isDark) {
    final urlController = TextEditingController(text: _photoUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('URL de l\'image', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
        content: TextField(
          controller: urlController,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCyan,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = urlController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _photoUrl = text;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_birthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de naissance')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final birthdayService = Provider.of<BirthdayService>(context, listen: false);
      
      final birthday = BirthdayModel(
        id: widget.birthdayId ?? 0,
        name: _name,
        birthdate: _birthdate!,
        category: _category,
        gender: _gender,
        notes: _notes,
        interests: _interests,
        reminderDays: _reminderDays,
        isFavorite: _isFavorite,
        partyLocation: _partyLocation,
        partyDescription: _partyDescription,
        photoUrl: _photoUrl,
      );

      if (widget.birthdayId == null) {
        await birthdayService.createBirthday(birthday);
      } else {
        await birthdayService.updateBirthday(widget.birthdayId!, birthday);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'enregistrer l\'anniversaire: ${e.toString().split('\n').first}'), backgroundColor: AppColors.accentPink),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
      filled: true,
      fillColor: isDark ? const Color(0xFF141B26) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final isDark = settings.isDarkMode;
    final localeStr = settings.language == 'en' ? 'en_US' : (settings.language == 'de' ? 'de_DE' : 'fr_FR');
    final isEditing = widget.birthdayId != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : AppColors.textMainLight),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Modifier l\'Anniversaire' : 'Nouvel Anniversaire',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMainLight,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        child: _isInitializing
            ? Center(
                child: SpinKitThreeBounce(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, size: 30),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Photo Avatar Picker Header
                        Center(
                          child: GestureDetector(
                            onTap: () => _showPhotoPicker(context, isDark),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _photoUrl != null && _photoUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: AvatarImage(
                                            photoUrl: _photoUrl!,
                                            width: 92,
                                            height: 92,
                                            fit: BoxFit.cover,
                                            fallback: Center(
                                              child: Text(
                                                _nameController.text.isNotEmpty
                                                    ? _nameController.text[0].toUpperCase()
                                                    : '🎂',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            _nameController.text.isNotEmpty
                                                ? _nameController.text[0].toUpperCase()
                                                : '🎂',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? AppColors.darkCanvas : Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _photoUrl != null && _photoUrl!.isNotEmpty
                                        ? Icons.edit_rounded
                                        : Icons.add_a_photo_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _showPhotoPicker(context, isDark),
                            icon: Icon(Icons.photo_camera_rounded, size: 16, color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo),
                            label: Text(
                              _photoUrl != null && _photoUrl!.isNotEmpty ? 'Modifier la photo' : 'Ajouter une photo',
                              style: TextStyle(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Name
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                              decoration: _inputDecoration('Nom complet', isDark),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                // Re-render initial in avatar if no photo set
                                if (_photoUrl == null) {
                                  setState(() {});
                                }
                              },
                              onSaved: (value) => _name = value!.trim(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Birthdate
                        GlassCard(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date de naissance',
                                    style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo),
                                      const SizedBox(width: 12),
                                      Text(
                                        _birthdate != null
                                            ? DateFormat('dd MMMM yyyy', localeStr).format(_birthdate!)
                                            : 'Sélectionner une date',
                                        style: TextStyle(
                                          color: _birthdate != null
                                              ? (isDark ? Colors.white : AppColors.textMainLight)
                                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Category
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                              decoration: _inputDecoration('Catégorie', isDark).copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: _categories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _category = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Gender
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Genre',
                                  style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<String>(
                                  segments: _genders.map((gender) => ButtonSegment<String>(
                                    value: gender,
                                    label: Text(gender),
                                  )).toList(),
                                  selected: {_gender},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    setState(() {
                                      _gender = newSelection.first;
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.2);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
                                        }
                                        return isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Notes
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextFormField(
                              controller: _notesController,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                              decoration: _inputDecoration('Notes (optionnel)', isDark),
                              maxLines: 3,
                              onSaved: (value) => _notes = value?.trim() ?? '',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Interests
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Centres d\'intérêt',
                                  style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    ..._interests.map((interest) => InputChip(
                                      label: Text(interest),
                                      onDeleted: () => _removeInterest(interest),
                                      backgroundColor: (isDark ? AppColors.accentPurple : const Color(0xFF8B5CF6)).withValues(alpha: 0.16),
                                      deleteIconColor: isDark ? Colors.white70 : AppColors.textMutedLight,
                                      labelStyle: TextStyle(color: isDark ? Colors.white : const Color(0xFF6D28D9), fontWeight: FontWeight.w600),
                                      side: BorderSide(color: (isDark ? AppColors.accentPurple : const Color(0xFF8B5CF6)).withValues(alpha: 0.3)),
                                    )),
                                    ActionChip(
                                      avatar: Icon(Icons.add, size: 16, color: isDark ? Colors.white : AppColors.primaryIndigo),
                                      label: Text('Ajouter', style: TextStyle(color: isDark ? Colors.white : AppColors.primaryIndigo, fontWeight: FontWeight.bold)),
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF2FF),
                                      side: BorderSide(color: (isDark ? Colors.white24 : AppColors.lightBorder)),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                                            title: Text('Ajouter un intérêt', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                                            content: TextField(
                                              controller: _interestController,
                                              style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                                              decoration: _inputDecoration('Ex: Musique, Sport, Lecture', isDark),
                                              autofocus: true,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => context.pop(),
                                                child: Text('Annuler', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _addInterest();
                                                  context.pop();
                                                },
                                                child: Text('Ajouter', style: TextStyle(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Reminder Days & Favorite
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Rappel avant (jours)', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                                    Text(_reminderDays.toString(), style: TextStyle(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Slider(
                                  value: _reminderDays.toDouble(),
                                  min: 1,
                                  max: 30,
                                  divisions: 29,
                                  activeColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
                                  inactiveColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
                                  onChanged: (value) {
                                    setState(() {
                                      _reminderDays = value.round();
                                    });
                                  },
                                ),
                                Divider(color: isDark ? Colors.white12 : AppColors.lightBorder),
                                SwitchListTile(
                                  title: Text('Mettre en favori', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                                  secondary: Icon(
                                    _isFavorite ? Icons.star : Icons.star_border,
                                    color: _isFavorite ? AppColors.wishCoinsAmber : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                  value: _isFavorite,
                                  activeThumbColor: AppColors.wishCoinsAmber,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() {
                                      _isFavorite = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Party Section
                        GlassCard(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              title: Text('Section Fête (Optionnel)', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight)),
                              leading: const Icon(Icons.celebration, color: AppColors.accentPink),
                              iconColor: isDark ? Colors.white : AppColors.textMainLight,
                              collapsedIconColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _partyLocationController,
                                        style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                                        decoration: _inputDecoration('Lieu de la fête', isDark),
                                        onSaved: (value) => _partyLocation = value?.trim().isEmpty ?? true ? null : value?.trim(),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _partyDescriptionController,
                                        style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                                        decoration: _inputDecoration('Description / Infos', isDark),
                                        maxLines: 2,
                                        onSaved: (value) => _partyDescription = value?.trim().isEmpty ?? true ? null : value?.trim(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.35 : 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SpinKitThreeBounce(color: Colors.white, size: 24)
                                : Text(
                                    isEditing ? 'Enregistrer les modifications' : 'Créer l\'anniversaire',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
