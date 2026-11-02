package app.time2wish.service;

import app.time2wish.dto.AstrologyInsightDto;
import app.time2wish.dto.ZodiacCompatibilityDto;
import app.time2wish.model.Birthday;
import app.time2wish.repository.BirthdayRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AstrologyServiceTest {

    @Mock
    private BirthdayRepository birthdayRepository;

    private AstrologyService astrologyService;

    @BeforeEach
    void setUp() {
        astrologyService = new AstrologyService(birthdayRepository);
    }

    @Test
    @DisplayName("Should correctly identify Western Zodiac signs across key cusp dates")
    void shouldIdentifyWesternSignsCorrectly() {
        // Aries (Mar 21 - Apr 19)
        AstrologyInsightDto aries = astrologyService.getInsights(LocalDate.of(1995, 3, 21), "fr");
        assertThat(aries.getWesternSign()).isEqualTo("Bélier");
        assertThat(aries.getElement()).isEqualTo("Feu");
        assertThat(aries.getRulingPlanet()).isEqualTo("Mars");

        // Taurus (Apr 20 - May 20)
        AstrologyInsightDto taurus = astrologyService.getInsights(LocalDate.of(1992, 4, 20), "fr");
        assertThat(taurus.getWesternSign()).isEqualTo("Taureau");
        assertThat(taurus.getElement()).isEqualTo("Terre");

        // Gemini (May 21 - Jun 20)
        AstrologyInsightDto gemini = astrologyService.getInsights(LocalDate.of(1998, 6, 1), "fr");
        assertThat(gemini.getWesternSign()).isEqualTo("Gémeaux");
        assertThat(gemini.getElement()).isEqualTo("Air");

        // Cancer (Jun 21 - Jul 22)
        AstrologyInsightDto cancer = astrologyService.getInsights(LocalDate.of(1989, 7, 10), "fr");
        assertThat(cancer.getWesternSign()).isEqualTo("Cancer");
        assertThat(cancer.getElement()).isEqualTo("Eau");

        // Leo (Jul 23 - Aug 22)
        AstrologyInsightDto leo = astrologyService.getInsights(LocalDate.of(2001, 8, 15), "en");
        assertThat(leo.getWesternSign()).isEqualTo("Leo");
        assertThat(leo.getElement()).isEqualTo("Fire");

        // Scorpio (Oct 23 - Nov 21)
        AstrologyInsightDto scorpio = astrologyService.getInsights(LocalDate.of(1985, 11, 5), "fr");
        assertThat(scorpio.getWesternSign()).isEqualTo("Scorpion");
        assertThat(scorpio.getElement()).isEqualTo("Eau");

        // Capricorn (Dec 22 - Jan 19)
        AstrologyInsightDto capricorn = astrologyService.getInsights(LocalDate.of(2000, 1, 10), "fr");
        assertThat(capricorn.getWesternSign()).isEqualTo("Capricorne");

        // Pisces (Feb 19 - Mar 20)
        AstrologyInsightDto pisces = astrologyService.getInsights(LocalDate.of(1996, 3, 1), "fr");
        assertThat(pisces.getWesternSign()).isEqualTo("Poissons");
    }

    @Test
    @DisplayName("Should correctly calculate Chinese Zodiac animal, element, and polarity")
    void shouldCalculateChineseZodiacCorrectly() {
        // 1984 -> Wood Rat Yang
        AstrologyInsightDto r1984 = astrologyService.getInsights(LocalDate.of(1984, 5, 10), "fr");
        assertThat(r1984.getChineseAnimal()).isEqualTo("Rat");
        assertThat(r1984.getChineseElement()).isEqualTo("Bois");
        assertThat(r1984.getPolarity()).isEqualTo("Yang");

        // 1990 -> Metal Horse Yang
        AstrologyInsightDto r1990 = astrologyService.getInsights(LocalDate.of(1990, 8, 20), "fr");
        assertThat(r1990.getChineseAnimal()).isEqualTo("Cheval");
        assertThat(r1990.getChineseElement()).isEqualTo("Métal");
        assertThat(r1990.getPolarity()).isEqualTo("Yang");

        // 1995 -> Wood Pig Yin
        AstrologyInsightDto r1995 = astrologyService.getInsights(LocalDate.of(1995, 12, 1), "fr");
        assertThat(r1995.getChineseAnimal()).isEqualTo("Cochon");
        assertThat(r1995.getChineseElement()).isEqualTo("Bois");
        assertThat(r1995.getPolarity()).isEqualTo("Yin");

        // 2024 -> Wood Dragon Yang
        AstrologyInsightDto r2024 = astrologyService.getInsights(LocalDate.of(2024, 2, 15), "en");
        assertThat(r2024.getChineseAnimal()).isEqualTo("Dragon");
        assertThat(r2024.getChineseElement()).isEqualTo("Wood");
    }

    @Test
    @DisplayName("Should generate meaningful celebration horoscope, lucky numbers and affirmation")
    void shouldGenerateHoroscopeAndAffirmation() {
        AstrologyInsightDto insights = astrologyService.getInsights(LocalDate.of(1994, 7, 28), "fr");

        assertThat(insights.getCelebrationHoroscope()).isNotBlank();
        assertThat(insights.getCelebrationHoroscope()).contains("Lion");
        assertThat(insights.getDailyAffirmation()).isNotBlank();
        assertThat(insights.getLuckyNumbers()).isNotEmpty();
        assertThat(insights.getLuckyDays()).isNotEmpty();
        assertThat(insights.getPersonalityTraits()).isNotEmpty();
    }

    @Test
    @DisplayName("Should calculate zodiac compatibility and element harmony between two dates")
    void shouldCalculateZodiacCompatibility() {
        // Leo (Fire) and Aries (Fire) -> High compatibility
        ZodiacCompatibilityDto compFire = astrologyService.calculateCompatibility(
                LocalDate.of(1990, 8, 1),
                LocalDate.of(1992, 4, 5),
                "fr"
        );

        assertThat(compFire.getCompatibilityScore()).isGreaterThanOrEqualTo(85);
        assertThat(compFire.getSign1()).isEqualTo("Lion");
        assertThat(compFire.getSign2()).isEqualTo("Bélier");
        assertThat(compFire.getElementHarmony()).contains("Feu");
        assertThat(compFire.getSynergyDescription()).isNotBlank();
        assertThat(compFire.getTipForHarmony()).isNotBlank();
    }

    @Test
    @DisplayName("Should fetch insights for an existing Birthday entity")
    void shouldFetchInsightsForBirthday() {
        Birthday mockBirthday = Birthday.builder()
                .id(42L)
                .name("Alexandre")
                .birthdate(LocalDate.of(1993, 11, 15))
                .build();

        when(birthdayRepository.findById(42L)).thenReturn(Optional.of(mockBirthday));

        AstrologyInsightDto insights = astrologyService.getInsightsForBirthday(42L, "fr");
        assertThat(insights).isNotNull();
        assertThat(insights.getWesternSign()).isEqualTo("Scorpion");
        assertThat(insights.getBirthdate()).isEqualTo(LocalDate.of(1993, 11, 15));
    }
}
