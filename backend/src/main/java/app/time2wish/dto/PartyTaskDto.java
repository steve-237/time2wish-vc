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
public class PartyTaskDto {
    private Long id;
    private Long birthdayId;
    private String description;
    private String assigneeName;
    private Boolean isCompleted;
    private LocalDateTime createdAt;
}
