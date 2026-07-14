package app.time2wish.dto;

import app.time2wish.model.MemoryItem;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class MemoryItemDto {
    private Long id;
    private String guestName;
    private String guestSessionId;
    private String message;
    private String mediaUrl;
    private String mediaType;
    private LocalDateTime createdAt;

    public static MemoryItemDto fromEntity(MemoryItem entity) {
        return MemoryItemDto.builder()
                .id(entity.getId())
                .guestName(entity.getGuestName())
                .guestSessionId(entity.getGuestSessionId())
                .message(entity.getMessage())
                .mediaUrl(entity.getMediaUrl())
                .mediaType(entity.getMediaType())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
