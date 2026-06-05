package app.time2wish.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "birthdays")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Birthday {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false)
    private LocalDate birthdate;

    @Column(nullable = false, length = 50)
    private String category = "Friend";

    @Column(name = "photo_url", columnDefinition = "TEXT")
    private String photoUrl;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "reminder_days", nullable = false)
    private Short reminderDays = (short) 7;

    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;

    @Column(name = "show_age", nullable = false)
    private Boolean showAge = true;

    @Column(length = 255)
    private String email;

    @Column(length = 50)
    private String whatsapp;

    @Column(length = 20)
    private String gender;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (isDeleted == null) {
            isDeleted = false;
        }
        if (category == null) {
            category = "Friend";
        }
        if (reminderDays == null) {
            reminderDays = (short) 7;
        }
        if (showAge == null) {
            showAge = true;
        }
    }
}
