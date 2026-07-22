package app.time2wish.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(name = "full_name", nullable = false, length = 100)
    private String fullName;

    @Column(columnDefinition = "TEXT")
    private String bio;

    @Column(name = "avatar_url", columnDefinition = "TEXT")
    private String avatarUrl;

    @Builder.Default
    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    @Builder.Default
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Role role = Role.ROLE_USER;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private PlanType plan = PlanType.BASIC;

    @Column(name = "last_ai_wish_generation")
    private LocalDateTime lastAiWishGeneration;

    @Column(name = "last_ai_gift_generation")
    private LocalDateTime lastAiGiftGeneration;

    @Column(name = "subscription_provider", length = 50)
    private String subscriptionProvider; // STRIPE, PAYPAL, MOMO

    @Column(name = "subscription_status", length = 50)
    private String subscriptionStatus; // ACTIVE, CANCELED, PAST_DUE

    @Column(name = "subscription_expires_at")
    private LocalDateTime subscriptionExpiresAt;

    @Builder.Default
    @Column(name = "coins", nullable = false)
    private Integer coins = 0;

    @Column(name = "google_access_token", columnDefinition = "TEXT")
    private String googleAccessToken;

    @Column(name = "google_refresh_token", columnDefinition = "TEXT")
    private String googleRefreshToken;

    @Column(name = "google_token_expiry")
    private LocalDateTime googleTokenExpiry;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        lastLoginAt = LocalDateTime.now();
        if (role == null) {
            role = Role.ROLE_USER;
        }
        if (plan == null) {
            plan = PlanType.BASIC;
        }
        if (status == null) {
            status = "ACTIVE";
        }
        if (coins == null) {
            coins = 0;
        }
    }
}
