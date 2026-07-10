package app.time2wish.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "promo_codes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PromoCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 50)
    private String code;

    @Column(name = "discount_percentage", nullable = false)
    private int discountPercentage;

    @Column(name = "max_uses")
    private Integer maxUses;

    @Builder.Default
    @Column(name = "current_uses", nullable = false)
    private int currentUses = 0;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Builder.Default
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
