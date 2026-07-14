package app.time2wish.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GiftVoteDto {
    @NotBlank
    private String voterName;
    @NotBlank
    private String voterSessionId;
    private String voteType; // "UP" or "DOWN" or "" to undo
}
