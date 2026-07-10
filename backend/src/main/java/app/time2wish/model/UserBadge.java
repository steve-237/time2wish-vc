package app.time2wish.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_badges")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserBadge {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "badge_name", length = 100, nullable = false)
    private String badgeName;

    @Column(name = "awarded_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime awardedAt = LocalDateTime.now();
}
