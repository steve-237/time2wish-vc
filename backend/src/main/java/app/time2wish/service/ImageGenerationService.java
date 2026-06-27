package app.time2wish.service;

import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class ImageGenerationService {

    private final RestTemplate restTemplate = new RestTemplate();

    public byte[] generateImage(String prompt) {
        try {
            String fullPrompt = "A beautiful birthday card, highly detailed, vibrant colors, " + prompt;
            String encodedPrompt = URLEncoder.encode(fullPrompt, StandardCharsets.UTF_8).replace("+", "%20");
            
            // Pollinations.ai API (Free, no account needed)
            String url = "https://image.pollinations.ai/prompt/" + encodedPrompt + "?width=800&height=1200&nologo=true";

            ResponseEntity<byte[]> response = restTemplate.getForEntity(url, byte[].class);
            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return response.getBody();
            }
        } catch (Exception e) {
            System.err.println("Error calling Pollinations AI: " + e.getMessage());
        }

        return generateLocalFallback(prompt);
    }

    private byte[] generateLocalFallback(String prompt) {
        // Return null or empty array to indicate fallback is needed by the frontend
        return null;
    }
}
