package app.time2wish.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class AstrologyInsightDto {
    private LocalDate birthdate;

    // Western Zodiac
    private String westernSign;
    private String westernSymbol;
    private String westernEmoji;
    private String westernDateRange;
    private String element;
    private String modality;
    private String rulingPlanet;
    private List<String> personalityTraits;
    private List<Integer> luckyNumbers;
    private List<String> luckyDays;
    private List<String> luckyColors;
    private List<String> compatibleSigns;

    // Chinese Zodiac
    private String chineseAnimal;
    private String chineseSymbol;
    private String chineseEmoji;
    private String chineseElement;
    private String polarity; // Yin or Yang

    // Affirmation & Horoscope
    private String celebrationHoroscope;
    private String dailyAffirmation;
}
