package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GiftCreateDto {
    @NotBlank
    private String name;
    private String description;
    private String priceRange;
    private String url;
    private String imageUrl;
}
