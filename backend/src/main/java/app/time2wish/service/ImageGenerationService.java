package app.time2wish.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
public class ImageGenerationService {

    @Value("${app.huggingface.api-key:}")
    private String apiKey;

    @Value("${app.huggingface.model:stabilityai/stable-diffusion-xl-base-1.0}")
    private String modelId;

    private final RestTemplate restTemplate = new RestTemplate();

    public byte[] generateImage(String prompt) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            return generateLocalFallback(prompt);
        }

        String url = "https://api-inference.huggingface.co/models/" + modelId;

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        Map<String, Object> body = new HashMap<>();
        body.put("inputs", "A beautiful birthday card, highly detailed, vibrant colors, " + prompt);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<byte[]> response = restTemplate.postForEntity(url, request, byte[].class);
            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return response.getBody();
            }
        } catch (Exception e) {
            System.err.println("Error calling Hugging Face API: " + e.getMessage());
        }

        return generateLocalFallback(prompt);
    }

    private byte[] generateLocalFallback(String prompt) {
        // Return null or empty array to indicate fallback is needed by the frontend
        return null;
    }
}
