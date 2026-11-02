package app.time2wish.controller;

import app.time2wish.dto.AstrologyInsightDto;
import app.time2wish.dto.ZodiacCompatibilityDto;
import app.time2wish.service.AstrologyService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/astrology")
@RequiredArgsConstructor
public class AstrologyController {

    private final AstrologyService astrologyService;

    @GetMapping("/insights")
    public ResponseEntity<AstrologyInsightDto> getInsights(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate birthdate,
            @RequestParam(required = false, defaultValue = "fr") String lang) {
        if (birthdate == null) {
            birthdate = LocalDate.now();
        }
        return ResponseEntity.ok(astrologyService.getInsights(birthdate, lang));
    }

    @GetMapping("/birthday/{id}")
    public ResponseEntity<AstrologyInsightDto> getInsightsForBirthday(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "fr") String lang) {
        return ResponseEntity.ok(astrologyService.getInsightsForBirthday(id, lang));
    }

    @GetMapping("/compatibility")
    public ResponseEntity<ZodiacCompatibilityDto> getCompatibility(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date1,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date2,
            @RequestParam(required = false, defaultValue = "fr") String lang) {
        return ResponseEntity.ok(astrologyService.calculateCompatibility(date1, date2, lang));
    }
}
