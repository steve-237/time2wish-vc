package app.time2wish.controller;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.scheduler.BirthdayReminderScheduler;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.BirthdayService;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.context.annotation.Import;
import app.time2wish.security.WebSecurityConfig;
import app.time2wish.security.UserDetailsServiceImpl;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(BirthdayController.class)
@Import(WebSecurityConfig.class)
@DisplayName("BirthdayController – Tests d'intégration MockMvc")
class BirthdayControllerTest {

    @MockitoBean
    private UserDetailsServiceImpl userDetailsService;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private BirthdayService birthdayService;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private BirthdayReminderScheduler reminderScheduler;

    // Mock du filtre JWT – fournit un UserDetails déjà authentifié
    @MockitoBean
    private app.time2wish.security.JwtUtils jwtUtils;

    private User mockUser;
    private Birthday mockBirthday;
    private UserDetailsImpl mockUserDetails;

    @BeforeEach
    void setUp() {
        mockUser = new User();
        mockUser.setId(1L);
        mockUser.setEmail("demo@time2wish.com");
        mockUser.setFullName("Demo User");
        mockUser.setPassword("encoded_password");

        mockBirthday = Birthday.builder()
                .id(10L)
                .name("Alice")
                .birthdate(LocalDate.of(1990, 6, 15))
                .category("Friend")
                .reminderDays((short) 7)
                .isDeleted(false)
                .createdAt(LocalDateTime.now())
                .build();
        mockBirthday.setUser(mockUser);

        mockUserDetails = UserDetailsImpl.build(mockUser);

        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));
    }

    // ─── GET /api/birthdays ─────────────────────────────────────────────────

    @Test
    @DisplayName("GET /api/birthdays → 200 pour utilisateur authentifié")
    void getAllBirthdays_shouldReturn200_whenAuthenticated() throws Exception {
        when(birthdayService.getActiveBirthdays(any(User.class))).thenReturn(List.of(mockBirthday));

        mockMvc.perform(get("/api/birthdays")
                        .with(user(mockUserDetails)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Alice"))
                .andExpect(jsonPath("$[0].category").value("Friend"));
    }

    @Test
    @DisplayName("GET /api/birthdays → 401 sans authentification")
    void getAllBirthdays_shouldReturn401_whenUnauthenticated() throws Exception {
        mockMvc.perform(get("/api/birthdays"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("GET /api/birthdays → liste vide si aucun anniversaire")
    void getAllBirthdays_shouldReturnEmptyList() throws Exception {
        when(birthdayService.getActiveBirthdays(any(User.class))).thenReturn(List.of());

        mockMvc.perform(get("/api/birthdays")
                        .with(user(mockUserDetails)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    // ─── POST /api/birthdays ────────────────────────────────────────────────

    @Test
    @DisplayName("POST /api/birthdays → 201 avec payload valide")
    void createBirthday_shouldReturn201_whenValidPayload() throws Exception {
        when(birthdayService.addBirthday(any(Birthday.class), any(User.class)))
                .thenReturn(mockBirthday);

        String payload = "{\"name\": \"Alice\", \"birthdate\": \"1990-06-15\", \"category\": \"Friend\", \"reminderDays\": 7}";

        mockMvc.perform(post("/api/birthdays")
                        .with(user(mockUserDetails))
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Alice"));
    }

    // ─── DELETE /api/birthdays/{id} ─────────────────────────────────────────

    @Test
    @DisplayName("DELETE /api/birthdays/{id} → 200 si l'anniversaire est supprimé")
    void deleteBirthday_shouldReturn200_whenFound() throws Exception {
        mockMvc.perform(delete("/api/birthdays/10")
                        .with(user(mockUserDetails))
                        .with(csrf()))
                .andExpect(status().isOk());
    }

    // ─── POST /api/birthdays/test-reminders ─────────────────────────────────

    @Test
    @DisplayName("POST /api/birthdays/test-reminders → 200 avec le décompte")
    void testReminders_shouldReturn200WithCount() throws Exception {
        when(reminderScheduler.triggerRemindersNow()).thenReturn(3);

        mockMvc.perform(post("/api/birthdays/test-reminders")
                        .with(user(mockUserDetails))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.remindersProcessed").value(3));
    }

    @Test
    @DisplayName("POST /api/birthdays/test-reminders → 401 sans authentification")
    void testReminders_shouldReturn401_whenUnauthenticated() throws Exception {
        mockMvc.perform(post("/api/birthdays/test-reminders")
                        .with(csrf()))
                .andExpect(status().isUnauthorized());
    }
}
