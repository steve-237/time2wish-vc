package app.time2wish.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class AILogDto {
    private Long id;
    private String userEmail;
    private String userFullName;
    private String featureType;
    private String prompt;
    private String generatedContent;
    private int tokensCost;
    private LocalDateTime createdAt;
}
