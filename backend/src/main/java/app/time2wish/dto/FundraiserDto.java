package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FundraiserDto {
    private Long id;
    private Long giftId;
    private BigDecimal targetAmount;
    private BigDecimal currentAmount;
    private String currency;
    private Boolean active;
    private List<PledgeDto> pledges;
}
