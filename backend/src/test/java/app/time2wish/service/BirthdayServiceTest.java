package app.time2wish.service;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.BirthdayRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("BirthdayService – Tests Unitaires")
class BirthdayServiceTest {

    @Mock
    private BirthdayRepository birthdayRepository;

    @InjectMocks
    private BirthdayService birthdayService;

    private User user;
    private Birthday birthday;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        user.setEmail("test@example.com");
        user.setFullName("Test User");

        birthday = Birthday.builder()
                .id(10L)
                .name("Alice Dupont")
                .birthdate(LocalDate.of(1990, 6, 15))
                .category("Friend")
                .reminderDays((short) 7)
                .isDeleted(false)
                .build();
        birthday.setUser(user);
    }

    // ─── getActiveBirthdays ─────────────────────────────────────────────────

    @Test
    @DisplayName("getActiveBirthdays() devrait appeler le repository avec l'utilisateur")
    void getActiveBirthdays_shouldDelegateToRepository() {
        when(birthdayRepository.findByUserAndIsDeletedFalse(user)).thenReturn(List.of(birthday));

        List<Birthday> result = birthdayService.getActiveBirthdays(user);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Alice Dupont");
        verify(birthdayRepository).findByUserAndIsDeletedFalse(user);
    }

    // ─── addBirthday ────────────────────────────────────────────────────────

    @Test
    @DisplayName("addBirthday() devrait associer l'utilisateur et sauvegarder")
    void addBirthday_shouldSetUserAndIsDeletedFalse() {
        Birthday newBirthday = Birthday.builder()
                .name("Bob Martin")
                .birthdate(LocalDate.of(1985, 3, 20))
                .category("Work")
                .reminderDays((short) 3)
                .build();

        when(birthdayRepository.save(any(Birthday.class))).thenAnswer(inv -> inv.getArgument(0));

        Birthday saved = birthdayService.addBirthday(newBirthday, user);

        assertThat(saved.getUser()).isEqualTo(user);
        assertThat(saved.getIsDeleted()).isFalse();
        verify(birthdayRepository).save(newBirthday);
    }

    // ─── updateBirthday ─────────────────────────────────────────────────────

    @Test
    @DisplayName("updateBirthday() devrait mettre à jour les champs et sauvegarder")
    void updateBirthday_shouldUpdateFieldsAndSave() {
        Birthday updates = Birthday.builder()
                .name("Alice Martin")
                .birthdate(LocalDate.of(1990, 7, 20))
                .category("Family")
                .notes("Aime le chocolat")
                .reminderDays((short) 14)
                .build();

        when(birthdayRepository.findByIdAndUserAndIsDeletedFalse(10L, user)).thenReturn(Optional.of(birthday));
        when(birthdayRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Birthday result = birthdayService.updateBirthday(10L, updates, user);

        assertThat(result.getName()).isEqualTo("Alice Martin");
        assertThat(result.getBirthdate()).isEqualTo(LocalDate.of(1990, 7, 20));
        assertThat(result.getCategory()).isEqualTo("Family");
        assertThat(result.getNotes()).isEqualTo("Aime le chocolat");
        assertThat(result.getReminderDays()).isEqualTo((short) 14);
    }

    @Test
    @DisplayName("updateBirthday() devrait lever une exception si l'anniversaire n'appartient pas à l'utilisateur")
    void updateBirthday_shouldThrowIfNotFound() {
        when(birthdayRepository.findByIdAndUserAndIsDeletedFalse(99L, user)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> birthdayService.updateBirthday(99L, birthday, user))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("99");
    }

    // ─── deleteBirthday ─────────────────────────────────────────────────────

    @Test
    @DisplayName("deleteBirthday() devrait effectuer un soft-delete (isDeleted = true)")
    void deleteBirthday_shouldSetIsDeletedTrue() {
        when(birthdayRepository.findByIdAndUserAndIsDeletedFalse(10L, user)).thenReturn(Optional.of(birthday));
        when(birthdayRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        birthdayService.deleteBirthday(10L, user);

        ArgumentCaptor<Birthday> captor = ArgumentCaptor.forClass(Birthday.class);
        verify(birthdayRepository).save(captor.capture());
        assertThat(captor.getValue().getIsDeleted()).isTrue();
    }

    @Test
    @DisplayName("deleteBirthday() devrait lever une exception si ID inconnu")
    void deleteBirthday_shouldThrowIfNotFound() {
        when(birthdayRepository.findByIdAndUserAndIsDeletedFalse(99L, user)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> birthdayService.deleteBirthday(99L, user))
                .isInstanceOf(RuntimeException.class);
    }

    // ─── getBirthday ────────────────────────────────────────────────────────

    @Test
    @DisplayName("getBirthday() devrait retourner empty si l'ID appartient à un autre utilisateur")
    void getBirthday_shouldReturnEmptyIfNotOwner() {
        when(birthdayRepository.findByIdAndUserAndIsDeletedFalse(10L, user)).thenReturn(Optional.empty());

        Optional<Birthday> result = birthdayService.getBirthday(10L, user);

        assertThat(result).isEmpty();
    }
}
