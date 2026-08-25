import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class AiWishDialog extends StatefulWidget {
  final int birthdayId;
  final ApiService apiService;

  const AiWishDialog({
    super.key,
    required this.birthdayId,
    required this.apiService,
  });

  static Future<void> show(BuildContext context, int birthdayId, ApiService apiService) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiWishDialog(
        birthdayId: birthdayId,
        apiService: apiService,
      ),
    );
  }

  @override
  State<AiWishDialog> createState() => _AiWishDialogState();
}

class _AiWishDialogState extends State<AiWishDialog> {
  late final AiService _aiService;
  String _selectedTone = 'AMICAL';
  String _generatedWish = '';
  bool _isLoading = false;
  String? _error;

  final Map<String, Map<String, dynamic>> _tones = {
    'AMICAL': {'label': 'Amical 😊', 'icon': Icons.sentiment_satisfied_alt, 'color': AppColors.primaryCyan},
    'HUMORISTIQUE': {'label': 'Drôle 😂', 'icon': Icons.mood, 'color': AppColors.wishCoinsAmber},
    'FORMEL': {'label': 'Formel 👔', 'icon': Icons.business_center, 'color': Colors.blueAccent},
    'ROMANTIQUE': {'label': 'Romantique ❤️', 'icon': Icons.favorite, 'color': AppColors.accentPink},
    'POETIQUE': {'label': 'Poétique ✨', 'icon': Icons.auto_awesome, 'color': AppColors.accentPurple},
  };

  @override
  void initState() {
    super.initState();
    _aiService = AiService(widget.apiService);
    _generateWish();
  }

  Future<void> _generateWish() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wish = await _aiService.generateWish(
        birthdayId: widget.birthdayId,
        tone: _selectedTone,
      );
      setState(() {
        _generatedWish = wish;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la génération. Réessayez.';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_generatedWish.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedWish));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vœu copié dans le presse-papier ! 📋'),
          backgroundColor: AppColors.primaryCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primaryCyan, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Générateur de Vœux IA ✨',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMutedDark),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tone Selector Horizontal Cards
          const Text('Choisissez le ton :', style: TextStyle(color: AppColors.textMutedDark, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _tones.entries.map((entry) {
                final key = entry.key;
                final data = entry.value;
                final isSelected = _selectedTone == key;
                final color = data['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    if (_selectedTone != key) {
                      setState(() => _selectedTone = key);
                      _generateWish();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(data['icon'] as IconData, size: 16, color: isSelected ? color : AppColors.textMutedDark),
                        const SizedBox(width: 6),
                        Text(
                          data['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMutedDark,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Wish Result Box
          Container(
            padding: const EdgeInsets.all(18),
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: _isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitThreeBounce(color: AppColors.primaryCyan, size: 28),
                      SizedBox(height: 12),
                      Text('L\'IA rédige un vœu sur mesure...', style: TextStyle(color: AppColors.textMutedDark, fontSize: 13)),
                    ],
                  )
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.accentPink)))
                    : SelectableText(
                        _generatedWish,
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                      ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _generateWish,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Régénérer', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _generatedWish.isEmpty ? null : _copyToClipboard,
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text('Copier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
