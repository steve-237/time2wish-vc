package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddMemoryDto {
    @NotBlank
    private String guestName;
    @NotBlank
    private String guestSessionId;
    
    private String message;
    private String mediaUrl;
    private String mediaType;
}
