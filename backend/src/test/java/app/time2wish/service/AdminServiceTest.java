package app.time2wish.service;

import app.time2wish.dto.AdminUserDto;
import app.time2wish.dto.StatsResponse;
import app.time2wish.model.Birthday;
import app.time2wish.model.MessageTemplate;
import app.time2wish.model.User;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.repository.RefreshTokenRepository;
import app.time2wish.repository.TemplateRepository;
import app.time2wish.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AdminServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private BirthdayRepository birthdayRepository;

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private TemplateRepository templateRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AdminService adminService;

    private User mockUser;

    @BeforeEach
    void setUp() {
        mockUser = new User();
        mockUser.setId(1L);
        mockUser.setEmail("test@test.com");
        mockUser.setFullName("Test User");
    }

    @Test
    void testGetAllUsers() {
        when(userRepository.findAll()).thenReturn(List.of(mockUser));

        List<AdminUserDto> users = adminService.getAllUsers();
        
        assertEquals(1, users.size());
        assertEquals("test@test.com", users.get(0).getEmail());
    }

    @Test
    void testDeleteUserSuccess() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));
        when(birthdayRepository.findByUser(mockUser)).thenReturn(List.of(new Birthday()));
        when(templateRepository.findByUser(mockUser)).thenReturn(List.of(new MessageTemplate()));

        adminService.deleteUser(1L);

        verify(refreshTokenRepository).deleteByUser(mockUser);
        verify(birthdayRepository).deleteAll(any());
        verify(templateRepository).deleteAll(any());
        verify(userRepository).delete(mockUser);
    }

    @Test
    void testDeleteUserNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () -> {
            adminService.deleteUser(1L);
        });

        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
        assertEquals("User not found", ex.getReason());
    }

    @Test
    void testUpdateUserPasswordSuccess() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(mockUser));
        when(passwordEncoder.encode("newPass")).thenReturn("encodedPass");

        adminService.updateUserPassword(1L, "newPass");

        assertEquals("encodedPass", mockUser.getPassword());
        verify(userRepository).save(mockUser);
        verify(refreshTokenRepository).deleteByUser(mockUser);
    }

    @Test
    void testUpdateUserPasswordNotFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () -> {
            adminService.updateUserPassword(1L, "newPass");
        });

        assertEquals(HttpStatus.NOT_FOUND, ex.getStatusCode());
        assertEquals("User not found", ex.getReason());
    }

    @Test
    void testGetStats() {
        when(userRepository.count()).thenReturn(10L);
        when(birthdayRepository.countByIsDeletedFalse()).thenReturn(20L);

        StatsResponse stats = adminService.getStats();

        assertEquals(10L, stats.getTotalUsers());
        assertEquals(20L, stats.getTotalBirthdays());
    }
}
