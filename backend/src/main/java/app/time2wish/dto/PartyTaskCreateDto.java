package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PartyTaskCreateDto {
    @NotBlank
    private String description;
}
