package app.time2wish.service;

import app.time2wish.model.Birthday;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;

@Slf4j
@Service
public class EmailService {

    @Value("${app.email.output-dir:scratch/emails}")
    private String emailOutputDir;

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String senderEmail;

    /**
     * Sends a birthday reminder email for the given birthday.
     */
    public void sendBirthdayReminder(Birthday birthday) {
        String subject = buildSubject(birthday);
        String htmlBody = buildHtmlEmail(birthday);

        if (senderEmail != null && !senderEmail.isBlank() && !senderEmail.contains("your-email")) {
            sendViaSmtp(birthday.getUser().getEmail(), subject, htmlBody);
        } else {
            simulateToFile(birthday, subject, htmlBody);
        }
    }

    // ─── Private Helpers ───────────────────────────────────────────────────────

    private String buildSubject(Birthday birthday) {
        long daysUntil = computeDaysUntil(birthday.getBirthdate());
        if (daysUntil == 0) {
            return "🎂 C'est l'anniversaire de " + birthday.getName() + " aujourd'hui !";
        }
        return "🔔 Rappel : anniversaire de " + birthday.getName() + " dans " + daysUntil + " jour(s)";
    }

    private long computeDaysUntil(LocalDate birthdate) {
        LocalDate today = LocalDate.now();
        LocalDate nextBirthday = birthdate.withYear(today.getYear());
        if (!nextBirthday.isAfter(today.minusDays(1))) {
            nextBirthday = nextBirthday.plusYears(1);
        }
        return ChronoUnit.DAYS.between(today, nextBirthday);
    }

