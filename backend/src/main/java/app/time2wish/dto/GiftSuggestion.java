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
    public GiftSuggestion(String name, String estimatedPrice, String whereToBuy, String purchaseLink, String preparationTips) {
        this.name = name;
        this.estimatedPrice = estimatedPrice;
        this.whereToBuy = whereToBuy;
        this.purchaseLink = purchaseLink;
        this.preparationTips = preparationTips;
    }
    private String name;
    private String estimatedPrice;
    private String whereToBuy;
    private String purchaseLink;
    private String imageUrl;
    private String preparationTips;
}
