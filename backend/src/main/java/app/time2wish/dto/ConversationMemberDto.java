package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversationMemberDto {
    private Long userId;
    private String fullName;
    private String avatarUrl;
    private String role;
    private LocalDateTime joinedAt;
}
