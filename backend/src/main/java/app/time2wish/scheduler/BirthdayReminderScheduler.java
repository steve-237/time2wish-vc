package app.time2wish.scheduler;

import app.time2wish.model.Birthday;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.service.EmailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Runs every day at 08:00 AM (server time) and sends reminder emails
 * for birthdays whose reminder window matches today.
 *
 * For development testing, the logic is exposed separately as
 * {@link #triggerRemindersNow()} which can be called from the controller.
 */
@Slf4j
@Component
public class BirthdayReminderScheduler {

    @Autowired
    private BirthdayRepository birthdayRepository;

    @Autowired
    private EmailService emailService;

    /**
     * Daily scheduled job – runs at 08:00 AM every day.
     * Cron: second=0, minute=0, hour=8, day=*, month=*, weekday=*
     */
    @Scheduled(cron = "0 0 8 * * ?")
    public void scheduledDailyReminders() {
        log.info("[BirthdayReminderScheduler] ⏰ Daily reminder job triggered at 08:00 AM");
        int count = triggerRemindersNow();
        log.info("[BirthdayReminderScheduler] ✅ Processed {} reminder(s)", count);
    }

    /**
     * Core logic: find all birthdays matching today's reminder window and send emails.
     * Returns the number of reminders sent.
     */
    public int triggerRemindersNow() {
        List<Birthday> upcomingBirthdays = birthdayRepository.findBirthdaysWithUpcomingReminders();
        log.info("[BirthdayReminderScheduler] Found {} birthday(s) to remind about", upcomingBirthdays.size());

        for (Birthday birthday : upcomingBirthdays) {
            try {
                emailService.sendBirthdayReminder(birthday);
                log.info("[BirthdayReminderScheduler] ✉️ Reminder sent for: {} (user: {})",
                        birthday.getName(),
                        birthday.getUser() != null ? birthday.getUser().getEmail() : "N/A");
            } catch (Exception e) {
                log.error("[BirthdayReminderScheduler] ❌ Failed to send reminder for birthday ID {}: {}",
                        birthday.getId(), e.getMessage());
            }
        }
        return upcomingBirthdays.size();
    }
}
