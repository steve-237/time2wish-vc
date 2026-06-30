package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PledgeDto {
    private Long id;
    private String contributorName;
    private BigDecimal amount;
    private String message;
    private LocalDateTime createdAt;
}
