package app.time2wish.service;

import app.time2wish.dto.GiftSuggestionResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

class IAServiceTest {

    @InjectMocks
    private IAService IAService;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private app.time2wish.service.SettingService settingService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        org.mockito.Mockito.lenient().when(settingService.getBooleanSetting(anyString())).thenReturn(true);
        // Inject the mocked RestTemplate into the service since it's instantiated directly
        ReflectionTestUtils.setField(IAService, "restTemplate", restTemplate);
    }

    @Test
    void testGenerateWish_Success() {
        String mockResponse = "Happy Birthday, test user!";
        when(restTemplate.getForObject(anyString(), eq(String.class))).thenReturn(mockResponse);

        String result = IAService.generateWish("Steve", 30, "Friend", "Likes coding", "funny", "en", null);

        assertNotNull(result);
        assertEquals(mockResponse, result);
    }

    @Test
    void testGenerateWish_FallbackOnError() {
        when(restTemplate.getForObject(anyString(), eq(String.class))).thenThrow(new RuntimeException("API error"));

        String result = IAService.generateWish("Steve", 30, "Friend", "Likes coding", "funny", "en", null);

        assertNotNull(result);
        assertTrue(result.contains("Happy birthday"));
        assertTrue(result.contains("Steve"));
    }

    @Test
    void testGenerateGiftSuggestions_Success() {
        String mockJsonResponse = "```json\n" +
                "[\n" +
                "  {\n" +
                "    \"name\": \"Mechanical Keyboard\",\n" +
                "    \"estimatedPrice\": \"$100\",\n" +
                "    \"whereToBuy\": \"Amazon\",\n" +
                "    \"purchaseLink\": \"https://amazon.com\",\n" +
                "    \"preparationTips\": \"Great for coders\"\n" +
                "  }\n" +
                "]\n" +
                "```";
        when(restTemplate.getForObject(anyString(), eq(String.class))).thenReturn(mockJsonResponse);

        GiftSuggestionResponse response = IAService.generateGiftSuggestions("Steve", 30, "Male", "Friend", List.of("coding"), "en");

        assertNotNull(response);
        assertEquals("AI", response.getSource());
        assertFalse(response.getSuggestions().isEmpty());
        assertEquals("Mechanical Keyboard", response.getSuggestions().get(0).getName());
    }

    @Test
    void testGenerateGiftSuggestions_FallbackOnError() {
        when(restTemplate.getForObject(anyString(), eq(String.class))).thenThrow(new RuntimeException("API error"));

        GiftSuggestionResponse response = IAService.generateGiftSuggestions("Steve", 30, "Male", "Friend", List.of("coding"), "en");

        assertNotNull(response);
        assertEquals("LOCAL", response.getSource());
        assertFalse(response.getSuggestions().isEmpty());
    }
}
