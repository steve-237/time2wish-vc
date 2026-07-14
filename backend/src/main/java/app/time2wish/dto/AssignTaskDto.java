package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AssignTaskDto {
    @NotBlank
    private String guestName;
    @NotBlank
    private String guestSessionId;
}
