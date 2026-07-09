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
    private final app.time2wish.repository.PaymentTransactionRepository paymentTransactionRepository;

    public AdminService(UserRepository userRepository, 
                        BirthdayRepository birthdayRepository, 
                        RefreshTokenRepository refreshTokenRepository, 
                        TemplateRepository templateRepository, 
                        PasswordEncoder passwordEncoder,
                        app.time2wish.repository.PaymentTransactionRepository paymentTransactionRepository) {
        this.userRepository = userRepository;
        this.birthdayRepository = birthdayRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.templateRepository = templateRepository;
        this.passwordEncoder = passwordEncoder;
        this.paymentTransactionRepository = paymentTransactionRepository;
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
        return buildStatsResponse(userRepository.findAll());
    }

    public StatsResponse getStatsForRole(app.time2wish.model.Role role) {
        return buildStatsResponse(userRepository.findByRole(role));
    }

    private StatsResponse buildStatsResponse(List<User> users) {
        long totalUsers = users.size();
        long totalBirthdays = users.stream()
                .mapToLong(u -> birthdayRepository.findByUserAndIsDeletedFalse(u).size())
                .sum();

        // Calculate plan distribution
        java.util.Map<String, Long> planDistribution = users.stream()
                .collect(Collectors.groupingBy(
                        u -> u.getPlan() != null ? u.getPlan().name() : "BASIC",
                        Collectors.counting()
                ));

        // Calculate monthly registrations (last 6 months)
        java.time.LocalDate sixMonthsAgo = java.time.LocalDate.now().minusMonths(5).withDayOfMonth(1);
        java.util.Map<String, Long> monthlyRegistrations = new java.util.LinkedHashMap<>();
        
        // Initialize last 6 months with 0
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("MMM yyyy");
        for (int i = 5; i >= 0; i--) {
            monthlyRegistrations.put(java.time.LocalDate.now().minusMonths(i).format(formatter), 0L);
        }

        // Fill with actual data
        for (User u : users) {
            if (u.getCreatedAt() != null) {
                java.time.LocalDate createdAt = u.getCreatedAt().toLocalDate();
                if (!createdAt.isBefore(sixMonthsAgo)) {
                    String monthKey = createdAt.format(formatter);
                    monthlyRegistrations.put(monthKey, monthlyRegistrations.getOrDefault(monthKey, 0L) + 1);
                }
            }
        }

        // Get recent users (latest 5)
        List<AdminUserDto> recentUsers = users.stream()
                .sorted(java.util.Comparator.comparing(User::getCreatedAt, java.util.Comparator.nullsLast(java.util.Comparator.reverseOrder())))
                .limit(5)
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

        // Calculate total revenue from SUCCESS payments
        double totalRevenue = paymentTransactionRepository.findAll().stream()
                .filter(p -> "SUCCESS".equals(p.getStatus()))
                .mapToDouble(app.time2wish.model.PaymentTransaction::getAmount)
                .sum();

        return new StatsResponse(totalUsers, totalBirthdays, planDistribution, monthlyRegistrations, recentUsers, totalRevenue);
    }

    public List<app.time2wish.dto.AdminPaymentDto> getAllPayments() {
        return paymentTransactionRepository.findAll().stream()
                .sorted(java.util.Comparator.comparing(app.time2wish.model.PaymentTransaction::getCreatedAt).reversed())
                .map(p -> app.time2wish.dto.AdminPaymentDto.builder()
                        .id(p.getId())
                        .userEmail(p.getUser().getEmail())
                        .userFullName(p.getUser().getFullName())
                        .provider(p.getProvider())
                        .amount(p.getAmount())
                        .currency(p.getCurrency())
                        .plan(p.getPlan())
                        .status(p.getStatus())
                        .providerTransactionId(p.getProviderTransactionId())
                        .createdAt(p.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }
}
