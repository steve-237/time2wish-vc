package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@Builder
public class JwtResponse {
    private String token;
    private Long id;
    private String email;
    private String fullName;
    private String bio;
    private String avatarUrl;
    private java.util.List<String> roles;
    private String plan;
    private java.time.LocalDateTime lastAiWishGeneration;
    private java.time.LocalDateTime lastAiGiftGeneration;
    private java.util.List<String> badges;
}
