package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AiCardRequest {
    @NotBlank
    private String prompt;
}
