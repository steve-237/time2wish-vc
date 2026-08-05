package app.time2wish.scheduler;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.service.EmailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("BirthdayReminderScheduler – Tests Unitaires")
class BirthdayReminderSchedulerTest {

    @Mock
    private BirthdayRepository birthdayRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private BirthdayReminderScheduler scheduler;

    private Birthday birthday1;
    private Birthday birthday2;

    @BeforeEach
    void setUp() {
        User user = new User();
        user.setEmail("user@example.com");
        user.setPlan(app.time2wish.model.PlanType.PRO);

        birthday1 = Birthday.builder()
                .id(1L).name("Alice").birthdate(LocalDate.now().plusDays(7))
                .category("Friend").reminderDays((short) 7).isDeleted(false).build();
        birthday1.setUser(user);

        birthday2 = Birthday.builder()
                .id(2L).name("Bob").birthdate(LocalDate.now().plusDays(3))
                .category("Work").reminderDays((short) 3).isDeleted(false).build();
        birthday2.setUser(user);
    }

    @Test
    @DisplayName("triggerRemindersNow() devrait envoyer un email pour chaque anniversaire trouvé")
    void triggerRemindersNow_shouldCallEmailServiceForEachBirthday() {
        when(birthdayRepository.findBirthdaysWithUpcomingReminders())
                .thenReturn(List.of(birthday1, birthday2));

        int count = scheduler.triggerRemindersNow();

        verify(emailService).sendBirthdayReminder(birthday1);
        verify(emailService).sendBirthdayReminder(birthday2);
        assertThat(count).isEqualTo(2);
    }

    @Test
    @DisplayName("triggerRemindersNow() devrait retourner 0 quand aucun anniversaire n'est trouvé")
    void triggerRemindersNow_shouldReturnZeroWhenNoBirthdays() {
        when(birthdayRepository.findBirthdaysWithUpcomingReminders())
                .thenReturn(Collections.emptyList());

        int count = scheduler.triggerRemindersNow();

        verifyNoInteractions(emailService);
        assertThat(count).isEqualTo(0);
    }

    @Test
    @DisplayName("triggerRemindersNow() devrait continuer si l'envoi d'un email échoue")
    void triggerRemindersNow_shouldContinueIfOneEmailFails() {
        when(birthdayRepository.findBirthdaysWithUpcomingReminders())
                .thenReturn(List.of(birthday1, birthday2));

        // Le premier envoi lève une exception
        doThrow(new RuntimeException("SMTP timeout"))
                .when(emailService).sendBirthdayReminder(birthday1);

        assertThrows(RuntimeException.class, () -> scheduler.triggerRemindersNow());

        // Le second doit quand même être appelé
        verify(emailService).sendBirthdayReminder(birthday2);
    }

    @Test
    @DisplayName("triggerRemindersNow() devrait appeler le repository une seule fois")
    void triggerRemindersNow_shouldQueryRepositoryOnce() {
        when(birthdayRepository.findBirthdaysWithUpcomingReminders())
                .thenReturn(List.of(birthday1));

        scheduler.triggerRemindersNow();

        verify(birthdayRepository, times(1)).findBirthdaysWithUpcomingReminders();
    }
}
