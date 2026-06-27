package app.time2wish.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

class ImageGenerationServiceTest {

    @InjectMocks
    private ImageGenerationService imageGenerationService;

    @Mock
    private RestTemplate restTemplate;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        // Inject the mocked RestTemplate into the service since it's instantiated directly
        ReflectionTestUtils.setField(imageGenerationService, "restTemplate", restTemplate);
    }

    @Test
    void testGenerateImage_Success() {
        byte[] mockImage = new byte[]{1, 2, 3};
        ResponseEntity<byte[]> responseEntity = new ResponseEntity<>(mockImage, HttpStatus.OK);
        when(restTemplate.getForEntity(anyString(), eq(byte[].class))).thenReturn(responseEntity);

        byte[] result = imageGenerationService.generateImage("A birthday cake");

        assertNotNull(result);
        assertArrayEquals(mockImage, result);
    }

    @Test
    void testGenerateImage_FallbackOnError() {
        when(restTemplate.getForEntity(anyString(), eq(byte[].class))).thenThrow(new RuntimeException("API error"));

        byte[] result = imageGenerationService.generateImage("A birthday cake");

        assertNull(result);
    }
}
