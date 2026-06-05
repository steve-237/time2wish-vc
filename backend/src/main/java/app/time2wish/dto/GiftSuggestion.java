package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GiftSuggestion {
    private String name;
    private String estimatedPrice;
    private String whereToBuy;
    private String purchaseLink;
    private String preparationTips;
}
