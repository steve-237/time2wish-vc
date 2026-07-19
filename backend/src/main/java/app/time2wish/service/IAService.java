package app.time2wish.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import app.time2wish.dto.GiftSuggestion;
import app.time2wish.dto.GiftSuggestionResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import app.time2wish.model.AILog;
import app.time2wish.model.User;
import app.time2wish.repository.AILogRepository;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.SettingService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class IAService {

    @Value("${app.IA.api-key:}")
    private String apiKey;

    @Value("${app.IA.model:IA-1.5-flash}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();
    private final AILogRepository aiLogRepository;
    private final UserRepository userRepository;
    private final SettingService settingService;

    public IAService(AILogRepository aiLogRepository, UserRepository userRepository, SettingService settingService) {
        this.aiLogRepository = aiLogRepository;
        this.userRepository = userRepository;
        this.settingService = settingService;
    }

    private void logUsage(String featureType, String prompt, String generatedContent) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl userDetails = (UserDetailsImpl) auth.getPrincipal();
            User user = userRepository.findById(userDetails.getId()).orElse(null);
            if (user != null) {
                AILog log = AILog.builder()
                        .user(user)
                        .featureType(featureType)
                        .prompt(prompt)
                        .generatedContent(generatedContent)
                        .tokensCost(1)
                        .build();
                aiLogRepository.save(log);
            }
        }
    }

    public String generateWish(String name, Integer age, String category, String notes, String tone, String lang, String extraInstructions) {
        if (!settingService.getBooleanSetting(SettingService.MODULE_AI_ENABLED)) {
            return generateLocalFallback(name, age, category, notes, tone, lang, extraInstructions);
        }

        String prompt = buildPrompt(name, age, category, notes, tone, lang, extraInstructions);

        try {
            String encodedPrompt = java.net.URLEncoder.encode(prompt, java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
            String url = "https://text.pollinations.ai/" + encodedPrompt;
            
            String generatedText = restTemplate.getForObject(url, String.class);
            if (generatedText != null && !generatedText.trim().isEmpty()) {
                String result = generatedText.trim();
                logUsage("WISH", prompt, result);
                return result;
            }
        } catch (Exception e) {
            System.err.println("Error calling Pollinations AI for text: " + e.getMessage());
        }

        // Fallback if API fails
        String fallbackResult = generateLocalFallback(name, age, category, notes, tone, lang, extraInstructions);
        logUsage("WISH", prompt, fallbackResult);
        return fallbackResult;
    }

    private String buildPrompt(String name, Integer age, String category, String notes, String tone, String lang, String extraInstructions) {
        StringBuilder sb = new StringBuilder();
        sb.append("Write a personalized birthday wish for a person with the following details:\n");
        sb.append("- Name: ").append(name).append("\n");
        if (age != null && age > 0) {
            sb.append("- Age: ").append(age).append(" years old\n");
        }
        sb.append("- Relationship category: ").append(category).append("\n");
        if (notes != null && !notes.trim().isEmpty()) {
            sb.append("- Notes & interests: ").append(notes).append("\n");
        }
        sb.append("- Requested tone: ").append(tone).append("\n");
        if (extraInstructions != null && !extraInstructions.trim().isEmpty()) {
            sb.append("- Additional instructions: ").append(extraInstructions).append("\n");
        }
        
        sb.append("\nCRITICAL INSTRUCTIONS:\n");
        sb.append("1. Write the message in the language: ").append(lang).append("\n");
        sb.append("2. Output ONLY the birthday wish content itself. Do NOT include any intro or outro, do NOT wrap in markdown, quotes, code blocks, or explanations. Just start with the actual message.\n");
        sb.append("3. Keep it warm, personalized, and appropriate for the relationship and tone.\n");
        
        return sb.toString();
    }

    private String generateLocalFallback(String name, Integer age, String category, String notes, String tone, String lang, String extraInstructions) {
        boolean isEn = "en".equalsIgnoreCase(lang);
        boolean isDe = "de".equalsIgnoreCase(lang);
        
        String ageStr = (age != null && age > 0) ? (isEn ? " " + age + "th" : isDe ? " " + age + "." : " " + age + " ans") : "";
        
        if (isEn) {
            if ("funny".equalsIgnoreCase(tone)) {
                return "Happy birthday " + name + "!" + ageStr + " looks good on you, but let's not count the candles, it might be a fire hazard! Hope you have an awesome day filled with laughter! 🎉😜";
            } else if ("formal".equalsIgnoreCase(tone)) {
                return "Dear " + name + ", wishing you a very happy birthday. May this new year of life bring you continued success, good health, and happiness. Best regards. ✨";
            } else if ("poetic".equalsIgnoreCase(tone)) {
                return "On this special day, " + name + ", may your heart be light and your dreams take flight. Wishing you a beautiful year ahead, full of wonder and delight. Happy birthday! 🌸";
            } else {
                return "Happy birthday " + name + "! Wishing you a wonderful day full of joy, happiness, and beautiful memories. Cheers to another great year! 🎂🎉";
            }
        } else if (isDe) {
            if ("funny".equalsIgnoreCase(tone)) {
                return "Alles Gute zum Geburtstag, " + name + "! Wieder ein Jahr älter... Aber keine Sorge, man ist nur so alt, wie man sich fühlt! Lass dich reich beschenken! 😜🍰";
            } else if ("formal".equalsIgnoreCase(tone)) {
                return "Sehr geehrte(r) " + name + ", ich wünsche Ihnen alles Gute zum Geburtstag. Möge das neue Lebensjahr Ihnen Erfolg, Freude und Gesundheit bringen. Mit freundlichen Grüßen. ✨";
            } else if ("poetic".equalsIgnoreCase(tone)) {
                return "Zum Geburtstag viel Sonnenschein, Gesundheit und ein glücklich Sein. Mögen deine Träume fliegen und alle Sorgen unterliegen. Alles Gute, " + name + "! 🌸";
            } else {
                return "Herzlichen Glückwunsch zum Geburtstag, " + name + "! Ich wünsche dir einen wundervollen Tag voller Freude und toller Momente im Kreise deiner Lieben. 🎉🎂";
            }
        } else {
            // French default
            if ("funny".equalsIgnoreCase(tone)) {
                return "Joyeux anniversaire " + name + " ! Déjà" + ageStr + "... mais t'inquiète pas, tu restes jeune dans ta tête ! Passe une excellente journée pleine de rires et de folie ! 😜🍰";
            } else if ("formal".equalsIgnoreCase(tone)) {
                return "Je vous souhaite un très heureux anniversaire, " + name + ". Que cette nouvelle année vous apporte réussite personnelle et professionnelle, ainsi qu'une excellente santé. Bien cordialement. ✨";
            } else if ("poetic".equalsIgnoreCase(tone)) {
                return "En ce jour unique, " + name + ", que chaque instant soit poésie et douceur. Que le vent t'apporte joie et bonheur pour toute l'année à venir. Joyeux anniversaire. 🌸";
            } else {
                return "Joyeux anniversaire " + name + " ! Je te souhaite une magnifique journée remplie de joie, de bonheur et entouré de tous ceux qui te sont chers. Gros bisous ! 🎉🎂";
            }
        }
    }

    public GiftSuggestionResponse generateGiftSuggestions(String name, Integer age, String gender, String category, List<String> interests, String lang) {
        if (!settingService.getBooleanSetting(SettingService.MODULE_AI_ENABLED)) {
            return generateLocalFallbackResponse(name, age, gender, category, interests, lang);
        }

        StringBuilder prompt = new StringBuilder();
        prompt.append("Suggest 3 gift ideas for a person with the following details:\n");
        prompt.append("- Name: ").append(name).append("\n");
        if (age != null && age > 0) {
            prompt.append("- Age: ").append(age).append(" years old\n");
        }
        if (gender != null && !gender.trim().isEmpty()) {
            prompt.append("- Gender: ").append(gender).append("\n");
        }
        prompt.append("- Relationship category: ").append(category).append("\n");
        if (interests != null && !interests.isEmpty()) {
            prompt.append("- Interests: ").append(String.join(", ", interests)).append("\n");
        }
        prompt.append("- Language: ").append(lang).append("\n\n");
        
        prompt.append("Return ONLY a valid JSON array of objects, with no markdown formatting or extra text. Each object must have these exact keys:\n");
        prompt.append("- name: name of the gift\n");
        prompt.append("- estimatedPrice: rough price range\n");
        prompt.append("- whereToBuy: general store or website types\n");
        prompt.append("- purchaseLink: JUST the specific product name or search term for Amazon (e.g. 'Sony WH-1000XM4' or 'Lego Star Wars')\n");
        prompt.append("- preparationTips: how to present it or why it's a good idea\n");

        try {
            String encodedPrompt = java.net.URLEncoder.encode(prompt.toString(), java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
            String url = "https://text.pollinations.ai/" + encodedPrompt;

            String generatedText = restTemplate.getForObject(url, String.class);
            
            if (generatedText != null && !generatedText.trim().isEmpty()) {
                generatedText = generatedText.trim();
                if (generatedText.startsWith("```json")) {
                    generatedText = generatedText.substring(7);
                }
                if (generatedText.startsWith("```")) {
                    generatedText = generatedText.substring(3);
                }
                if (generatedText.endsWith("```")) {
                    generatedText = generatedText.substring(0, generatedText.length() - 3);
                }
                generatedText = generatedText.trim();
                logUsage("GIFT", prompt.toString(), generatedText);
                ObjectMapper mapper = new ObjectMapper();
                List<GiftSuggestion> suggestions = mapper.readValue(generatedText, new TypeReference<List<GiftSuggestion>>() {});
                
                String amazonTag = settingService.getSetting(SettingService.AMAZON_AFFILIATE_TAG) != null ? settingService.getSetting(SettingService.AMAZON_AFFILIATE_TAG).getValue() : "time2wish-21";
                String fnacTag = settingService.getSetting(SettingService.FNAC_AFFILIATE_TAG) != null ? settingService.getSetting(SettingService.FNAC_AFFILIATE_TAG).getValue() : "time2wish";
                String etsyTag = settingService.getSetting(SettingService.ETSY_AFFILIATE_TAG) != null ? settingService.getSetting(SettingService.ETSY_AFFILIATE_TAG).getValue() : "time2wish";

                for (GiftSuggestion s : suggestions) {
                    String productName = s.getName();
                    if (s.getPurchaseLink() != null && !s.getPurchaseLink().startsWith("http")) {
                        productName = s.getPurchaseLink();
                    }
                    
                    try {
                        String encodedName = java.net.URLEncoder.encode(productName, java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
                        s.setImageUrl("https://image.pollinations.ai/prompt/" + encodedName + "%20isolated%20on%20white%20background");
                    } catch (Exception e) {}

                    if (s.getPurchaseLink() != null && !s.getPurchaseLink().startsWith("http")) {
                        String searchTerm = "";
                        try {
                            searchTerm = java.net.URLEncoder.encode(s.getPurchaseLink(), java.nio.charset.StandardCharsets.UTF_8);
                        } catch (Exception e) {}

                        String wtb = s.getWhereToBuy() != null ? s.getWhereToBuy().toLowerCase() : "";
                        if (wtb.contains("fnac")) {
                            s.setPurchaseLink("https://www.fnac.com/SearchResult/ResultList.aspx?Search=" + searchTerm + "&awin=" + fnacTag);
                        } else if (wtb.contains("etsy")) {
                            s.setPurchaseLink("https://www.etsy.com/search?q=" + searchTerm + "&ref=" + etsyTag);
                        } else if (wtb.contains("sephora")) {
                            s.setPurchaseLink("https://www.sephora.fr/recherche?q=" + searchTerm);
                        } else if (wtb.contains("decathlon")) {
                            s.setPurchaseLink("https://www.decathlon.fr/search?Ntt=" + searchTerm);
                        } else {
                            String domain = "fr";
                            if ("en".equalsIgnoreCase(lang)) domain = "com";
                            else if ("de".equalsIgnoreCase(lang)) domain = "de";
                            s.setPurchaseLink("https://www.amazon." + domain + "/s?k=" + searchTerm + "&tag=" + amazonTag);
                        }
                    }
                }
                
                return new GiftSuggestionResponse(suggestions, "AI");
            }
        } catch (Exception e) {
            System.err.println("Error calling Pollinations AI for gift suggestions: " + e.getMessage());
        }

        GiftSuggestionResponse fallback = new GiftSuggestionResponse(generateLocalFallbackGifts(name, age, gender, category, interests, lang), "LOCAL");
        logUsage("GIFT", prompt.toString(), "Local Fallback JSON array");
        return fallback;
    }

    public GiftSuggestionResponse generateLocalFallbackResponse(String name, Integer age, String gender, String category, List<String> interests, String lang) {
        return new GiftSuggestionResponse(generateLocalFallbackGifts(name, age, gender, category, interests, lang), "LOCAL");
    }

    private List<GiftSuggestion> generateLocalFallbackGifts(String name, Integer age, String gender, String category, List<String> interests, String lang) {
        boolean isEn = "en".equalsIgnoreCase(lang);
        boolean isDe = "de".equalsIgnoreCase(lang);

        List<GiftSuggestion> suggestions = new ArrayList<>();
        String interestsStr = (interests != null) ? String.join(" ", interests).toLowerCase() : "";

        // Rules based on interests
        if (interestsStr.contains("sport") || interestsStr.contains("fitness") || interestsStr.contains("foot") || interestsStr.contains("tennis") || interestsStr.contains("gym")) {
            if (isEn) suggestions.add(new GiftSuggestion("Sports Equipment / Match Tickets", "$30 - $100", "Sports store, Ticketmaster", "https://amazon.com/s?k=sports+equipment", "Perfect for their passion for sports."));
            else if (isDe) suggestions.add(new GiftSuggestion("Sportausrüstung / Tickets", "30€ - 100€", "Sportgeschäft, Ticketmaster", "https://amazon.de/s?k=sport", "Perfekt für ihre Leidenschaft für Sport."));
            else suggestions.add(new GiftSuggestion("Équipement sportif / Billets de match", "30€ - 100€", "Decathlon, Fnac Spectacles", "https://www.decathlon.fr/", "Idéal pour accompagner sa passion pour le sport."));
        }
        if (interestsStr.contains("livre") || interestsStr.contains("lecture") || interestsStr.contains("book") || interestsStr.contains("read")) {
            if (isEn) suggestions.add(new GiftSuggestion("Bestseller Book / E-reader", "$15 - $120", "Bookstore, Amazon", "https://amazon.com/s?k=bestseller+books", "A great novel or a bookstore gift card."));
            else if (isDe) suggestions.add(new GiftSuggestion("Bestseller-Buch / E-Reader", "15€ - 120€", "Buchhandlung, Amazon", "https://amazon.de/s?k=bestseller+buch", "Ein guter Roman oder ein Gutschein für die Buchhandlung."));
            else suggestions.add(new GiftSuggestion("Livre Bestseller / Liseuse", "15€ - 120€", "Fnac, Cultura, Librairie", "https://livre.fnac.com/", "Un bon roman ou une carte cadeau en librairie."));
        }
        if (interestsStr.contains("jeux") || interestsStr.contains("game") || interestsStr.contains("video")) {
            if (isEn) suggestions.add(new GiftSuggestion("Video Game / Board Game", "$20 - $70", "Gaming store", "https://amazon.com/s?k=board+games", "A fun game to play solo or with friends."));
            else if (isDe) suggestions.add(new GiftSuggestion("Videospiel / Brettspiel", "20€ - 70€", "Spieleladen", "https://amazon.de/s?k=brettspiele", "Ein lustiges Spiel für alleine oder mit Freunden."));
            else suggestions.add(new GiftSuggestion("Jeu Vidéo / Jeu de société", "20€ - 70€", "Micromania, Philibert", "https://www.philibertnet.com/", "Un jeu sympa à faire en solo ou entre amis."));
        }
        if (interestsStr.contains("voyage") || interestsStr.contains("travel") || interestsStr.contains("reise")) {
            if (isEn) suggestions.add(new GiftSuggestion("Travel Accessories / Scratch Map", "$15 - $50", "Travel store", "https://amazon.com/s?k=travel+gifts", "Something useful for their next adventure."));
            else if (isDe) suggestions.add(new GiftSuggestion("Reisezubehör / Rubbelweltkarte", "15€ - 50€", "Reisegeschäft", "https://amazon.de/s?k=reise+geschenke", "Etwas Nützliches für das nächste Abenteuer."));
            else suggestions.add(new GiftSuggestion("Accessoire de voyage / Carte à gratter", "15€ - 50€", "Nature & Découvertes", "https://www.natureetdecouvertes.com/", "Quelque chose d'utile pour sa prochaine aventure."));
        }
        if (interestsStr.contains("musique") || interestsStr.contains("music") || interestsStr.contains("musik") || interestsStr.contains("concert")) {
            if (isEn) suggestions.add(new GiftSuggestion("Concert Tickets / Vinyl Record", "$20 - $80", "Ticketmaster, Record store", "https://amazon.com/s?k=vinyl", "Great for music lovers."));
            else if (isDe) suggestions.add(new GiftSuggestion("Konzertkarten / Schallplatte", "20€ - 80€", "Ticketmaster, Plattenladen", "https://amazon.de/s?k=schallplatte", "Toll für Musikliebhaber."));
            else suggestions.add(new GiftSuggestion("Place de concert / Vinyle", "20€ - 80€", "Fnac Spectacles, Disquaire", "https://www.fnac.com/", "Parfait pour vibrer au rythme de sa musique préférée."));
        }
        if (interestsStr.contains("art") || interestsStr.contains("dessin") || interestsStr.contains("draw") || interestsStr.contains("paint")) {
            if (isEn) suggestions.add(new GiftSuggestion("Art Supplies / Museum Pass", "$20 - $60", "Art store", "https://amazon.com/s?k=art+supplies", "Fuel their creativity."));
            else if (isDe) suggestions.add(new GiftSuggestion("Künstlerbedarf / Museumspass", "20€ - 60€", "Kunstbedarf", "https://amazon.de/s?k=künstlerbedarf", "Fördere ihre Kreativität."));
            else suggestions.add(new GiftSuggestion("Matériel d'Art / Pass Musée", "20€ - 60€", "Cultura, Géant des Beaux-Arts", "https://www.cultura.com/", "Pour nourrir sa créativité et son inspiration."));
        }

        // Rules based on age
        if (age != null) {
            if (age < 12) {
                if (isEn) suggestions.add(new GiftSuggestion("Educational Toy / Lego Set", "$20 - $50", "Toy store", "https://amazon.com/s?k=lego", "Fun and educational."));
                else if (isDe) suggestions.add(new GiftSuggestion("Lernspielzeug / Lego-Set", "20€ - 50€", "Spielzeugladen", "https://amazon.de/s?k=lego", "Spaßig und lehrreich."));
                else suggestions.add(new GiftSuggestion("Jouet éducatif / Set Lego", "20€ - 50€", "JouéClub, Maxi Toys", "https://www.joueclub.fr/", "Amusant et stimulant pour son âge."));
            } else if (age >= 18 && age < 30) {
                if (isEn) suggestions.add(new GiftSuggestion("Tech Gadget / Wireless Earbuds", "$30 - $100", "Electronics store", "https://amazon.com/s?k=tech+gadget", "A cool gadget they'll use everyday."));
                else if (isDe) suggestions.add(new GiftSuggestion("Tech-Gadget / Kabellose Kopfhörer", "30€ - 100€", "Elektronikmarkt", "https://amazon.de/s?k=tech+gadget", "Ein cooles Gadget für jeden Tag."));
                else suggestions.add(new GiftSuggestion("Gadget Tech / Écouteurs sans fil", "30€ - 100€", "Boulanger, Amazon", "https://www.boulanger.com/", "Un gadget sympa à utiliser au quotidien."));
            }
        }

        // General fallbacks to fill up the list
        if (suggestions.size() < 3) {
            if (isEn) {
                suggestions.add(new GiftSuggestion("Custom Photo Album", "$25 - $50", "Online print shops", "https://amazon.com/s?k=photo+album", "Fill it with some of your favorite memories together."));
                suggestions.add(new GiftSuggestion("Gourmet Gift Set", "$30 - $60", "Specialty food stores", "https://amazon.com/s?k=gourmet+gift", "Perfect for food lovers."));
                suggestions.add(new GiftSuggestion("Gift Card", "$50+", "Any major store", "https://amazon.com/gift-cards", "When in doubt, let them choose."));
            } else if (isDe) {
                suggestions.add(new GiftSuggestion("Personalisiertes Fotoalbum", "25€ - 50€", "Online-Druckereien", "https://amazon.de/s?k=fotoalbum", "Fülle es mit schönen Erinnerungen."));
                suggestions.add(new GiftSuggestion("Feinkost-Geschenkset", "30€ - 60€", "Feinkostläden", "https://amazon.de/s?k=feinkost", "Perfekt für Feinschmecker."));
                suggestions.add(new GiftSuggestion("Gutschein", "50€+", "Jedes größere Geschäft", "https://amazon.de/gift-cards", "Wenn du dir unsicher bist, lass sie selbst wählen."));
            } else {
                suggestions.add(new GiftSuggestion("Album photo personnalisé", "25€ - 50€", "Cheerz, Photobox", "https://amazon.fr/s?k=album+photo", "Prenez le temps d'y glisser vos meilleurs souvenirs avec " + name + "."));
                suggestions.add(new GiftSuggestion("Coffret découverte épicerie fine", "20€ - 40€", "Boutiques spécialisées", "https://amazon.fr/s?k=coffret+gourmand", "Un cadeau réconfortant qui fait toujours plaisir."));
                suggestions.add(new GiftSuggestion("Carte cadeau Multi-enseignes", "50€+", "Fnac, Cultura, Illicado", "https://www.illicado.com/", "Idéal quand on manque d'inspiration ou que " + name + " est difficile à combler !"));
            }
        }
        
        // Remove duplicates if any, and limit to 4 to give a nice selection
        List<GiftSuggestion> results = suggestions.stream()
            .distinct()
            .limit(4)
            .toList();

        for (GiftSuggestion s : results) {
            try {
                String encodedName = java.net.URLEncoder.encode(s.getName(), java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
                s.setImageUrl("https://image.pollinations.ai/prompt/" + encodedName + "%20isolated%20on%20white%20background");
            } catch (Exception e) {}
        }
        
        return results;
    }
}
