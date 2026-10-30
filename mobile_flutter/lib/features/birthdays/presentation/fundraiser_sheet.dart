import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/fundraiser_model.dart';
import '../../../core/models/gift_model.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/fundraiser_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class FundraiserSheet extends StatefulWidget {
  final GiftModel gift;
  final String birthdayPersonName;

  const FundraiserSheet({
    super.key,
    required this.gift,
    required this.birthdayPersonName,
  });

  static Future<void> show(BuildContext context, GiftModel gift, String birthdayPersonName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FundraiserSheet(
        gift: gift,
        birthdayPersonName: birthdayPersonName,
      ),
    );
  }

  @override
  State<FundraiserSheet> createState() => _FundraiserSheetState();
}

class _FundraiserSheetState extends State<FundraiserSheet> {
  bool _isLoading = true;
  FundraiserModel? _fundraiser;

  @override
  void initState() {
    super.initState();
    _loadFundraiser();
  }

  Future<void> _loadFundraiser() async {
    final service = context.read<FundraiserService>();
    final target = _parseTargetAmount(widget.gift.priceRange);
    final model = await service.getOrCreateFundraiser(widget.gift.id, defaultTarget: target);
    if (mounted) {
      setState(() {
        _fundraiser = model;
        _isLoading = false;
      });
    }
  }

  double _parseTargetAmount(String? text) {
    if (text == null) return 80.0;
    final match = RegExp(r'(\d+([\.,]\d+)?)').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 80.0;
    }
    return 80.0;
  }

  void _showContributeDialog() {
    final amountCtrl = TextEditingController(text: '20');
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDialogDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.volunteer_activism, color: AppColors.primaryCyan, size: 24),
              SizedBox(width: 10),
              Text('Participer au cadeau', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cagnotte pour "${widget.gift.name}"',
                style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Preset chips
              Wrap(
                spacing: 8,
                children: ['10', '20', '30', '50'].map((val) {
                  return ChoiceChip(
                    label: Text('$val€'),
                    selected: amountCtrl.text == val,
                    onSelected: (_) {
                      amountCtrl.text = val;
                      (dialogCtx as Element).markNeedsBuild();
                    },
                    selectedColor: AppColors.primaryCyan,
                    labelStyle: TextStyle(
                      color: amountCtrl.text == val ? Colors.white : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Montant (€)',
                  prefixIcon: const Icon(Icons.euro, color: AppColors.primaryCyan),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Petit mot (optionnel)',
                  hintText: 'Joyeux anniversaire !',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textMutedDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (amt > 0 && _fundraiser != null) {
                  Navigator.pop(dialogCtx);
                  DeviceService.triggerMediumHaptic();
                  final service = context.read<FundraiserService>();
                  final updated = await service.addPledge(
                    _fundraiser!.id,
                    widget.gift.id,
                    amt,
                    contributorName: 'Vous',
                    message: messageCtrl.text.trim().isNotEmpty ? messageCtrl.text.trim() : null,
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _fundraiser = updated;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Merci pour votre participation de ${amt.toStringAsFixed(0)}€ !'),
                        backgroundColor: AppColors.primaryCyan,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 0);

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
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: SpinKitThreeBounce(color: AppColors.primaryCyan, size: 30),
              ),
            )
          : Column(
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
                      child: const Icon(Icons.savings_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cagnotte Collective',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pour ${widget.gift.name}',
                            style: const TextStyle(
                              color: AppColors.textMutedDark,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress Card
                if (_fundraiser != null) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Collecté',
                                  style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                                ),
                                Text(
                                  currencyFormat.format(_fundraiser!.currentAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _fundraiser!.isCompleted
                                    ? AppColors.successGreen.withValues(alpha: 0.2)
                                    : AppColors.primaryCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(_fundraiser!.progressPercentage * 100).toInt()}%',
                                style: TextStyle(
                                  color: _fundraiser!.isCompleted
                                      ? AppColors.successGreen
                                      : AppColors.primaryCyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Objectif',
                                  style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                                ),
                                Text(
                                  currencyFormat.format(_fundraiser!.targetAmount),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _fundraiser!.progressPercentage,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _fundraiser!.isCompleted
                                  ? AppColors.successGreen
                                  : AppColors.primaryCyan,
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fundraiser!.isCompleted
                              ? '🎉 Objectif atteint ! Merci à tous les contributeurs !'
                              : 'Reste encore ${currencyFormat.format(_fundraiser!.remainingAmount)} à collecter',
                          style: TextStyle(
                            color: _fundraiser!.isCompleted
                                ? AppColors.successGreen
                                : AppColors.textMutedDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  ElevatedButton.icon(
                    onPressed: _showContributeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.favorite, color: Colors.white, size: 20),
                    label: const Text(
                      'Participer à la cagnotte 💰',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contributors List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Contributeurs',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_fundraiser!.pledges.length} participation(s)',
                        style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_fundraiser!.pledges.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Soyez le premier à participer ! 🎁',
                          style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _fundraiser!.pledges.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final pledge = _fundraiser!.pledges[index];
                          return GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.25),
                                  child: Text(
                                    pledge.contributorName.isNotEmpty
                                        ? pledge.contributorName[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pledge.contributorName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      if (pledge.message != null && pledge.message!.isNotEmpty)
                                        Text(
                                          pledge.message!,
                                          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${pledge.amount.toStringAsFixed(0)}€',
                                  style: const TextStyle(
                                    color: AppColors.successGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
