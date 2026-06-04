package app.time2wish.service;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.InjectMocks;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
@DisplayName("EmailService – Tests Unitaires")
class EmailServiceTest {

    @InjectMocks
    private EmailService emailService;

    @TempDir
    Path tempDir;

    private Birthday birthday;

    @BeforeEach
    void setUp() {
        // Injecte le dossier temporaire comme répertoire de sortie
        ReflectionTestUtils.setField(emailService, "emailOutputDir", tempDir.toString());
        ReflectionTestUtils.setField(emailService, "sendGridApiKey", "");

        User user = new User();
        user.setEmail("owner@example.com");

        birthday = Birthday.builder()
                .id(1L)
                .name("Marie Curie")
                .birthdate(LocalDate.now()) // anniversaire aujourd'hui
                .category("Family")
                .notes("Aime la physique et la chimie")
                .reminderDays((short) 0)
                .build();
        birthday.setUser(user);
    }

    @Test
    @DisplayName("sendBirthdayReminder() devrait créer un fichier HTML dans le dossier de sortie")
    void sendBirthdayReminder_shouldWriteHtmlFile() throws IOException {
        emailService.sendBirthdayReminder(birthday);

        List<Path> files = Files.list(tempDir)
                .filter(p -> p.toString().endsWith(".html"))
                .toList();

        assertThat(files).hasSize(1);
        assertThat(files.get(0).getFileName().toString()).contains("Marie_Curie");
    }

    @Test
    @DisplayName("Le fichier HTML généré devrait contenir le nom de la personne")
    void sendBirthdayReminder_htmlContainsPersonName() throws IOException {
        emailService.sendBirthdayReminder(birthday);

        Path htmlFile = Files.list(tempDir)
                .filter(p -> p.toString().endsWith(".html"))
                .findFirst()
                .orElseThrow();

        String content = Files.readString(htmlFile);
        assertThat(content).contains("Marie Curie");
    }

    @Test
    @DisplayName("Le fichier HTML devrait signaler 'C'est aujourd'hui' pour un anniversaire du jour")
    void sendBirthdayReminder_htmlContainsTodayLabel() throws IOException {
        emailService.sendBirthdayReminder(birthday);

        Path htmlFile = Files.list(tempDir)
                .filter(p -> p.toString().endsWith(".html"))
                .findFirst()
                .orElseThrow();

        String content = Files.readString(htmlFile);
        assertThat(content).contains("aujourd'hui");
    }

    @Test
    @DisplayName("Le fichier HTML devrait contenir la catégorie du contact")
    void sendBirthdayReminder_htmlContainsCategory() throws IOException {
        emailService.sendBirthdayReminder(birthday);

        Path htmlFile = Files.list(tempDir)
                .filter(p -> p.toString().endsWith(".html"))
                .findFirst()
                .orElseThrow();

        String content = Files.readString(htmlFile);
        assertThat(content).contains("Family");
    }

    @Test
    @DisplayName("Le fichier HTML devrait contenir les notes du contact")
    void sendBirthdayReminder_htmlContainsNotes() throws IOException {
        emailService.sendBirthdayReminder(birthday);

        Path htmlFile = Files.list(tempDir)
                .filter(p -> p.toString().endsWith(".html"))
                .findFirst()
                .orElseThrow();

        String content = Files.readString(htmlFile);
        assertThat(content).contains("Aime la physique et la chimie");
    }

    @Test
    @DisplayName("Aucun fichier ne devrait être créé si la clé SendGrid est présente (stub)")
    void sendBirthdayReminder_shouldNotWriteFile_whenSendGridKeyPresent() throws IOException {
        ReflectionTestUtils.setField(emailService, "sendGridApiKey", "SG.fake_key_for_test");

        emailService.sendBirthdayReminder(birthday);

        List<Path> files = Files.list(tempDir)
                .filter(p -> p.toString().endsWith(".html"))
                .toList();

        // Pas de fichier — la clé SendGrid active le chemin API (stub dans le test)
        assertThat(files).isEmpty();
    }
}
