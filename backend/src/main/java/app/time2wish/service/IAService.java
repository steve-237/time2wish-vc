package app.time2wish.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
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

    // Fast RestTemplate with short timeouts (5 seconds connect, 8 seconds read)
    private final RestTemplate fastRestTemplate;
    // Standard RestTemplate (for longer operations if needed)
    private final RestTemplate restTemplate = new RestTemplate();
    private final AILogRepository aiLogRepository;
    private final UserRepository userRepository;
    private final SettingService settingService;

    public IAService(AILogRepository aiLogRepository, UserRepository userRepository, SettingService settingService) {
        this.aiLogRepository = aiLogRepository;
        this.userRepository = userRepository;
        this.settingService = settingService;

        // Configure RestTemplate with appropriate timeouts for LLM text generation
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10000); // 10 seconds to connect
        factory.setReadTimeout(25000);    // 25 seconds read timeout for LLM generation
        this.fastRestTemplate = new RestTemplate(factory);
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

    // =====================================================================
    // FREE AI TEXT GENERATION — Cascading Fallback System
    // Provider 1: Pollinations.ai POST JSON (OpenAI format, keyless)
    // Provider 2: Pollinations.ai GET (Single line prompt)
    // Provider 3: DevToolBox POST
    // Fallback: Local rule-based template engine
    // =====================================================================

    /**
     * Universal extractor to clean and parse text responses from any AI API (raw string or JSON).
     */
    private String cleanAndExtractText(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String str = raw.trim();

        // Strip markdown code blocks
        if (str.startsWith("```json")) {
            str = str.substring(7);
        } else if (str.startsWith("```")) {
            str = str.substring(3);
        }
        if (str.endsWith("```")) {
            str = str.substring(0, str.length() - 3);
        }
        str = str.trim();

        // If JSON object, extract text field recursively
        if (str.startsWith("{") && str.endsWith("}")) {
            try {
                ObjectMapper mapper = new ObjectMapper();
                Map<String, Object> map = mapper.readValue(str, new TypeReference<Map<String, Object>>() {});
                
                // Helper: convert value to JSON string (preserves arrays/objects as valid JSON)
                // Unlike .toString() which produces Java Map format like {key=value}
                java.util.function.Function<Object, String> toJsonString = (obj) -> {
                    if (obj instanceof String) return (String) obj;
                    try { return mapper.writeValueAsString(obj); } catch (Exception e) { return obj.toString(); }
                };

                if (map.containsKey("response") && map.get("response") != null) {
                    return cleanAndExtractText(toJsonString.apply(map.get("response")));
                }
                if (map.containsKey("result") && map.get("result") != null) {
                    return cleanAndExtractText(toJsonString.apply(map.get("result")));
                }
                if (map.containsKey("output") && map.get("output") != null) {
                    return cleanAndExtractText(toJsonString.apply(map.get("output")));
                }
                if (map.containsKey("text") && map.get("text") != null) {
                    return cleanAndExtractText(toJsonString.apply(map.get("text")));
                }
                if (map.containsKey("content") && map.get("content") != null) {
                    return cleanAndExtractText(toJsonString.apply(map.get("content")));
                }
                if (map.containsKey("choices")) {
                    List<Map<String, Object>> choices = (List<Map<String, Object>>) map.get("choices");
                    if (choices != null && !choices.isEmpty()) {
                        Map<String, Object> firstChoice = choices.get(0);
                        if (firstChoice.containsKey("message")) {
                            Map<String, Object> msg = (Map<String, Object>) firstChoice.get("message");
                            if (msg != null && msg.containsKey("content")) {
                                return cleanAndExtractText(toJsonString.apply(msg.get("content")));
                            }
                        }
                        if (firstChoice.containsKey("text")) {
                            return cleanAndExtractText(toJsonString.apply(firstChoice.get("text")));
                        }
                    }
                }
            } catch (Exception ignore) {}
        }
        return str;
    }

    /** Escape special characters for JSON string embedding */
    private String escapeJson(String input) {
        if (input == null) return "";
        return input
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", " ")
            .replace("\r", " ")
            .replace("\t", " ");
    }

    private String callFreeTextApis(String prompt) {
        // --- Provider 1: DevToolBox POST API (Free, keyless Cloudflare Worker LLM) ---
        try {
            String url = "https://devtoolbox-api.devtoolbox-api.workers.dev/ai/generate";
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, String> requestBody = new HashMap<>();
            requestBody.put("prompt", prompt);

            ObjectMapper mapper = new ObjectMapper();
            String jsonPayload = mapper.writeValueAsString(requestBody);

            HttpEntity<String> entity = new HttpEntity<>(jsonPayload, headers);
            String result = fastRestTemplate.postForObject(url, entity, String.class);

            if (result != null && !result.trim().isEmpty()) {
                String parsed = cleanAndExtractText(result);
                if (parsed != null && !parsed.trim().isEmpty()) {
                    System.out.println("[AI Cascade] ✅ DevToolBox POST responded successfully.");
                    return parsed.trim();
                }
            }
        } catch (Exception e) {
            System.err.println("[AI Cascade] ⚠️ DevToolBox POST failed: " + e.getMessage());
        }

        // --- Provider 2: Pollinations POST JSON API (Fallback) ---
        try {
            String url = "https://text.pollinations.ai/";
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> message = new HashMap<>();
            message.put("role", "user");
            message.put("content", prompt);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("messages", Collections.singletonList(message));

            ObjectMapper mapper = new ObjectMapper();
            String jsonPayload = mapper.writeValueAsString(requestBody);

            HttpEntity<String> entity = new HttpEntity<>(jsonPayload, headers);
            String result = fastRestTemplate.postForObject(url, entity, String.class);

            if (result != null && !result.trim().isEmpty()) {
                String parsed = cleanAndExtractText(result);
                if (parsed != null && !parsed.trim().isEmpty()) {
                    System.out.println("[AI Cascade] ✅ Pollinations POST JSON responded successfully.");
                    return parsed.trim();
                }
            }
        } catch (Exception e) {
            System.err.println("[AI Cascade] ⚠️ Pollinations POST JSON failed: " + e.getMessage());
        }

        // --- Provider 3: Pollinations GET simple prompt ---
        try {
            String cleanPrompt = prompt.replaceAll("[\\r\\n]+", " ").trim();
            String encodedPrompt = java.net.URLEncoder.encode(cleanPrompt, java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
            String url = "https://text.pollinations.ai/" + encodedPrompt;
            String result = fastRestTemplate.getForObject(url, String.class);
            if (result != null && !result.trim().isEmpty()) {
                String parsed = cleanAndExtractText(result);
                if (parsed != null && !parsed.trim().isEmpty()) {
                    System.out.println("[AI Cascade] ✅ Pollinations GET responded successfully.");
                    return parsed.trim();
                }
            }
        } catch (Exception e) {
            System.err.println("[AI Cascade] ⚠️ Pollinations GET failed: " + e.getMessage());
        }

        System.err.println("[AI Cascade] ❌ All free AI providers failed. Using local fallback.");
        return null;
    }

    // =====================================================================
    // WISH GENERATION
    // =====================================================================

    public String generateWish(String name, Integer age, String category, String notes, String tone, String lang, String extraInstructions) {
        if (!settingService.getBooleanSetting(SettingService.MODULE_AI_ENABLED)) {
            return generateLocalFallback(name, age, category, notes, tone, lang, extraInstructions);
        }

        String prompt = buildPrompt(name, age, category, notes, tone, lang, extraInstructions);

        // Try the cascade of free APIs
        String generatedText = callFreeTextApis(prompt);
        if (generatedText != null) {
            logUsage("WISH", prompt, generatedText);
            return generatedText;
        }

        // All APIs failed — use local fallback
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

    // =====================================================================
    // GIFT SUGGESTIONS
    // =====================================================================

    public GiftSuggestionResponse generateGiftSuggestions(String name, Integer age, String gender, String category, List<String> interests, String lang) {
        if (!settingService.getBooleanSetting(SettingService.MODULE_AI_ENABLED)) {
            return generateLocalFallbackResponse(name, age, gender, category, interests, lang);
        }

        StringBuilder prompt = new StringBuilder();
        prompt.append("Suggest 6 creative and diverse gift ideas for a person with the following details:\n");
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
        
        prompt.append("Return ONLY a valid JSON array of objects, with no markdown formatting or extra text. ALL values MUST be quoted strings. Each object must have these exact keys:\n");
        prompt.append("- name: string, name of the gift\n");
        prompt.append("- estimatedPrice: string, rough price range (e.g. \"30-50€\")\n");
        prompt.append("- whereToBuy: string, general store or website types\n");
        prompt.append("- purchaseLink: string, JUST the specific product name or search term for Amazon (e.g. \"Sony WH-1000XM4\")\n");
        prompt.append("- preparationTips: string, how to present it or why it's a good idea\n");
        prompt.append("\nExample format: [{\"name\":\"Book\",\"estimatedPrice\":\"15-25€\",\"whereToBuy\":\"Amazon\",\"purchaseLink\":\"Bestseller book\",\"preparationTips\":\"Wrap it nicely\"}]\n");

        // Try the cascade of free APIs
        String generatedText = callFreeTextApis(prompt.toString());
        List<GiftSuggestion> aiSuggestions = new ArrayList<>();

        if (generatedText != null && !generatedText.trim().isEmpty()) {
            try {
                String cleanText = generatedText.trim();
                // Strip markdown code blocks if present
                if (cleanText.startsWith("```json")) {
                    cleanText = cleanText.substring(7);
                } else if (cleanText.startsWith("```")) {
                    cleanText = cleanText.substring(3);
                }
                if (cleanText.endsWith("```")) {
                    cleanText = cleanText.substring(0, cleanText.length() - 3);
                }
                cleanText = cleanText.trim();

                // Extract JSON array substring from [ to ] if surrounded by extra text
                int firstBracket = cleanText.indexOf("[");
                int lastBracket = cleanText.lastIndexOf("]");
                if (firstBracket != -1 && lastBracket > firstBracket) {
                    cleanText = cleanText.substring(firstBracket, lastBracket + 1);
                }

                // Sanitize JSON: quote unquoted values like  50-150€
                cleanText = cleanText.replaceAll(":\\s*([0-9][^,\"\\}\\]]*[^,\"\\}\\]\\s])", ": \"$1\"");

                // Build a lenient ObjectMapper that tolerates AI quirks
                ObjectMapper mapper = com.fasterxml.jackson.databind.json.JsonMapper.builder()
                    .enable(com.fasterxml.jackson.core.json.JsonReadFeature.ALLOW_UNESCAPED_CONTROL_CHARS)
                    .enable(com.fasterxml.jackson.core.json.JsonReadFeature.ALLOW_UNQUOTED_FIELD_NAMES)
                    .enable(com.fasterxml.jackson.core.json.JsonReadFeature.ALLOW_SINGLE_QUOTES)
                    .enable(com.fasterxml.jackson.core.json.JsonReadFeature.ALLOW_TRAILING_COMMA)
                    .build();
                mapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

                logUsage("GIFT", prompt.toString(), cleanText);
                System.out.println("[AI Cascade] 🔍 Attempting to parse gift JSON (" + cleanText.length() + " chars): " + cleanText.substring(0, Math.min(cleanText.length(), 300)));

                // First try: parse directly as List<GiftSuggestion>
                List<GiftSuggestion> suggestions = null;
                try {
                    suggestions = mapper.readValue(cleanText, new TypeReference<List<GiftSuggestion>>() {});
                } catch (Exception directParseEx) {
                    System.err.println("[AI Cascade] 🔄 Direct parse failed: " + directParseEx.getMessage());
                    // Second try: AI sometimes wraps as array-of-strings like ["{ json... }"]
                    try {
                        List<String> stringList = mapper.readValue(cleanText, new TypeReference<List<String>>() {});
                        if (stringList != null && !stringList.isEmpty()) {
                            // Concatenate all strings and re-parse
                            StringBuilder combined = new StringBuilder("[");
                            for (int i = 0; i < stringList.size(); i++) {
                                if (i > 0) combined.append(",");
                                String s = stringList.get(i).trim();
                                // If the string itself is a JSON object or array, include it directly
                                if (s.startsWith("{") || s.startsWith("[")) {
                                    combined.append(s);
                                }
                            }
                            combined.append("]");
                            String recombined = combined.toString();
                            System.out.println("[AI Cascade] 🔄 Recombined from string-array: " + recombined.substring(0, Math.min(recombined.length(), 300)));
                            suggestions = mapper.readValue(recombined, new TypeReference<List<GiftSuggestion>>() {});
                        }
                    } catch (Exception stringParseEx) {
                        System.err.println("[AI Cascade] 🔄 String-array parse also failed: " + stringParseEx.getMessage());
                        throw directParseEx; // Re-throw original to fall through to text parser
                    }
                }
                
                if (suggestions != null && !suggestions.isEmpty()) {
                    aiSuggestions.addAll(suggestions);
                    System.out.println("[AI Cascade] ✅ Parsed " + suggestions.size() + " AI gift suggestions successfully.");
                }
            } catch (Exception e) {
                System.err.println("[AI Cascade] ⚠️ Failed to parse JSON AI gift response: " + e.getMessage() + ". Trying line parser...");
                System.err.println("[AI Cascade] 🔍 Raw text was: " + generatedText.substring(0, Math.min(generatedText.length(), 500)));
                // Attempt plain text list line parsing if AI returned bullet points instead of JSON
                List<GiftSuggestion> parsedLines = parseTextGiftSuggestions(generatedText);
                if (parsedLines != null && !parsedLines.isEmpty()) {
                    aiSuggestions.addAll(parsedLines);
                    System.out.println("[AI Cascade] ✅ Parsed " + parsedLines.size() + " text-formatted AI gift suggestions.");
                }
            }
        }

        int TARGET = 25;
        List<GiftSuggestion> localSuggestions = generateLocalFallbackGifts(name, age, gender, category, interests, lang);

        List<GiftSuggestion> combined = new ArrayList<>(aiSuggestions);
        java.util.Set<String> existingNames = aiSuggestions.stream().map(s -> s.getName().toLowerCase()).collect(java.util.stream.Collectors.toSet());
        for (GiftSuggestion local : localSuggestions) {
            if (combined.size() >= TARGET) break;
            if (!existingNames.contains(local.getName().toLowerCase())) {
                combined.add(local);
                existingNames.add(local.getName().toLowerCase());
            }
        }
        
        enrichGiftSuggestions(combined, lang);
        String source = aiSuggestions.isEmpty() ? "LOCAL" : "AI";
        logUsage("GIFT", prompt.toString(), "Hybrid fallback with source=" + source);
        return new GiftSuggestionResponse(combined, source);
    }

    /**
     * Fallback parser for plain text / markdown bullet lists returned by AI models for gift ideas.
     */
    private List<GiftSuggestion> parseTextGiftSuggestions(String text) {
        if (text == null || text.trim().isEmpty()) return null;
        List<GiftSuggestion> list = new ArrayList<>();
        String[] lines = text.split("\n");
        for (String line : lines) {
            String trimmed = line.trim();
            // Match lines starting with 1., 2., 3., -, *, or •
            if (trimmed.matches("^(?:\\d+[\\.\\)]|[-*•])\\s+.+")) {
                String cleanLine = trimmed.replaceAll("^(?:\\d+[\\.\\)]|[-*•])\\s+", "");
                String[] parts = cleanLine.split("[-–:;]");
                String name = parts[0].trim();
                if (!name.isEmpty()) {
                    String price = parts.length > 1 ? parts[1].trim() : "20€ - 50€";
                    String tips = parts.length > 2 ? parts[2].trim() : "Une excellente idée personnalisée.";
                    list.add(new GiftSuggestion(name, price, "Boutiques spécialisées", name, tips));
                }
            }
        }
        return list.isEmpty() ? null : list;
    }

    /**
     * Enriches gift suggestions with affiliate purchase links and image URLs.
     */
    private void enrichGiftSuggestions(List<GiftSuggestion> suggestions, String lang) {
        String amazonTag = settingService.getSetting(SettingService.AMAZON_AFFILIATE_TAG) != null ? settingService.getSetting(SettingService.AMAZON_AFFILIATE_TAG).getValue() : "time2wish-21";
        String fnacTag = settingService.getSetting(SettingService.FNAC_AFFILIATE_TAG) != null ? settingService.getSetting(SettingService.FNAC_AFFILIATE_TAG).getValue() : "time2wish";
        String etsyTag = settingService.getSetting(SettingService.ETSY_AFFILIATE_TAG) != null ? settingService.getSetting(SettingService.ETSY_AFFILIATE_TAG).getValue() : "time2wish";

        for (GiftSuggestion s : suggestions) {
            String nameForImage = s.getName() != null && !s.getName().trim().isEmpty() ? s.getName() : "gift item";
            
            try {
                String imagePrompt = "High quality studio product photograph of " + nameForImage + ", centered on clean white background, 4k photo";
                String encodedPrompt = java.net.URLEncoder.encode(imagePrompt, java.nio.charset.StandardCharsets.UTF_8).replace("+", "%20");
                s.setImageUrl("https://image.pollinations.ai/prompt/" + encodedPrompt + "?width=400&height=400&nologo=true");
            } catch (Exception e) {}

            String productName = s.getName();
            if (s.getPurchaseLink() != null && !s.getPurchaseLink().startsWith("http")) {
                productName = s.getPurchaseLink();
            }

            if (s.getPurchaseLink() == null || !s.getPurchaseLink().startsWith("http")) {
                String searchTerm = "";
                try {
                    searchTerm = java.net.URLEncoder.encode(productName, java.nio.charset.StandardCharsets.UTF_8);
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
    }

    public GiftSuggestionResponse generateLocalFallbackResponse(String name, Integer age, String gender, String category, List<String> interests, String lang) {
        return new GiftSuggestionResponse(generateLocalFallbackGifts(name, age, gender, category, interests, lang), "LOCAL");
    }

    private List<GiftSuggestion> generateLocalFallbackGifts(String name, Integer age, String gender, String category, List<String> interests, String lang) {
        List<GiftSuggestion> sports = new ArrayList<>();
        sports.add(new GiftSuggestion("Tapis de yoga premium", "25-50€", "Decathlon/Amazon", "tapis yoga premium", "Idéal pour ses séances de sport."));
        sports.add(new GiftSuggestion("Gourde isotherme personnalisée", "15-35€", "Amazon", "gourde isotherme", "Pratique pour rester hydraté."));
        sports.add(new GiftSuggestion("Montre connectée fitness", "50-150€", "Boulanger/Amazon", "montre connectée fitness", "Pour suivre ses performances."));
        sports.add(new GiftSuggestion("Sac de sport Nike/Adidas", "30-60€", "Nike Store/Amazon", "sac de sport", "Toujours utile pour l'entraînement."));
        sports.add(new GiftSuggestion("Abonnement salle de sport (1 mois)", "30-50€", "Basic Fit/Neoness", "abonnement salle de sport", "Pour garder la forme."));
        sports.add(new GiftSuggestion("Bandes de résistance élastiques", "15-30€", "Decathlon", "bandes resistance elastiques", "Pour s'entraîner partout."));
        sports.add(new GiftSuggestion("Ballon de football officiel", "20-40€", "Decathlon", "ballon football", "Pour les matchs entre amis."));

        List<GiftSuggestion> tech = new ArrayList<>();
        tech.add(new GiftSuggestion("Écouteurs sans fil Bluetooth", "30-100€", "Boulanger/Amazon", "ecouteurs sans fil bluetooth", "Pour écouter de la musique partout."));
        tech.add(new GiftSuggestion("Support téléphone voiture magnétique", "10-25€", "Amazon", "support telephone voiture magnetique", "Très pratique en conduisant."));
        tech.add(new GiftSuggestion("Batterie externe 20000mAh", "20-40€", "Amazon", "batterie externe 20000mAh", "Pour ne jamais tomber en panne."));
        tech.add(new GiftSuggestion("Enceinte Bluetooth portable", "30-80€", "Fnac/Amazon", "enceinte bluetooth portable", "Pour mettre l'ambiance."));
        tech.add(new GiftSuggestion("Lampe LED de bureau avec chargeur sans fil", "25-50€", "Amazon", "lampe bureau led chargeur sans fil", "Un ajout moderne à son bureau."));
        tech.add(new GiftSuggestion("Clé USB 128Go design", "15-25€", "Amazon", "cle usb 128go", "Pour stocker tous ses fichiers."));
        tech.add(new GiftSuggestion("Ring light pour selfie/visio", "15-35€", "Amazon", "ring light", "Pour un éclairage parfait."));

        List<GiftSuggestion> books = new ArrayList<>();
        books.add(new GiftSuggestion("Bestseller du moment", "15-25€", "Fnac/Cultura", "bestseller livre", "Une valeur sûre."));
        books.add(new GiftSuggestion("Liseuse électronique Kindle", "80-130€", "Amazon", "kindle liseuse", "Pour avoir tous ses livres avec soi."));
        books.add(new GiftSuggestion("Abonnement Audible (3 mois)", "30€", "Amazon/Audible", "abonnement audible", "Pour écouter des livres en voiture."));
        books.add(new GiftSuggestion("Coffret intégrale BD/Manga populaire", "30-60€", "Fnac", "coffret manga bd", "Pour les passionnés de lecture."));
        books.add(new GiftSuggestion("Carnet Moleskine premium", "15-25€", "Fnac/Amazon", "carnet moleskine", "Pour noter toutes ses idées."));

        List<GiftSuggestion> cooking = new ArrayList<>();
        cooking.add(new GiftSuggestion("Coffret dégustation thés du monde", "20-40€", "Palais des Thés", "coffret the degustation", "Un moment de détente assuré."));
        cooking.add(new GiftSuggestion("Kit cocktails maison avec shaker", "25-50€", "Amazon", "kit cocktail", "Pour des soirées réussies."));
        cooking.add(new GiftSuggestion("Livre de recettes chef étoilé", "20-35€", "Fnac/Amazon", "livre recette chef", "Pour s'inspirer en cuisine."));
        cooking.add(new GiftSuggestion("Planche à découper en bois d'olivier", "20-40€", "Amazon", "planche a decouper bois olivier", "Un très bel objet utile."));
        cooking.add(new GiftSuggestion("Coffret épices rares du monde", "25-45€", "Amazon", "coffret epices", "Pour relever ses plats."));
        cooking.add(new GiftSuggestion("Machine à pâtes fraîches", "30-60€", "Amazon", "machine a pates", "Pour faire ses pâtes maison."));
        cooking.add(new GiftSuggestion("Tablier de cuisine personnalisé", "15-30€", "Amazon", "tablier cuisine", "Pour cuisiner avec style."));

        List<GiftSuggestion> wellness = new ArrayList<>();
        wellness.add(new GiftSuggestion("Coffret soins visage bio", "25-50€", "Sephora/Amazon", "coffret soins visage bio", "Pour prendre soin de soi."));
        wellness.add(new GiftSuggestion("Diffuseur huiles essentielles avec LED", "20-40€", "Amazon", "diffuseur huiles essentielles", "Pour une atmosphère relaxante."));
        wellness.add(new GiftSuggestion("Bougie parfumée luxe (Yankee Candle)", "15-30€", "Amazon", "bougie yankee candle", "Pour une ambiance chaleureuse."));
        wellness.add(new GiftSuggestion("Kit massage relaxation", "20-45€", "Amazon", "kit massage", "Un moment de détente."));
        wellness.add(new GiftSuggestion("Masque de nuit en soie", "10-25€", "Amazon", "masque de nuit soie", "Pour un sommeil réparateur."));
        wellness.add(new GiftSuggestion("Coffret bain moussant et bombes de bain", "15-30€", "Lush/Amazon", "bombes de bain", "Pour un bain relaxant."));

        List<GiftSuggestion> fashion = new ArrayList<>();
        fashion.add(new GiftSuggestion("Écharpe cachemire", "30-80€", "Amazon/Galeries Lafayette", "echarpe cachemire", "Pour passer l'hiver au chaud."));
        fashion.add(new GiftSuggestion("Portefeuille en cuir véritable", "20-50€", "Amazon", "portefeuille cuir", "Un classique toujours utile."));
        fashion.add(new GiftSuggestion("Lunettes de soleil polarisées", "20-60€", "Amazon", "lunettes de soleil polarisees", "Pour protéger ses yeux avec style."));
        fashion.add(new GiftSuggestion("Montre classique élégante", "30-100€", "Amazon", "montre homme femme", "Un accessoire intemporel."));
        fashion.add(new GiftSuggestion("Sac à dos urbain tendance", "30-60€", "Amazon", "sac a dos urbain", "Pratique pour tous les jours."));

        List<GiftSuggestion> home = new ArrayList<>();
        home.add(new GiftSuggestion("Lampe d'ambiance LED connectée Philips Hue", "30-60€", "Amazon", "philips hue lampe", "Pour créer la bonne ambiance."));
        home.add(new GiftSuggestion("Cadre photo numérique WiFi", "40-80€", "Amazon", "cadre photo numerique wifi", "Pour afficher ses meilleurs souvenirs."));
        home.add(new GiftSuggestion("Plante d'intérieur avec pot design", "15-35€", "Jardiland", "plante interieur pot", "Pour apporter un peu de verdure."));
        home.add(new GiftSuggestion("Couverture plaid polaire doux", "20-40€", "Amazon", "plaid polaire", "Idéal pour les soirées d'hiver."));
        home.add(new GiftSuggestion("Horloge murale design moderne", "20-45€", "Amazon", "horloge murale design", "Un élément déco tendance."));

        List<GiftSuggestion> experiences = new ArrayList<>();
        experiences.add(new GiftSuggestion("Box escape game à la maison", "20-35€", "Amazon", "box escape game", "Une soirée ludique."));
        experiences.add(new GiftSuggestion("Coffret Wonderbox aventure/détente", "30-100€", "Wonderbox", "coffret wonderbox", "Pour choisir son activité."));
        experiences.add(new GiftSuggestion("Cours de cuisine en ligne (MasterClass)", "15-30€", "MasterClass", "cours cuisine", "Pour apprendre des meilleurs."));
        experiences.add(new GiftSuggestion("Place de cinéma illimitée (1 mois)", "20-25€", "UGC/Pathé", "carte cinema", "Pour les cinéphiles."));
        experiences.add(new GiftSuggestion("Atelier poterie/céramique", "30-60€", "Wecandoo", "atelier poterie", "Une activité créative."));

        List<GiftSuggestion> personalized = new ArrayList<>();
        personalized.add(new GiftSuggestion("Album photo personnalisé", "25-50€", "Cheerz/Photobox", "album photo personnalise", "Un cadeau unique et touchant."));
        personalized.add(new GiftSuggestion("Mug personnalisé avec photo", "10-20€", "Amazon", "mug personnalise", "Pour penser à vous le matin."));
        personalized.add(new GiftSuggestion("Bijou gravé personnalisé", "15-40€", "Amazon", "bijou grave", "Un souvenir précieux."));
        personalized.add(new GiftSuggestion("Coussin personnalisé avec photo", "15-30€", "Amazon", "coussin personnalise", "Pour décorer avec une touche personnelle."));
        personalized.add(new GiftSuggestion("Puzzle personnalisé avec photo", "15-25€", "Amazon", "puzzle photo personnalise", "Ludique et personnel."));

        List<GiftSuggestion> gardening = new ArrayList<>();
        gardening.add(new GiftSuggestion("Kit jardinage d'intérieur (herbes aromatiques)", "15-30€", "Amazon", "kit jardinage interieur", "Pour cultiver ses propres herbes."));
        gardening.add(new GiftSuggestion("Hamac portable", "25-50€", "Amazon/Decathlon", "hamac portable", "Pour se relaxer dehors."));
        gardening.add(new GiftSuggestion("Lampe solaire de jardin", "15-30€", "Amazon", "lampe solaire jardin", "Pour éclairer son extérieur."));

        List<GiftSuggestion> eco = new ArrayList<>();
        eco.add(new GiftSuggestion("Kit zéro déchet (gourde + couverts + sac)", "20-35€", "Amazon", "kit zero dechet", "Un geste pour la planète."));
        eco.add(new GiftSuggestion("Lunch box inox compartimentée", "15-30€", "Amazon", "lunch box inox", "Pratique et durable."));
        eco.add(new GiftSuggestion("Livre sur le développement durable", "15-25€", "Fnac", "livre developpement durable", "Pour s'informer et agir."));

        List<GiftSuggestion> result = new ArrayList<>();
        String interestsStr = (interests != null) ? String.join(" ", interests).toLowerCase() : "";
        
        // 1. Interests
        if (interestsStr.contains("sport") || interestsStr.contains("fitness") || interestsStr.contains("foot") || interestsStr.contains("gym")) {
            Collections.shuffle(sports);
            result.addAll(sports.subList(0, Math.min(3, sports.size())));
        }
        if (interestsStr.contains("tech") || interestsStr.contains("geek") || interestsStr.contains("informatique") || interestsStr.contains("jeu") || interestsStr.contains("game")) {
            Collections.shuffle(tech);
            result.addAll(tech.subList(0, Math.min(3, tech.size())));
        }
        if (interestsStr.contains("livre") || interestsStr.contains("lecture") || interestsStr.contains("read")) {
            Collections.shuffle(books);
            result.addAll(books.subList(0, Math.min(3, books.size())));
        }
        if (interestsStr.contains("cuisine") || interestsStr.contains("cook") || interestsStr.contains("gastronomie")) {
            Collections.shuffle(cooking);
            result.addAll(cooking.subList(0, Math.min(3, cooking.size())));
        }
        if (interestsStr.contains("bien-être") || interestsStr.contains("soin") || interestsStr.contains("beaute") || interestsStr.contains("wellness")) {
            Collections.shuffle(wellness);
            result.addAll(wellness.subList(0, Math.min(3, wellness.size())));
        }
        if (interestsStr.contains("mode") || interestsStr.contains("fashion") || interestsStr.contains("vetement")) {
            Collections.shuffle(fashion);
            result.addAll(fashion.subList(0, Math.min(3, fashion.size())));
        }
        if (interestsStr.contains("maison") || interestsStr.contains("deco") || interestsStr.contains("home")) {
            Collections.shuffle(home);
            result.addAll(home.subList(0, Math.min(3, home.size())));
        }
        if (interestsStr.contains("experience") || interestsStr.contains("voyage") || interestsStr.contains("travel") || interestsStr.contains("sortie") || interestsStr.contains("cinema")) {
            Collections.shuffle(experiences);
            result.addAll(experiences.subList(0, Math.min(3, experiences.size())));
        }
        if (interestsStr.contains("jardin") || interestsStr.contains("nature") || interestsStr.contains("garden")) {
            Collections.shuffle(gardening);
            result.addAll(gardening.subList(0, Math.min(3, gardening.size())));
        }
        if (interestsStr.contains("eco") || interestsStr.contains("nature") || interestsStr.contains("bio")) {
            Collections.shuffle(eco);
            result.addAll(eco.subList(0, Math.min(3, eco.size())));
        }

        // 2. Age-appropriate
        if (age != null) {
            if (age < 18) {
                Collections.shuffle(experiences);
                result.addAll(experiences.subList(0, 1));
                Collections.shuffle(tech);
                result.addAll(tech.subList(0, 1));
            } else if (age >= 18 && age < 35) {
                Collections.shuffle(tech);
                result.addAll(tech.subList(0, 1));
                Collections.shuffle(fashion);
                result.addAll(fashion.subList(0, 1));
            } else {
                Collections.shuffle(cooking);
                result.addAll(cooking.subList(0, 1));
                Collections.shuffle(home);
                result.addAll(home.subList(0, 1));
            }
        }

        // 3. Category-appropriate (Relationship)
        String cat = category != null ? category.toLowerCase() : "";
        if (cat.contains("friend") || cat.contains("ami")) {
            Collections.shuffle(experiences);
            result.addAll(experiences.subList(0, 1));
            Collections.shuffle(personalized);
            result.addAll(personalized.subList(0, 1));
        } else if (cat.contains("family") || cat.contains("famille") || cat.contains("parent")) {
            Collections.shuffle(home);
            result.addAll(home.subList(0, 1));
            Collections.shuffle(cooking);
            result.addAll(cooking.subList(0, 1));
        } else if (cat.contains("partner") || cat.contains("amour") || cat.contains("conjoint")) {
            Collections.shuffle(personalized);
            result.addAll(personalized.subList(0, 2));
            Collections.shuffle(wellness);
            result.addAll(wellness.subList(0, 1));
        } else if (cat.contains("colleague") || cat.contains("collegue")) {
            Collections.shuffle(tech);
            result.addAll(tech.subList(0, 1)); // desk tech
            Collections.shuffle(books);
            result.addAll(books.subList(0, 1));
        }

        // 4. Fill up with general popular gifts
        List<GiftSuggestion> universal = new ArrayList<>();
        universal.addAll(books);
        universal.addAll(cooking);
        universal.addAll(home);
        universal.addAll(experiences);
        universal.addAll(wellness);
        universal.addAll(personalized);
        Collections.shuffle(universal);
        
        result.addAll(universal);
        
        // Remove duplicates and limit to 30
        List<GiftSuggestion> finalResult = result.stream()
            .distinct()
            .limit(30)
            .collect(java.util.stream.Collectors.toList());

        return finalResult;
    }
}