    private void sendViaSmtp(String toEmail, String subject, String htmlBody) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(senderEmail);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlBody, true); // true indicates html
            
            mailSender.send(message);
            log.info("[EmailService] 📧 Email sent successfully via SMTP to '{}'", toEmail);
        } catch (MessagingException e) {
            log.error("[EmailService] Failed to send email via SMTP to '{}'", toEmail, e);
        }
    }

    private void simulateToFile(Birthday birthday, String subject, String htmlBody) {
        try {
            Path dir = Paths.get(emailOutputDir);
            Files.createDirectories(dir);

            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String safeName = birthday.getName().replaceAll("[^a-zA-Z0-9]", "_");
            Path file = dir.resolve("reminder_" + safeName + "_" + timestamp + ".html");

            Files.writeString(file, htmlBody);
            log.info("[EmailService] 📧 Email simulated! Open this file to preview: {}", file.toAbsolutePath());
        } catch (IOException e) {
            log.error("[EmailService] Failed to write email simulation file", e);
        }
    }

    private String buildHtmlEmail(Birthday birthday) {
        long daysUntil = computeDaysUntil(birthday.getBirthdate());
        String urgencyColor = daysUntil == 0 ? "#dc2626" : (daysUntil <= 3 ? "#d97706" : "#2563eb");
        String urgencyLabel = daysUntil == 0 ? "🎂 C'est aujourd'hui !" :
                              daysUntil == 1 ? "⚡ Demain !" :
                              "📅 Dans " + daysUntil + " jours";
        String photoSection = birthday.getPhotoUrl() != null && !birthday.getPhotoUrl().isBlank()
            ? "<img src=\"" + birthday.getPhotoUrl() + "\" alt=\"" + birthday.getName() + "\" style=\"width:120px;height:120px;border-radius:50%;border:4px solid " + urgencyColor + ";object-fit:cover;margin-bottom:16px;\">"
            : "<div style=\"width:120px;height:120px;border-radius:50%;background:linear-gradient(135deg,#667eea,#764ba2);display:flex;align-items:center;justify-content:center;font-size:48px;margin:0 auto 16px auto;\">🎂</div>";
        String notesSection = birthday.getNotes() != null && !birthday.getNotes().isBlank()
            ? "<div style=\"background:#f8fafc;border-left:4px solid " + urgencyColor + ";border-radius:8px;padding:16px;margin-top:20px;text-align:left;\">" +
              "<strong style=\"color:#374151;font-size:0.9rem;\">💡 Idées & Notes</strong>" +
              "<p style=\"color:#6b7280;font-size:0.9rem;margin-top:8px;line-height:1.6;\">" + birthday.getNotes() + "</p></div>"
            : "";

        return """
                <!DOCTYPE html>
                <html lang="fr">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Rappel Anniversaire – %s</title>
                  <style>
                    * { box-sizing: border-box; margin: 0; padding: 0; }
                    body { font-family: 'Segoe UI', system-ui, sans-serif; background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); min-height: 100vh; padding: 40px 16px; }
                    .email-container { max-width: 600px; margin: 0 auto; background: white; border-radius: 24px; overflow: hidden; box-shadow: 0 25px 50px rgba(0,0,0,0.3); }
                    .email-header { background: linear-gradient(135deg, %s, #7c3aed); padding: 40px 32px; text-align: center; color: white; }
                    .email-body { padding: 40px 32px; text-align: center; }
                    .email-footer { background: #f9fafb; padding: 24px 32px; text-align: center; border-top: 1px solid #e5e7eb; }
                  </style>
                </head>
                <body>
                  <div class="email-container">
                    <div class="email-header">
                      <div style="font-size:2rem;margin-bottom:8px;">🎂</div>
                      <h1 style="font-size:1.6rem;font-weight:800;margin-bottom:4px;">Time2Wish</h1>
                      <p style="opacity:0.85;font-size:0.95rem;">Ne manquez jamais un anniversaire !</p>
                    </div>
                    <div class="email-body">
                      %s
                      <h2 style="font-size:1.8rem;font-weight:800;color:#1f2937;margin-bottom:8px;">%s</h2>
                      <div style="display:inline-block;background:%s;color:white;padding:8px 20px;border-radius:999px;font-weight:700;font-size:1rem;margin-bottom:24px;">%s</div>
                      <p style="color:#6b7280;line-height:1.7;font-size:1rem;">
                        L'anniversaire de <strong style="color:#1f2937;">%s</strong> approche à grands pas !
                        C'est le moment parfait pour préparer un message chaleureux, un cadeau attentionné,
                        ou simplement lui souhaiter une merveilleuse journée. 🎉
                      </p>
                      <div style="background:linear-gradient(135deg,#f0f9ff,#e0f2fe);border-radius:16px;padding:24px;margin:24px 0;">
                        <div style="display:flex;align-items:center;gap:12px;justify-content:center;flex-wrap:wrap;">
                          <div style="text-align:center;padding:12px 20px;background:white;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
                            <div style="font-size:1.4rem;font-weight:800;color:#2563eb;">%s</div>
                            <div style="font-size:0.75rem;color:#6b7280;margin-top:2px;">Catégorie</div>
                          </div>
                          <div style="text-align:center;padding:12px 20px;background:white;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
                            <div style="font-size:1.4rem;font-weight:800;color:#7c3aed;">%s</div>
                            <div style="font-size:0.75rem;color:#6b7280;margin-top:2px;">Date de naissance</div>
                          </div>
                        </div>
                      </div>
                      %s
                    </div>
                    <div class="email-footer">
                      <p style="color:#9ca3af;font-size:0.8rem;">© 2026 Time2Wish • Cet email vous a été envoyé car vous avez configuré des rappels pour <strong>%s</strong>.</p>
                    </div>
                  </div>
                </body>
                </html>
                """.formatted(
                    birthday.getName(),
                    urgencyColor,
                    photoSection,
                    birthday.getName(),
                    urgencyColor,
                    urgencyLabel,
                    birthday.getName(),
                    birthday.getCategory(),
                    birthday.getBirthdate().format(DateTimeFormatter.ofPattern("dd MMMM yyyy")),
                    notesSection,
                    birthday.getName()
                );
    }
}
