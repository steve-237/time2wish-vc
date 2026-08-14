import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/birthday_service.dart';

class BirthdayFormScreen extends StatefulWidget {
  final int? birthdayId;

  const BirthdayFormScreen({Key? key, this.birthdayId}) : super(key: key);

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
      // Wait a bit to ensure birthdays are loaded or fetch if needed
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
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF0F172A),
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
          SnackBar(content: Text('Erreur: $e')),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMutedDark),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.birthdayId != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Modifier l\'Anniversaire' : 'Nouvel Anniversaire',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: _isInitializing
            ? const Center(
                child: SpinKitThreeBounce(color: AppColors.primaryBlue, size: 30),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Nom complet'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                return null;
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
                                  const Text(
                                    'Date de naissance',
                                    style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                                      const SizedBox(width: 12),
                                      Text(
                                        _birthdate != null
                                            ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_birthdate!)
                                            : 'Sélectionner une date',
                                        style: TextStyle(
                                          color: _birthdate != null ? Colors.white : AppColors.textMutedDark,
                                          fontSize: 16,
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
                              value: _category,
                              dropdownColor: const Color(0xFF1E1B4B),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Catégorie').copyWith(
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
                                const Text(
                                  'Genre',
                                  style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
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
                                          return AppColors.primaryBlue.withValues(alpha: 0.3);
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.white;
                                        }
                                        return AppColors.textMutedDark;
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
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Notes (optionnel)'),
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
                                const Text(
                                  'Centres d\'intérêt',
                                  style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    ..._interests.map((interest) => InputChip(
                                      label: Text(interest),
                                      onDeleted: () => _removeInterest(interest),
                                      backgroundColor: AppColors.accentPurple.withValues(alpha: 0.2),
                                      deleteIconColor: Colors.white70,
                                      labelStyle: const TextStyle(color: Colors.white),
                                      side: BorderSide.none,
                                    )),
                                    ActionChip(
                                      avatar: const Icon(Icons.add, size: 16, color: Colors.white),
                                      label: const Text('Ajouter'),
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      labelStyle: const TextStyle(color: Colors.white),
                                      side: BorderSide.none,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: const Color(0xFF1E1B4B),
                                            title: const Text('Ajouter un intérêt', style: TextStyle(color: Colors.white)),
                                            content: TextField(
                                              controller: _interestController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: _inputDecoration('Ex: Musique, Sport, Lecture'),
                                              autofocus: true,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => context.pop(),
                                                child: const Text('Annuler', style: TextStyle(color: AppColors.textMutedDark)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _addInterest();
                                                  context.pop();
                                                },
                                                child: const Text('Ajouter', style: TextStyle(color: AppColors.primaryBlue)),
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
                                    const Text('Rappel avant (jours)', style: TextStyle(color: Colors.white)),
                                    Text(_reminderDays.toString(), style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Slider(
                                  value: _reminderDays.toDouble(),
                                  min: 1,
                                  max: 30,
                                  divisions: 29,
                                  activeColor: AppColors.primaryBlue,
                                  inactiveColor: Colors.white.withValues(alpha: 0.1),
                                  onChanged: (value) {
                                    setState(() {
                                      _reminderDays = value.round();
                                    });
                                  },
                                ),
                                const Divider(color: Colors.white12),
                                SwitchListTile(
                                  title: const Text('Mettre en favori', style: TextStyle(color: Colors.white)),
                                  secondary: Icon(
                                    _isFavorite ? Icons.star : Icons.star_border,
                                    color: _isFavorite ? AppColors.wishCoinsAmber : AppColors.textMutedDark,
                                  ),
                                  value: _isFavorite,
                                  activeColor: AppColors.wishCoinsAmber,
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
                              title: const Text('Section Fête (Optionnel)', style: TextStyle(color: Colors.white)),
                              leading: const Icon(Icons.celebration, color: AppColors.accentPink),
                              iconColor: Colors.white,
                              collapsedIconColor: AppColors.textMutedDark,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _partyLocationController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: _inputDecoration('Lieu de la fête'),
                                        onSaved: (value) => _partyLocation = value?.trim().isEmpty ?? true ? null : value?.trim(),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _partyDescriptionController,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: _inputDecoration('Description / Infos'),
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
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
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
