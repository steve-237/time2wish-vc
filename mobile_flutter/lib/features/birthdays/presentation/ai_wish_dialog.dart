import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/glass_card.dart';

class AiWishDialog extends StatefulWidget {
  final int birthdayId;
  final ApiService apiService;

  const AiWishDialog({
    super.key,
    required this.birthdayId,
    required this.apiService,
  });

  static Future<void> show(
    BuildContext context,
    int birthdayId,
    ApiService apiService,
  ) {
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
  String _selectedTone = 'FRIENDLY';
  bool _isGenerating = false;
  String? _generatedWish;
  late final AiService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AiService(widget.apiService);
  }

  Future<void> _generateWish() async {
    setState(() {
      _isGenerating = true;
      _generatedWish = null;
    });

    try {
      final wish = await _aiService.generateWish(
        birthdayId: widget.birthdayId,
        tone: _selectedTone,
        lang: 'fr',
      );
      if (mounted) {
        setState(() => _generatedWish = wish);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copyToClipboard() {
    if (_generatedWish != null) {
      Clipboard.setData(ClipboardData(text: _generatedWish!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Copié dans le presse-papier !'),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            '🤖 Générer un Vœu IA',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez un ton et laissez l\'IA créer un message personnalisé',
            style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Tone selector label
          const Text('Ton du message', style: TextStyle(color: AppColors.textMutedDark, fontSize: 14)),
          const SizedBox(height: 12),

          // Tone chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AiService.tones.map((toneMap) {
                final key = toneMap['key']!;
                final label = toneMap['label']!;
                final isSelected = _selectedTone == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTone = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [AppColors.primaryBlue, AppColors.accentPurple])
                            : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textMutedDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Content area
          if (_generatedWish == null && !_isGenerating) ...[
            const Spacer(),
            // Generate button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.accentPurple]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.4), blurRadius: 16)],
              ),
              child: ElevatedButton(
                onPressed: _generateWish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Générer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_isGenerating) ...[
            const Spacer(),
            const Column(
              children: [
                SpinKitThreeBounce(color: AppColors.accentPurple, size: 30.0),
                SizedBox(height: 16),
                Text('L\'IA rédige votre message...', style: TextStyle(color: AppColors.textMutedDark, fontSize: 14)),
              ],
            ),
            const Spacer(),
          ] else if (_generatedWish != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: GlassCard(
                  opacity: 0.12,
                  blur: 16,
                  child: Text(
                    _generatedWish!,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.copy, 'Copier', AppColors.primaryBlue, _copyToClipboard),
                _buildActionButton(Icons.share, 'Partager', AppColors.accentPink, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partage bientôt disponible')),
                  );
                }),
                _buildActionButton(Icons.refresh, 'Regénérer', AppColors.wishCoinsAmber, _generateWish),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
