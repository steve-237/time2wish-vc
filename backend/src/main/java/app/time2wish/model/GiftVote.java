package app.time2wish.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "gift_votes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GiftVote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gift_id", nullable = false)
    @JsonIgnore
    private Gift gift;

    @Column(name = "voter_name", nullable = false, length = 100)
    private String voterName;

    @Column(name = "voter_session_id", length = 100)
    private String voterSessionId; // To prevent double voting

    @Enumerated(EnumType.STRING)
    @Column(name = "vote_type", nullable = false)
    private VoteType voteType;

    @Builder.Default
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum VoteType {
        UP, DOWN
    }
}
