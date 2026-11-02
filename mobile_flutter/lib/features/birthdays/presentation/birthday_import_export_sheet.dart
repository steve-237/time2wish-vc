import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/birthday_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/file_backup_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class BirthdayImportExportSheet extends StatefulWidget {
  const BirthdayImportExportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BirthdayImportExportSheet(),
    );
  }

  @override
  State<BirthdayImportExportSheet> createState() => _BirthdayImportExportSheetState();
}

class _BirthdayImportExportSheetState extends State<BirthdayImportExportSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();
  bool _replaceExisting = false;
  bool _isImporting = false;
  String? _importError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    const sample = '''[
  {
    "name": "Marie Curie",
    "birthdate": "1994-11-07T00:00:00.000",
    "category": "AMIS",
    "gender": "Femme",
    "notes": "Passionnée de sciences et lecture 🔬",
    "interests": ["Sciences", "Lecture", "Voyages"],
    "reminderDays": 3,
    "isFavorite": true
  },
  {
    "name": "Thomas Pesquet",
    "birthdate": "1988-02-27T00:00:00.000",
    "category": "TRAVAIL",
    "gender": "Homme",
    "notes": "Astronaute préféré 🚀",
    "interests": ["Espace", "Sport", "Photographie"],
    "reminderDays": 7,
    "isFavorite": false
  }
]''';
    setState(() {
      _importController.text = sample;
      _importError = null;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() {
        _importController.text = data!.text!;
        _importError = null;
      });
    }
  }

  Future<void> _executeImport() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _importError = 'Veuillez coller des données JSON à importer.';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _importError = null;
    });

    try {
      final birthdayService = context.read<BirthdayService>();
      final count = await birthdayService.importFromJson(
        text,
        replaceExisting: _replaceExisting,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                const SizedBox(width: 10),
                Text('✓ $count anniversaire(s) importé(s) avec succès !'),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importError = 'Erreur lors de l\'importation : ${e.toString().split('\n').first}';
          _isImporting = false;
        });
      }
    }
  }

  void _downloadBackupFile(BirthdayService birthdayService) {
    try {
      DeviceService.playSuccessSound();
      DeviceService.triggerMediumHaptic();

      final jsonContent = birthdayService.exportToJson();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = 'time2wish_birthdays_$dateStr.json';

      FileBackupService.downloadJsonFile(
        filename: filename,
        content: jsonContent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done_rounded, color: AppColors.successGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('✓ Téléchargement lancé : $filename'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de téléchargement : $e'),
            backgroundColor: AppColors.accentPink,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      DeviceService.playTapSound();
      DeviceService.triggerLightHaptic();

      final content = await FileBackupService.pickJsonFile();
      if (content != null && content.isNotEmpty && mounted) {
        setState(() {
          _importController.text = content;
          _importError = null;
        });

        DeviceService.playSuccessSound();
        DeviceService.triggerSuccessHaptic();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.file_present_rounded, color: AppColors.cyanLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('✓ Fichier JSON chargé (${content.length} octets). Vérifiez et cliquez sur Importer.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importError = 'Erreur lors de la sélection du fichier : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final birthdayService = context.watch<BirthdayService>();
    final isDark = settings.isDarkMode;

    final primaryColor = isDark ? AppColors.indigoLight : AppColors.primaryIndigo;
    final surfaceColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textMain = isDark ? Colors.white : AppColors.textMainLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    final exportJsonString = birthdayService.exportToJson();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sync_alt_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sauvegarde, Export & Import',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  icon: const Icon(Icons.file_upload_outlined, size: 20),
                  text: 'Exporter (${birthdayService.birthdays.length})',
                ),
                const Tab(
                  icon: Icon(Icons.file_download_outlined, size: 20),
                  text: 'Importer',
                ),
              ],
            ),

            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- TAB 1: EXPORT ---
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${birthdayService.birthdays.length} anniversaires prêts',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textMain),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Export complet incluant catégories, notes, rappels et intérêts.',
                                    style: TextStyle(fontSize: 12, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Primary Download Button (.json file)
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _downloadBackupFile(birthdayService),
                          icon: const Icon(Icons.file_download_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'Télécharger le fichier JSON (.json)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Secondary Copy Action Button
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? const Color(0xFF2D3748) : AppColors.lightBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : Colors.white,
                          ),
                          onPressed: () async {
                            DeviceService.playTapSound();
                            DeviceService.triggerLightHaptic();
                            await Clipboard.setData(ClipboardData(text: exportJsonString));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Données JSON copiées dans le presse-papier !'),
                                  backgroundColor: AppColors.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.copy_rounded, color: primaryColor, size: 16),
                          label: Text(
                            'Copier le JSON dans le presse-papier',
                            style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Aperçu des données d\'exportation',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMuted),
                      ),
                      const SizedBox(height: 8),

                      // Preview Container
                      Container(
                        height: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            exportJsonString,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- TAB 2: IMPORT ---
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // Upload File Banner Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.28),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.indigoLight : AppColors.primaryIndigo).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.upload_file_rounded, color: primaryColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fichier de sauvegarde JSON',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMain),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Chargez un fichier .json depuis votre appareil',
                                    style: TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: _pickAndUploadFile,
                              icon: const Icon(Icons.folder_open_rounded, size: 16),
                              label: const Text('Uploader', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: borderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OU COLLER LE CONTENU JSON',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: borderColor)),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Données JSON',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textMain),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _pasteFromClipboard,
                                icon: const Icon(Icons.content_paste_rounded, size: 14),
                                label: const Text('Coller', style: TextStyle(fontSize: 12)),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: _loadSampleData,
                                icon: const Icon(Icons.lightbulb_outline_rounded, size: 14),
                                label: const Text('Exemple', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Import text input
                      Container(
                        height: 170,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _importError != null ? AppColors.accentPink : borderColor,
                          ),
                        ),
                        child: TextField(
                          controller: _importController,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Collez ici la liste JSON d\'anniversaires...',
                            hintStyle: TextStyle(color: textMuted, fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      if (_importError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _importError!,
                          style: const TextStyle(color: AppColors.accentPink, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Replace Option
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Remplacer les anniversaires existants',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMain),
                          ),
                          subtitle: Text(
                            'Si désactivé, les nouveaux anniversaires seront fusionnés avec la liste actuelle.',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                          value: _replaceExisting,
                          activeTrackColor: primaryColor,
                          onChanged: (val) => setState(() => _replaceExisting = val),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Import Button
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isImporting ? null : _executeImport,
                          icon: _isImporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _isImporting ? 'Importation en cours...' : 'Importer les Anniversaires',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
