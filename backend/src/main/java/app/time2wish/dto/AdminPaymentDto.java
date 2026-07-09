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
public class AdminPaymentDto {
    private Long id;
    private String userEmail;
    private String userFullName;
    private String provider;
    private Double amount;
    private String currency;
    private String plan;
    private String status;
    private String providerTransactionId;
    private LocalDateTime createdAt;
}
