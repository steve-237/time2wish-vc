package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimeCapsuleResponseDto {
    private String status; // "LOCKED" or "UNLOCKED"
    private Integer daysRemaining; // null if UNLOCKED
    private List<TimeCapsuleVideoDto> videos; // empty if LOCKED
}
