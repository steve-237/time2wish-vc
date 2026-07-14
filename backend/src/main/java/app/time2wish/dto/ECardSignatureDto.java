package app.time2wish.dto;

import app.time2wish.model.ECardSignature;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ECardSignatureDto {
    private Long id;
    private String guestName;
    private String guestSessionId;
    private String message;
    private String color;
    private String fontFamily;
    private LocalDateTime createdAt;

    public static ECardSignatureDto fromEntity(ECardSignature entity) {
        return ECardSignatureDto.builder()
                .id(entity.getId())
                .guestName(entity.getGuestName())
                .guestSessionId(entity.getGuestSessionId())
                .message(entity.getMessage())
                .color(entity.getColor())
                .fontFamily(entity.getFontFamily())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
