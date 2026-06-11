package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminPasswordUpdateRequest {
    @NotBlank(message = "New password cannot be blank")
    private String newPassword;
}
