package app.time2wish.service;

import app.time2wish.dto.AstrologyInsightDto;
import app.time2wish.dto.ZodiacCompatibilityDto;
import app.time2wish.model.Birthday;
import app.time2wish.repository.BirthdayRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class AstrologyService {

    private final BirthdayRepository birthdayRepository;

    public AstrologyInsightDto getInsights(LocalDate birthdate, String lang) {
        if (birthdate == null) {
            birthdate = LocalDate.now();
        }
        String language = (lang == null || lang.isBlank()) ? "fr" : lang.toLowerCase();

        WesternZodiac western = calculateWesternZodiac(birthdate);
        ChineseZodiac chinese = calculateChineseZodiac(birthdate);

        String horoscope = generateCelebrationHoroscope(western, chinese, language);
        String affirmation = generateAffirmation(western, language);

        return AstrologyInsightDto.builder()
                .birthdate(birthdate)
                .westernSign(western.name(language))
                .westernSymbol(western.symbol)
                .westernEmoji(western.emoji)
                .westernDateRange(western.dateRange(language))
                .element(western.element(language))
                .modality(western.modality(language))
                .rulingPlanet(western.rulingPlanet(language))
                .personalityTraits(western.personalityTraits(language))
                .luckyNumbers(western.luckyNumbers)
                .luckyDays(western.luckyDays(language))
                .luckyColors(western.luckyColors(language))
                .compatibleSigns(western.compatibleSigns(language))
                .chineseAnimal(chinese.animal(language))
                .chineseSymbol(chinese.symbol)
                .chineseEmoji(chinese.emoji)
                .chineseElement(chinese.element(language))
                .polarity(chinese.polarity)
                .celebrationHoroscope(horoscope)
                .dailyAffirmation(affirmation)
                .build();
    }

    public AstrologyInsightDto getInsightsForBirthday(Long birthdayId, String lang) {
        Birthday birthday = birthdayRepository.findById(birthdayId)
                .orElseThrow(() -> new IllegalArgumentException("Anniversaire introuvable avec l'ID : " + birthdayId));
        return getInsights(birthday.getBirthdate(), lang);
    }

    public ZodiacCompatibilityDto calculateCompatibility(LocalDate date1, LocalDate date2, String lang) {
        if (date1 == null || date2 == null) {
            date1 = LocalDate.of(2000, 1, 1);
            date2 = LocalDate.of(2000, 1, 1);
        }
        String language = (lang == null || lang.isBlank()) ? "fr" : lang.toLowerCase();

        WesternZodiac w1 = calculateWesternZodiac(date1);
        WesternZodiac w2 = calculateWesternZodiac(date2);

        int score = calculateCompatibilityScore(w1, w2);
        String harmony = getElementHarmonyDescription(w1, w2, language);
        String synergy = getSynergyDescription(w1, w2, score, language);
        String tip = getTipForHarmony(w1, w2, language);

        return ZodiacCompatibilityDto.builder()
                .birthdate1(date1)
                .birthdate2(date2)
                .sign1(w1.name(language))
                .sign1Emoji(w1.emoji)
                .sign2(w2.name(language))
                .sign2Emoji(w2.emoji)
                .compatibilityScore(score)
                .elementHarmony(harmony)
                .synergyDescription(synergy)
                .tipForHarmony(tip)
                .build();
    }

    private WesternZodiac calculateWesternZodiac(LocalDate date) {
        int month = date.getMonthValue();
        int day = date.getDayOfMonth();

        if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return WesternZodiac.ARIES;
        if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return WesternZodiac.TAURUS;
        if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return WesternZodiac.GEMINI;
        if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return WesternZodiac.CANCER;
        if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return WesternZodiac.LEO;
        if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return WesternZodiac.VIRGO;
        if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return WesternZodiac.LIBRA;
        if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return WesternZodiac.SCORPIO;
        if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return WesternZodiac.SAGITTARIUS;
        if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return WesternZodiac.CAPRICORN;
        if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return WesternZodiac.AQUARIUS;
        return WesternZodiac.PISCES;
    }

    private ChineseZodiac calculateChineseZodiac(LocalDate date) {
        int year = date.getYear();
        int animalIndex = Math.floorMod(year - 4, 12);
        ChineseAnimal animal = ChineseAnimal.values()[animalIndex];

        int elementLastDigit = Math.abs(year) % 10;
        ChineseElement element;
        switch (elementLastDigit) {
            case 0:
            case 1:
                element = ChineseElement.METAL;
                break;
            case 2:
            case 3:
                element = ChineseElement.WATER;
                break;
            case 4:
            case 5:
                element = ChineseElement.WOOD;
                break;
            case 6:
            case 7:
                element = ChineseElement.FIRE;
                break;
            default:
                element = ChineseElement.EARTH;
                break;
        }

        String polarity = (year % 2 == 0) ? "Yang" : "Yin";
        return new ChineseZodiac(animal, element, polarity);
    }

    private int calculateCompatibilityScore(WesternZodiac w1, WesternZodiac w2) {
        if (w1 == w2) return 88; // Même signe : excellente résonance mais besoin de variété
        Element e1 = w1.rawElement;
        Element e2 = w2.rawElement;

        // Éléments identiques : très forte harmonie naturelle
        if (e1 == e2) return 92;

        // Complémentarités idéales : Feu + Air / Terre + Eau
        if ((e1 == Element.FIRE && e2 == Element.AIR) || (e1 == Element.AIR && e2 == Element.FIRE)) return 95;
        if ((e1 == Element.EARTH && e2 == Element.WATER) || (e1 == Element.WATER && e2 == Element.EARTH)) return 94;

        // Éléments neutres constructifs : Terre + Feu (bâtisseur) / Air + Eau (créativité sensible)
        if ((e1 == Element.EARTH && e2 == Element.FIRE) || (e1 == Element.FIRE && e2 == Element.EARTH)) return 76;
        if ((e1 == Element.AIR && e2 == Element.WATER) || (e1 == Element.WATER && e2 == Element.AIR)) return 78;

        // Éléments en tension stimulante : Feu + Eau / Terre + Air
        return 72;
    }

    private String getElementHarmonyDescription(WesternZodiac w1, WesternZodiac w2, String lang) {
        Element e1 = w1.rawElement;
        Element e2 = w2.rawElement;

        if (lang.startsWith("en")) {
            if (e1 == e2) return "Elemental Resonance (" + e1.en + " + " + e2.en + ")";
            if ((e1 == Element.FIRE && e2 == Element.AIR) || (e1 == Element.AIR && e2 == Element.FIRE))
                return "Spark & Wind Harmony (Inspirational Energy)";
            if ((e1 == Element.EARTH && e2 == Element.WATER) || (e1 == Element.WATER && e2 == Element.EARTH))
                return "Root & Oasis Harmony (Mutual Nurturing)";
            return "Dynamic Complementarity (" + e1.en + " & " + e2.en + ")";
        }

        if (e1 == e2) return "Résonance Élémentaire (" + e1.fr + " + " + e2.fr + ")";
        if ((e1 == Element.FIRE && e2 == Element.AIR) || (e1 == Element.AIR && e2 == Element.FIRE))
            return "Harmonie Étincelle & Souffle (Énergie Inspirante)";
        if ((e1 == Element.EARTH && e2 == Element.WATER) || (e1 == Element.WATER && e2 == Element.EARTH))
            return "Harmonie Terre & Source (Épanouissement Mutuel)";
        return "Complémentarité Dynamique (" + e1.fr + " & " + e2.fr + ")";
    }

    private String getSynergyDescription(WesternZodiac w1, WesternZodiac w2, int score, String lang) {
        if (lang.startsWith("en")) {
            if (score >= 90) return w1.enName + " and " + w2.enName + " share a powerful natural synergy, inspiring and elevating each other.";
            if (score >= 80) return "A balanced and enriching connection where each person's unique strengths complement the other.";
            return "An intriguing bond rich in creative discoveries through your contrasting viewpoints.";
        }
        if (score >= 90) return w1.frName + " et " + w2.frName + " partagent une complicité vibrante naturelle qui démultiplie vos projets et inspirations.";
        if (score >= 80) return "Une connexion équilibrée et chaleureuse où les qualités de l'un viennent soutenir harmonieusement celles de l'autre.";
        return "Une relation stimulante riche en apprentissages mutuels et en perspectives complémentaires.";
    }

    private String getTipForHarmony(WesternZodiac w1, WesternZodiac w2, String lang) {
        if (lang.startsWith("en")) {
            return "Cultivate regular shared celebrations and celebrate each other's distinct cosmic perspectives.";
        }
        return "Cultivez des moments de partage spontanés et valorisez vos talents complémentaires au quotidien.";
    }

    private String generateCelebrationHoroscope(WesternZodiac w, ChineseZodiac c, String lang) {
        if (lang.startsWith("en")) {
            return "Under the radiant influence of " + w.rulingPlanet.en + " and the noble aura of " + w.enName + ", this year marks a flourishing expansion for you. "
                    + "Your " + c.animal.en + " vitality and " + w.rawElement.en + " warmth draw inspiring opportunities, genuine joy, and loving celebrations into your life!";
        }
        return "Sous les auspices bienveillants de " + w.rulingPlanet.fr + " et la constellation du " + w.frName + ", cette nouvelle année personnelle s'ouvre sous le signe de l'expansion et de la réussite. "
                + "Votre énergie de " + c.animal.fr + " alliée à la noblesse de votre élément " + w.rawElement.fr + " attire à vous des opportunités inspirantes, des amitiés fidèles et de vibrantes célébrations !";
    }

    private String generateAffirmation(WesternZodiac w, String lang) {
        if (lang.startsWith("en")) {
            switch (w.rawElement) {
                case FIRE: return "I shine with confidence, warmth, and relentless creative passion.";
                case EARTH: return "I build lasting happiness, peace, and abundance with graceful determination.";
                case AIR: return "My mind is open to boundless wisdom, joy, and deep authentic connections.";
                case WATER: return "My heart flows with boundless intuition, kindness, and deep harmony.";
            }
        }
        switch (w.rawElement) {
            case FIRE: return "Je rayonne de confiance, d'enthousiasme et d'une force créatrice inaltérable.";
            case EARTH: return "Je construis mon bonheur et mes réussites avec constance, sagesse et sérénité.";
            case AIR: return "Mon esprit s'ouvre à des horizons infinis, à la joie et à des amitiés lumineuses.";
            case WATER: return "Mon intuition et ma sensibilité bienveillante sont des dons précieux pour mon entourage.";
        }
        return "Je célèbre chaque jour comme une opportunité unique d'épanouissement.";
    }

    // Enumerations & Inner Structures
    public enum Element {
        FIRE("Feu", "Fire"),
        EARTH("Terre", "Earth"),
        AIR("Air", "Air"),
        WATER("Eau", "Water");

        public final String fr;
        public final String en;
        Element(String fr, String en) { this.fr = fr; this.en = en; }
    }

    public enum Modality {
        CARDINAL("Cardinal", "Cardinal"),
        FIXED("Fixe", "Fixed"),
        MUTABLE("Mutable", "Mutable");

        public final String fr;
        public final String en;
        Modality(String fr, String en) { this.fr = fr; this.en = en; }
    }

    public enum Planet {
        MARS("Mars", "Mars"),
        VENUS("Vénus", "Venus"),
        MERCURY("Mercure", "Mercury"),
        MOON("Lune", "Moon"),
        SUN("Soleil", "Sun"),
        PLUTO("Pluton", "Pluto"),
        JUPITER("Jupiter", "Jupiter"),
        SATURN("Saturne", "Saturn"),
        URANUS("Uranus", "Uranus"),
        NEPTUNE("Neptune", "Neptune");

        public final String fr;
        public final String en;
        Planet(String fr, String en) { this.fr = fr; this.en = en; }
    }

    public enum WesternZodiac {
        ARIES("Bélier", "Aries", "♈", "♈", "21 mars - 19 avril", "Mar 21 - Apr 19", Element.FIRE, Modality.CARDINAL, Planet.MARS,
                List.of("Courageux", "Pionnier", "Énergique", "Spontané"), List.of("Courageous", "Pioneering", "Energetic", "Spontaneous"),
                List.of(9, 18, 27), List.of("Mardi"), List.of("Tuesday"), List.of("Rouge", "Corail"), List.of("Red", "Coral"),
                List.of("Lion", "Sagittaire", "Verseau", "Gémeaux"), List.of("Leo", "Sagittarius", "Aquarius", "Gemini")),

        TAURUS("Taureau", "Taurus", "♉", "♉", "20 avril - 20 mai", "Apr 20 - May 20", Element.EARTH, Modality.FIXED, Planet.VENUS,
                List.of("Persévérant", "Loyal", "Généreux", "Pragmatique"), List.of("Steadfast", "Loyal", "Generous", "Pragmatic"),
                List.of(6, 15, 24), List.of("Vendredi"), List.of("Friday"), List.of("Vert émeraude", "Rose"), List.of("Emerald Green", "Pink"),
                List.of("Vierge", "Capricorne", "Cancer", "Poissons"), List.of("Virgo", "Capricorn", "Cancer", "Pisces")),

        GEMINI("Gémeaux", "Gemini", "♊", "♊", "21 mai - 20 juin", "May 21 - Jun 20", Element.AIR, Modality.MUTABLE, Planet.MERCURY,
                List.of("Curieux", "Éloquent", "Vif d'esprit", "Adaptable"), List.of("Curious", "Eloquent", "Quick-witted", "Adaptable"),
                List.of(5, 14, 23), List.of("Mercredi"), List.of("Wednesday"), List.of("Jaune solaire", "Bleu ciel"), List.of("Sunny Yellow", "Sky Blue"),
                List.of("Balance", "Verseau", "Bélier", "Lion"), List.of("Libra", "Aquarius", "Aries", "Leo")),

        CANCER("Cancer", "Cancer", "♋", "♋", "21 juin - 22 juillet", "Jun 21 - Jul 22", Element.WATER, Modality.CARDINAL, Planet.MOON,
                List.of("Protecteur", "Intuitif", "Sensible", "Dévoué"), List.of("Protective", "Intuitive", "Empathetic", "Devoted"),
                List.of(2, 7, 11), List.of("Lundi"), List.of("Monday"), List.of("Blanc perle", "Argent"), List.of("Pearl White", "Silver"),
                List.of("Scorpion", "Poissons", "Taureau", "Vierge"), List.of("Scorpio", "Pisces", "Taurus", "Virgo")),

        LEO("Lion", "Leo", "♌", "♌", "23 juillet - 22 août", "Jul 23 - Aug 22", Element.FIRE, Modality.FIXED, Planet.SUN,
                List.of("Magnanime", "Chaleureux", "Rayonnant", "Leader"), List.of("Magnanimous", "Warm-hearted", "Radiant", "Leader"),
                List.of(1, 10, 19), List.of("Dimanche"), List.of("Sunday"), List.of("Or", "Ambre"), List.of("Gold", "Amber"),
                List.of("Bélier", "Sagittaire", "Balance", "Gémeaux"), List.of("Aries", "Sagittarius", "Libra", "Gemini")),

        VIRGO("Vierge", "Virgo", "♍", "♍", "23 août - 22 septembre", "Aug 23 - Sep 22", Element.EARTH, Modality.MUTABLE, Planet.MERCURY,
                List.of("Méthodique", "Bienveillant", "Sensible", "Perspicace"), List.of("Methodical", "Kind-hearted", "Discerning", "Insightful"),
                List.of(5, 14, 32), List.of("Mercredi"), List.of("Wednesday"), List.of("Bleu marine", "Beige"), List.of("Navy Blue", "Beige"),
                List.of("Taureau", "Capricorne", "Cancer", "Scorpion"), List.of("Taurus", "Capricorn", "Cancer", "Scorpio")),

        LIBRA("Balance", "Libra", "♎", "♎", "23 septembre - 22 octobre", "Sep 23 - Oct 22", Element.AIR, Modality.CARDINAL, Planet.VENUS,
                List.of("Harmonieux", "Juste", "Diplomate", "Raffiné"), List.of("Harmonious", "Fair-minded", "Diplomatic", "Refined"),
                List.of(6, 15, 24), List.of("Vendredi"), List.of("Friday"), List.of("Bleu pastel", "Rose pêche"), List.of("Pastel Blue", "Peach Pink"),
                List.of("Gémeaux", "Verseau", "Lion", "Sagittaire"), List.of("Gemini", "Aquarius", "Leo", "Sagittarius")),

        SCORPIO("Scorpion", "Scorpio", "♏", "♏", "23 octobre - 21 novembre", "Oct 23 - Nov 21", Element.WATER, Modality.FIXED, Planet.PLUTO,
                List.of("Passionné", "Magnétique", "Résolu", "Loyal"), List.of("Passionate", "Magnetic", "Determined", "Loyal"),
                List.of(8, 17, 26), List.of("Mardi"), List.of("Tuesday"), List.of("Pourpre", "Bordeaux"), List.of("Crimson", "Burgundy"),
                List.of("Cancer", "Poissons", "Vierge", "Capricorne"), List.of("Cancer", "Pisces", "Virgo", "Capricorn")),

        SAGITTARIUS("Sagittaire", "Sagittarius", "♐", "♐", "22 novembre - 21 décembre", "Nov 22 - Dec 21", Element.FIRE, Modality.MUTABLE, Planet.JUPITER,
                List.of("Optimiste", "Visionnaire", "Aventurier", "Généreux"), List.of("Optimistic", "Visionary", "Adventurous", "Generous"),
                List.of(3, 12, 21), List.of("Jeudi"), List.of("Thursday"), List.of("Violet royal", "Indigo"), List.of("Royal Purple", "Indigo"),
                List.of("Bélier", "Lion", "Balance", "Verseau"), List.of("Aries", "Leo", "Libra", "Aquarius")),

        CAPRICORN("Capricorne", "Capricorn", "♑", "♑", "22 décembre - 19 janvier", "Dec 22 - Jan 19", Element.EARTH, Modality.CARDINAL, Planet.SATURN,
                List.of("Ambitieux", "Sage", "Discipliné", "Fiable"), List.of("Ambitious", "Wise", "Disciplined", "Dependable"),
                List.of(4, 13, 22), List.of("Samedi"), List.of("Saturday"), List.of("Gris ardoise", "Marron chaud"), List.of("Slate Gray", "Warm Brown"),
                List.of("Taureau", "Vierge", "Scorpion", "Poissons"), List.of("Taurus", "Virgo", "Scorpio", "Pisces")),

        AQUARIUS("Verseau", "Aquarius", "♒", "♒", "20 janvier - 18 février", "Jan 20 - Feb 18", Element.AIR, Modality.FIXED, Planet.URANUS,
                List.of("Innovant", "Humaniste", "Idéaliste", "Fraternel"), List.of("Innovative", "Humanitarian", "Idealistic", "Brotherly"),
                List.of(4, 7, 11), List.of("Samedi"), List.of("Saturday"), List.of("Bleu électrique", "Turquoise"), List.of("Electric Blue", "Turquoise"),
                List.of("Gémeaux", "Balance", "Bélier", "Sagittaire"), List.of("Gemini", "Libra", "Aries", "Sagittarius")),

        PISCES("Poissons", "Pisces", "♓", "♓", "19 février - 20 mars", "Feb 19 - Mar 20", Element.WATER, Modality.MUTABLE, Planet.NEPTUNE,
                List.of("Empathique", "Créatif", "Rêveur", "Généreux"), List.of("Empathetic", "Creative", "Dreamer", "Generous"),
                List.of(3, 7, 12), List.of("Jeudi"), List.of("Thursday"), List.of("Vert d'eau", "Bleu marine"), List.of("Sea Green", "Sea Navy"),
                List.of("Cancer", "Scorpion", "Taureau", "Capricorne"), List.of("Cancer", "Scorpio", "Taurus", "Capricorn"));

        public final String frName;
        public final String enName;
        public final String symbol;
        public final String emoji;
        public final String frDateRange;
        public final String enDateRange;
        public final Element rawElement;
        public final Modality rawModality;
        public final Planet rulingPlanet;
        public final List<String> frTraits;
        public final List<String> enTraits;
        public final List<Integer> luckyNumbers;
        public final List<String> frDays;
        public final List<String> enDays;
        public final List<String> frColors;
        public final List<String> enColors;
        public final List<String> frCompatible;
        public final List<String> enCompatible;

        WesternZodiac(String frName, String enName, String symbol, String emoji, String frDateRange, String enDateRange,
                      Element rawElement, Modality rawModality, Planet rulingPlanet,
                      List<String> frTraits, List<String> enTraits,
                      List<Integer> luckyNumbers, List<String> frDays, List<String> enDays,
                      List<String> frColors, List<String> enColors,
                      List<String> frCompatible, List<String> enCompatible) {
            this.frName = frName;
            this.enName = enName;
            this.symbol = symbol;
            this.emoji = emoji;
            this.frDateRange = frDateRange;
            this.enDateRange = enDateRange;
            this.rawElement = rawElement;
            this.rawModality = rawModality;
            this.rulingPlanet = rulingPlanet;
            this.frTraits = frTraits;
            this.enTraits = enTraits;
            this.luckyNumbers = luckyNumbers;
            this.frDays = frDays;
            this.enDays = enDays;
            this.frColors = frColors;
            this.enColors = enColors;
            this.frCompatible = frCompatible;
            this.enCompatible = enCompatible;
        }

        public String name(String lang) { return lang.startsWith("en") ? enName : frName; }
        public String dateRange(String lang) { return lang.startsWith("en") ? enDateRange : frDateRange; }
        public String element(String lang) { return lang.startsWith("en") ? rawElement.en : rawElement.fr; }
        public String modality(String lang) { return lang.startsWith("en") ? rawModality.en : rawModality.fr; }
        public String rulingPlanet(String lang) { return lang.startsWith("en") ? rulingPlanet.en : rulingPlanet.fr; }
        public List<String> personalityTraits(String lang) { return lang.startsWith("en") ? enTraits : frTraits; }
        public List<String> luckyDays(String lang) { return lang.startsWith("en") ? enDays : frDays; }
        public List<String> luckyColors(String lang) { return lang.startsWith("en") ? enColors : frColors; }
        public List<String> compatibleSigns(String lang) { return lang.startsWith("en") ? enCompatible : frCompatible; }
    }

    public enum ChineseAnimal {
        RAT("Rat", "Rat", "鼠", "🐀"),
        OX("Bœuf", "Ox", "牛", "🐂"),
        TIGER("Tigre", "Tiger", "虎", "🐅"),
        RABBIT("Lapin", "Rabbit", "兔", "🐇"),
        DRAGON("Dragon", "Dragon", "龙", "🐉"),
        SNAKE("Serpent", "Snake", "蛇", "🐍"),
        HORSE("Cheval", "Horse", "马", "🐎"),
        GOAT("Chèvre", "Goat", "羊", "🐐"),
        MONKEY("Singe", "Monkey", "猴", "🐒"),
        ROOSTER("Coq", "Rooster", "鸡", "🐓"),
        DOG("Chien", "Dog", "狗", "🐕"),
        PIG("Cochon", "Pig", "猪", "🐖");

        public final String fr;
        public final String en;
        public final String symbol;
        public final String emoji;

        ChineseAnimal(String fr, String en, String symbol, String emoji) {
            this.fr = fr;
            this.en = en;
            this.symbol = symbol;
            this.emoji = emoji;
        }
    }

    public enum ChineseElement {
        WOOD("Bois", "Wood"),
        FIRE("Feu", "Fire"),
        EARTH("Terre", "Earth"),
        METAL("Métal", "Metal"),
        WATER("Eau", "Water");

        public final String fr;
        public final String en;
        ChineseElement(String fr, String en) { this.fr = fr; this.en = en; }
    }

    private static class ChineseZodiac {
        public final ChineseAnimal animal;
        public final ChineseElement element;
        public final String polarity;
        public final String symbol;
        public final String emoji;

        public ChineseZodiac(ChineseAnimal animal, ChineseElement element, String polarity) {
            this.animal = animal;
            this.element = element;
            this.polarity = polarity;
            this.symbol = animal.symbol;
            this.emoji = animal.emoji;
        }

        public String animal(String lang) { return lang.startsWith("en") ? animal.en : animal.fr; }
        public String element(String lang) { return lang.startsWith("en") ? element.en : element.fr; }
    }
}
