package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddSignatureDto {
    @NotBlank
    private String guestName;
    @NotBlank
    private String guestSessionId;
    @NotBlank
    private String message;
    @NotBlank
    private String color;
    @NotBlank
    private String fontFamily;
}
