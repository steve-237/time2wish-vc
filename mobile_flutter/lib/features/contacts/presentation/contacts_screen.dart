import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/contact_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glowing_badge.dart';
import '../../../core/widgets/animated_list_item.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactService>().fetchContacts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContactDialog(BuildContext context) {
    final emailController = TextEditingController();
    final isDark = context.read<SettingsService>().isDarkMode;

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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.textMutedDark : AppColors.textMutedLight).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ajouter un Contact',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textMainLight,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez l\'adresse email de l\'utilisateur pour lui envoyer une demande.',
                    style: TextStyle(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      prefixIcon: Icon(Icons.email_outlined, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF141B26) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDark ? Colors.white24 : AppColors.lightBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Annuler', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              final email = emailController.text.trim();
                              if (email.isNotEmpty) {
                                Navigator.pop(ctx);
                                final service = context.read<ContactService>();
                                await service.sendContactRequest(email);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Demande de contact envoyée avec succès !'),
                                      backgroundColor: AppColors.primaryCyan,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final contactService = Provider.of<ContactService>(context);
    final settings = Provider.of<SettingsService>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contacts & Réseau 👥',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    if (contactService.pendingRequests.isNotEmpty)
                      GlowingBadge(
                        label: '${contactService.pendingRequests.length} attente',
                        color: AppColors.accentPink,
                        isSelected: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un ami...',
                      hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 14),
                      icon: Icon(Icons.search, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
            labelColor: isDark ? AppColors.indigoLight : AppColors.primaryIndigo,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            tabs: [
              Tab(text: 'Mes Contacts (${contactService.contacts.length})'),
              Tab(text: 'Demandes (${contactService.pendingRequests.length})'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContactsList(contactService, isDark),
                _buildPendingList(contactService, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ContactService service, bool isDark) {
    final filtered = service.contacts
        .where((c) => c.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (service.isLoading) {
      return Center(child: SpinKitThreeBounce(color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo, size: 28));
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            const SizedBox(height: 12),
            Text('Aucun contact trouvé', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Ajoutez vos amis avec le bouton +', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final contact = filtered[index];
        final initial = contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?';

        return AnimatedListItem(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)]),
                  ),
                  child: Center(
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.fullName, style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(contact.email, style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: isDark ? AppColors.indigoLight : AppColors.primaryIndigo),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Discussion avec ${contact.fullName}')),
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildPendingList(ContactService service, bool isDark) {
    if (service.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 64, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            const SizedBox(height: 12),
            Text('Aucune demande en attente', style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: service.pendingRequests.length,
      itemBuilder: (context, index) {
        final request = service.pendingRequests[index];
        final initial = request.fullName.isNotEmpty ? request.fullName[0].toUpperCase() : '?';

        return AnimatedListItem(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                    ),
                  child: Center(
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.fullName, style: TextStyle(color: isDark ? Colors.white : AppColors.textMainLight, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      const Text('Demande de contact', style: TextStyle(color: AppColors.accentPink, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 28),
                      onPressed: () async {
                        await service.acceptRequest(request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Contact ${request.fullName} accepté !')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.accentPink, size: 28),
                      onPressed: () => service.rejectRequest(request.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
