package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ProfileUpdateRequest {
    @NotBlank
    private String fullName;
    
    private String bio;
    
    private String avatarUrl;
}
