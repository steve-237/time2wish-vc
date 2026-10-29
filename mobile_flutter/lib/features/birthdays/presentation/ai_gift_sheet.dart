import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../core/models/birthday_model.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/gift_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class AiGiftSheet extends StatefulWidget {
  final BirthdayModel birthday;

  const AiGiftSheet({super.key, required this.birthday});

  static Future<void> show(BuildContext context, BirthdayModel birthday) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiGiftSheet(birthday: birthday),
    );
  }

  @override
  State<AiGiftSheet> createState() => _AiGiftSheetState();
}

class _AiGiftSheetState extends State<AiGiftSheet> {
  late final AiService _aiService;
  List<GiftSuggestionModel> _suggestions = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _addedGifts = {};

  @override
  void initState() {
    super.initState();
    _aiService = AiService(context.read<ApiService>());
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _aiService.generateGiftSuggestions(
        birthdayId: widget.birthday.id,
        contactName: widget.birthday.name,
        category: widget.birthday.category,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les suggestions IA.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addGiftToWishlist(GiftSuggestionModel item) async {
    final giftService = context.read<GiftService>();
    final added = await giftService.addGift(
      widget.birthday.id,
      item.name,
      '${item.preparationTips ?? ''} (Où acheter : ${item.whereToBuy})',
      item.estimatedPrice,
    );

    if (added != null && mounted) {
      setState(() {
        _addedGifts.add(item.name);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎁 "${item.name}" ajouté à la liste de cadeaux !'),
          backgroundColor: AppColors.primaryCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.primaryCyan.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Idées Cadeaux par l\'IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pour ${widget.birthday.name} • ${widget.birthday.category}',
                      style: const TextStyle(
                        color: AppColors.textMutedDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadSuggestions,
                icon: const Icon(Icons.refresh, color: AppColors.primaryCyan),
                tooltip: 'Régénérer',
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  SpinKitThreeBounce(color: AppColors.primaryCyan, size: 28),
                  SizedBox(height: 16),
                  Text(
                    'L\'IA analyse le profil et génère des suggestions adaptées...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSuggestions,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                    child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final isAdded = _addedGifts.contains(item.name);

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryCyan.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                item.estimatedPrice,
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.preparationTips != null && item.preparationTips!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.preparationTips!,
                            style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.storefront_outlined, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  item.whereToBuy,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: isAdded ? null : () => _addGiftToWishlist(item),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isAdded
                                      ? AppColors.successGreen
                                      : AppColors.primaryCyan.withValues(alpha: 0.6),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(
                                isAdded ? Icons.check : Icons.card_giftcard,
                                size: 16,
                                color: isAdded ? AppColors.successGreen : AppColors.primaryCyan,
                              ),
                              label: Text(
                                isAdded ? 'Ajouté' : 'Ajouter',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAdded ? AppColors.successGreen : AppColors.primaryCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
