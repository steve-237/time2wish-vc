package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimeCapsuleVideoDto {
    private Long id;
    private String guestName;
    private String videoUrl;
    private Boolean isViewed;
    private LocalDateTime createdAt;
}
