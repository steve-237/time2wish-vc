package app.time2wish.controller;

import app.time2wish.dto.LoginRequest;
import app.time2wish.dto.SignupRequest;
import app.time2wish.model.PlanType;
import app.time2wish.model.RefreshToken;
import app.time2wish.model.Role;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.JwtUtils;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.security.UserDetailsServiceImpl;
import app.time2wish.security.WebSecurityConfig;
import app.time2wish.service.RefreshTokenService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import(WebSecurityConfig.class)
@DisplayName("AuthController – Tests d'intégration MockMvc")
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AuthenticationManager authenticationManager;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private PasswordEncoder encoder;

    @MockitoBean
    private JwtUtils jwtUtils;

    @MockitoBean
    private RefreshTokenService refreshTokenService;

    @MockitoBean
    private UserDetailsServiceImpl userDetailsService;

    @MockitoBean
    private app.time2wish.service.SettingService settingService;

    @MockitoBean
    private app.time2wish.repository.UserBadgeRepository userBadgeRepository;

    private User mockUser;

    @BeforeEach
    void setUp() {
        org.mockito.Mockito.lenient().when(settingService.getBooleanSetting(app.time2wish.service.SettingService.ALLOW_REGISTRATION)).thenReturn(true);
        org.mockito.Mockito.lenient().when(settingService.getBooleanSetting(app.time2wish.service.SettingService.MAINTENANCE_MODE)).thenReturn(false);
        mockUser = new User();
        mockUser.setId(1L);
        mockUser.setEmail("test@time2wish.com");
        mockUser.setFullName("Test User");
        mockUser.setPassword("encoded_pwd");
        mockUser.setRole(Role.ROLE_USER);
        mockUser.setPlan(PlanType.BASIC);
    }

    @Test
    @DisplayName("POST /api/auth/register → 200 Succès")
    void registerUser_shouldReturn200() throws Exception {
        when(userRepository.existsByEmail("new@time2wish.com")).thenReturn(false);
        when(encoder.encode("password")).thenReturn("encoded_pwd");

        String payload = "{\"email\": \"new@time2wish.com\", \"password\": \"password\", \"fullName\": \"New User\"}";

        mockMvc.perform(post("/api/auth/register")
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("User registered successfully!"));
    }

    @Test
    @DisplayName("POST /api/auth/register → 400 Email existant")
    void registerUser_shouldReturn400_whenEmailExists() throws Exception {
        when(userRepository.existsByEmail("test@time2wish.com")).thenReturn(true);

        String payload = "{\"email\": \"test@time2wish.com\", \"password\": \"password\", \"fullName\": \"Test User\"}";

        mockMvc.perform(post("/api/auth/register")
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Error: Email is already in use!"));
    }

    @Test
    @DisplayName("POST /api/auth/login → 200 Succès")
    void authenticateUser_shouldReturn200() throws Exception {
        UserDetailsImpl userDetails = UserDetailsImpl.build(mockUser);
        Authentication authentication = mock(Authentication.class);
        when(authentication.getPrincipal()).thenReturn(userDetails);

        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenReturn(authentication);
        when(jwtUtils.generateJwtToken("test@time2wish.com")).thenReturn("mocked-jwt");

        RefreshToken mockToken = new RefreshToken();
        mockToken.setToken(UUID.randomUUID());
        mockToken.setExpiryDate(Instant.now().plusMillis(10000));
        when(refreshTokenService.createRefreshToken(1L)).thenReturn(mockToken);

        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));

        String payload = "{\"email\": \"test@time2wish.com\", \"password\": \"password\"}";

        mockMvc.perform(post("/api/auth/login")
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("mocked-jwt"))
                .andExpect(jsonPath("$.email").value("test@time2wish.com"));
    }

    @Test
    @DisplayName("POST /api/auth/refresh → 200 avec cookie valide")
    void refreshToken_shouldReturn200_whenValidCookieProvided() throws Exception {
        UUID tokenUuid = UUID.randomUUID();
        RefreshToken mockToken = new RefreshToken();
        mockToken.setToken(tokenUuid);
        mockToken.setUser(mockUser);
        mockToken.setExpiryDate(Instant.now().plusMillis(100000));

        when(refreshTokenService.findByToken(tokenUuid)).thenReturn(Optional.of(mockToken));
        when(refreshTokenService.verifyExpiration(mockToken)).thenReturn(mockToken);
        when(jwtUtils.generateJwtToken("test@time2wish.com")).thenReturn("new-refreshed-jwt");

        mockMvc.perform(post("/api/auth/refresh")
                        .with(csrf())
                        .cookie(new jakarta.servlet.http.Cookie("t2w_refresh", tokenUuid.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new-refreshed-jwt"))
                .andExpect(jsonPath("$.email").value("test@time2wish.com"));
    }

    @Test
    @DisplayName("POST /api/auth/refresh → 200 avec body JSON valide (fallback sans cookie)")
    void refreshToken_shouldReturn200_whenValidBodyProvided() throws Exception {
        UUID tokenUuid = UUID.randomUUID();
        RefreshToken mockToken = new RefreshToken();
        mockToken.setToken(tokenUuid);
        mockToken.setUser(mockUser);
        mockToken.setExpiryDate(Instant.now().plusMillis(100000));

        when(refreshTokenService.findByToken(tokenUuid)).thenReturn(Optional.of(mockToken));
        when(refreshTokenService.verifyExpiration(mockToken)).thenReturn(mockToken);
        when(jwtUtils.generateJwtToken("test@time2wish.com")).thenReturn("new-refreshed-jwt");

        String payload = "{\"refreshToken\": \"" + tokenUuid.toString() + "\"}";

        mockMvc.perform(post("/api/auth/refresh")
                        .with(csrf())
                        .contentType("application/json")
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("new-refreshed-jwt"));
    }

    @Test
    @DisplayName("POST /api/auth/refresh → 400 si refresh token absent")
    void refreshToken_shouldReturn400_whenTokenMissing() throws Exception {
        mockMvc.perform(post("/api/auth/refresh")
                        .with(csrf()))
                .andExpect(status().isBadRequest());
    }
}
