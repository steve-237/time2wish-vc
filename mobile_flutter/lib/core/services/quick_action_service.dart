import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/birthday_model.dart';
import '../theme/app_theme.dart';
import 'device_service.dart';

class QuickActionService {
  /// Strips formatting characters (spaces, dashes, dots, parentheses) while preserving leading '+'
  static String sanitizePhoneNumber(String rawPhone) {
    var trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return '';

    final hasPlus = trimmed.startsWith('+');
    // Remove all non-numeric characters
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// Triggers a native phone call intent (tel:<number>)
  static Future<bool> makePhoneCall(BuildContext context, String rawPhone) async {
    final phone = sanitizePhoneNumber(rawPhone);
    if (phone.isEmpty) {
      _showSnackbar(context, 'Numéro de téléphone non renseigné', isError: true);
      return false;
    }

    DeviceService.triggerLightHaptic();
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        // Fallback for Web/desktop: copy to clipboard
        await Clipboard.setData(ClipboardData(text: phone));
        if (context.mounted) {
          _showSnackbar(context, 'Numéro copié dans le presse-papier : $phone');
        }
        return true;
      }
    } catch (e) {
      debugPrint('[QuickActionService] Error launching phone call: $e');
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        _showSnackbar(context, 'Numéro copié dans le presse-papier : $phone');
      }
      return false;
    }
  }

  /// Triggers native SMS messaging intent (sms:<number>?body=<message>)
  static Future<bool> sendSms(
    BuildContext context,
    String rawPhone, {
    String? body,
  }) async {
    final phone = sanitizePhoneNumber(rawPhone);
    if (phone.isEmpty) {
      _showSnackbar(context, 'Numéro de téléphone non renseigné', isError: true);
      return false;
    }

    DeviceService.triggerLightHaptic();
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: body != null && body.isNotEmpty ? {'body': body} : null,
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        if (body != null && body.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: body));
          if (context.mounted) {
            _showSnackbar(context, 'Message copié dans le presse-papier pour $phone');
          }
        }
        return false;
      }
    } catch (e) {
      debugPrint('[QuickActionService] Error launching SMS: $e');
      if (body != null && body.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: body));
        if (context.mounted) {
          _showSnackbar(context, 'Message copié dans le presse-papier');
        }
      }
      return false;
    }
  }

  /// Triggers WhatsApp chat intent (https://wa.me/<number>?text=<message>)
  static Future<bool> sendWhatsApp(
    BuildContext context,
    String rawPhone, {
    String? message,
  }) async {
    var phone = sanitizePhoneNumber(rawPhone);
    if (phone.isEmpty) {
      _showSnackbar(context, 'Numéro WhatsApp non renseigné', isError: true);
      return false;
    }

    // WhatsApp wa.me requires digits without leading '+' or special chars
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }

    DeviceService.triggerLightHaptic();
    final queryParams = <String, String>{};
    if (message != null && message.trim().isNotEmpty) {
      queryParams['text'] = message.trim();
    }

    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: phone,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (message != null && message.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: message));
          if (context.mounted) {
            _showSnackbar(context, 'Message copié pour WhatsApp : $phone');
          }
        }
        return false;
      }
    } catch (e) {
      debugPrint('[QuickActionService] Error launching WhatsApp: $e');
      if (message != null && message.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: message));
        if (context.mounted) {
          _showSnackbar(context, 'Message copié dans le presse-papier');
        }
      }
      return false;
    }
  }

  /// Triggers email client (mailto:<email>?subject=<subject>&body=<body>)
  static Future<bool> sendEmail(
    BuildContext context,
    String rawEmail, {
    String? subject,
    String? body,
  }) async {
    final email = rawEmail.trim();
    if (email.isEmpty) {
      _showSnackbar(context, 'Adresse email non renseignée', isError: true);
      return false;
    }

    DeviceService.triggerLightHaptic();
    final query = <String, String>{};
    if (subject != null && subject.isNotEmpty) query['subject'] = subject;
    if (body != null && body.isNotEmpty) query['body'] = body;

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: query.isNotEmpty ? query : null,
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: email));
        if (context.mounted) {
          _showSnackbar(context, 'Email copié dans le presse-papier : $email');
        }
        return false;
      }
    } catch (e) {
      debugPrint('[QuickActionService] Error launching email: $e');
      return false;
    }
  }

  /// Displays a modal bottom sheet presenting all available 1-click quick actions for a birthday contact
  static void showQuickActionSheet(
    BuildContext context,
    BirthdayModel birthday, {
    String? prefilledMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = (birthday.whatsapp != null && birthday.whatsapp!.isNotEmpty)
        ? birthday.whatsapp!
        : '';
    final email = (birthday.email != null && birthday.email!.isNotEmpty)
        ? birthday.email!
        : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppColors.primaryIndigo, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Souhaiter à ${birthday.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone.isNotEmpty ? phone : (email.isNotEmpty ? email : 'Coordonnées directes'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions Grid / List
            if (phone.isNotEmpty) ...[
              // WhatsApp
              _buildActionButton(
                context: ctx,
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'WhatsApp',
                subtitle: prefilledMessage != null ? 'Envoyer le vœu IA directement' : 'Démarrer une discussion',
                onTap: () {
                  Navigator.pop(ctx);
                  sendWhatsApp(context, phone, message: prefilledMessage);
                },
              ),
              const SizedBox(height: 10),

              // Phone Call
              _buildActionButton(
                context: ctx,
                icon: Icons.phone_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Appel téléphonique',
                subtitle: 'Composer le $phone',
                onTap: () {
                  Navigator.pop(ctx);
                  makePhoneCall(context, phone);
                },
              ),
              const SizedBox(height: 10),

              // SMS
              _buildActionButton(
                context: ctx,
                icon: Icons.sms_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Message SMS',
                subtitle: 'Ouvrir l\'application Messages',
                onTap: () {
                  Navigator.pop(ctx);
                  sendSms(context, phone, body: prefilledMessage);
                },
              ),
              const SizedBox(height: 10),
            ],

            if (email.isNotEmpty) ...[
              // Email
              _buildActionButton(
                context: ctx,
                icon: Icons.alternate_email_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Email',
                subtitle: 'Envoyer un courriel à $email',
                onTap: () {
                  Navigator.pop(ctx);
                  sendEmail(
                    context,
                    email,
                    subject: 'Joyeux Anniversaire ${birthday.name} ! 🎉',
                    body: prefilledMessage,
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            if (phone.isEmpty && email.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline_rounded, color: isDark ? AppColors.amberLight : Colors.amber.shade700, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun numéro ni email enregistré pour ce contact.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Renseignez son numéro de téléphone ou WhatsApp dans la fiche contact pour activer les actions rapides en 1 clic.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }

  static void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryIndigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
