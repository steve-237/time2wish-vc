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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminService {
    private final UserRepository userRepository;
    private final BirthdayRepository birthdayRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final TemplateRepository templateRepository;
    private final PasswordEncoder passwordEncoder;

    public AdminService(UserRepository userRepository, 
                        BirthdayRepository birthdayRepository, 
                        RefreshTokenRepository refreshTokenRepository, 
                        TemplateRepository templateRepository, 
                        PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.birthdayRepository = birthdayRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.templateRepository = templateRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<AdminUserDto> getAllUsers() {
        return userRepository.findAll().stream()
                .map(user -> AdminUserDto.builder()
                        .id(user.getId())
                        .email(user.getEmail())
                        .fullName(user.getFullName())
                        .bio(user.getBio())
                        .avatarUrl(user.getAvatarUrl())
                        .status(user.getStatus())
                        .lastLoginAt(user.getLastLoginAt())
                        .createdAt(user.getCreatedAt())
                        .role(user.getRole())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        
        // Delete refresh tokens
        refreshTokenRepository.deleteByUser(user);
        
        // Delete birthdays
        List<Birthday> birthdays = birthdayRepository.findByUser(user);
        birthdayRepository.deleteAll(birthdays);
        
        // Delete message templates
        List<MessageTemplate> templates = templateRepository.findByUser(user);
        templateRepository.deleteAll(templates);
        
        // Delete user
        userRepository.delete(user);
    }

    @Transactional
    public void updateUserPassword(Long id, String newPassword) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        refreshTokenRepository.deleteByUser(user);
    }

    public StatsResponse getStats() {
        long totalUsers = userRepository.count();
        long totalBirthdays = birthdayRepository.countByIsDeletedFalse();
        return new StatsResponse(totalUsers, totalBirthdays);
    }

    public StatsResponse getStatsForRole(app.time2wish.model.Role role) {
        long totalUsers = userRepository.findByRole(role).size();
        // Since we don't easily count birthdays by role in a single query, we'll do it in Java
        // Or better yet, we just count the birthdays of those users.
        long totalBirthdays = userRepository.findByRole(role).stream()
                .mapToLong(u -> birthdayRepository.findByUserAndIsDeletedFalse(u).size())
                .sum();
        return new StatsResponse(totalUsers, totalBirthdays);
    }
}
