package app.time2wish.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "time_capsule_videos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimeCapsuleVideo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "birthday_id", nullable = false)
    @JsonIgnore
    private Birthday birthday;

    @Column(name = "guest_name", nullable = false, length = 100)
    private String guestName;

    @Column(name = "video_url", nullable = false, length = 255)
    private String videoUrl;

    @Builder.Default
    @Column(name = "is_viewed", nullable = false)
    private Boolean isViewed = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
