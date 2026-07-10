package app.time2wish.controller;

import app.time2wish.model.PromoCode;
import app.time2wish.repository.PromoCodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/promos")
public class PromoController {

    @Autowired
    private PromoCodeRepository promoCodeRepository;

    @GetMapping("/validate")
    public ResponseEntity<?> validatePromo(@RequestParam String code) {
        if (code == null || code.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Veuillez entrer un code."));
        }

        return promoCodeRepository.findByCode(code.toUpperCase()).map(promo -> {
            if (!promo.isActive()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Ce code n'est plus valide."));
            }
            if (promo.getExpiresAt() != null && promo.getExpiresAt().isBefore(LocalDateTime.now())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Ce code a expiré."));
            }
            if (promo.getMaxUses() != null && promo.getCurrentUses() >= promo.getMaxUses()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Ce code a atteint sa limite d'utilisation."));
            }
            
            return ResponseEntity.ok(Map.of(
                "code", promo.getCode(),
                "discountPercentage", promo.getDiscountPercentage()
            ));
        }).orElse(ResponseEntity.badRequest().body(Map.of("message", "Code introuvable.")));
    }
}
