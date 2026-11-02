package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ZodiacCompatibilityDto {
    private LocalDate birthdate1;
    private LocalDate birthdate2;
    private String sign1;
    private String sign1Emoji;
    private String sign2;
    private String sign2Emoji;
    private Integer compatibilityScore; // 0 to 100
    private String elementHarmony;
    private String synergyDescription;
    private String tipForHarmony;
}
