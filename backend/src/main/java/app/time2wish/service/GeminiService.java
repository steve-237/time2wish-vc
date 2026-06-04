package app.time2wish.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.*;

@Service
public class GeminiService {

    @Value("${app.gemini.api-key:}")
    private String apiKey;

    @Value("${app.gemini.model:gemini-1.5-flash}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();

    public String generateWish(String name, Integer age, String category, String notes, String tone, String lang, String extraInstructions) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            return generateLocalFallback(name, age, category, notes, tone, lang, extraInstructions);
        }

        String prompt = buildPrompt(name, age, category, notes, tone, lang, extraInstructions);
        String url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + apiKey;

        try {
            // Build request payload for Gemini API
            Map<String, Object> requestBody = new HashMap<>();
            
            Map<String, Object> textPart = new HashMap<>();
            textPart.put("text", prompt);
            
            Map<String, Object> partsContainer = new HashMap<>();
            partsContainer.put("parts", List.of(textPart));
            
            requestBody.put("contents", List.of(partsContainer));

            // Call API
            Map<String, Object> response = restTemplate.postForObject(url, requestBody, Map.class);
            if (response != null) {
                List<Map<String, Object>> candidates = (List<Map<String, Object>>) response.get("candidates");
                if (candidates != null && !candidates.isEmpty()) {
                    Map<String, Object> content = (Map<String, Object>) candidates.get(0).get("content");
                    if (content != null) {
                        List<Map<String, Object>> parts = (List<Map<String, Object>>) content.get("parts");
                        if (parts != null && !parts.isEmpty()) {
                            String generatedText = (String) parts.get(0).get("text");
                            if (generatedText != null) {
                                return generatedText.trim();
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error calling Gemini API: " + e.getMessage());
        }

        // Fallback if API fails
        return generateLocalFallback(name, age, category, notes, tone, lang, extraInstructions);
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
}
