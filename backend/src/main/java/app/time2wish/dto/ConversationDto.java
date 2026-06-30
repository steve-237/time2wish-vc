package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversationDto {
    private Long id;
    private String name;
    private String type;
    private Long birthdayId;
    private List<ConversationMemberDto> members;
    private String lastMessage;
    private LocalDateTime lastMessageAt;
    private int unreadCount;
}
