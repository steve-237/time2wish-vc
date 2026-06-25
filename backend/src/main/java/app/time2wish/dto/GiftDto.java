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
public class GiftDto {
    private Long id;
    private Long birthdayId;
    private String name;
    private String description;
    private String priceRange;
    private String url;
    private Boolean isReserved;
    private String reservedByName;
    private LocalDateTime createdAt;
}
