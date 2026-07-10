package app.time2wish.controller;

import app.time2wish.model.PromoCode;
import app.time2wish.repository.PromoCodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;

@RestController
@RequestMapping("/api/admin/promos")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
public class AdminPromoController {

    @Autowired
    private PromoCodeRepository promoCodeRepository;

    @GetMapping
    public ResponseEntity<List<PromoCode>> getAllPromos() {
        return ResponseEntity.ok(promoCodeRepository.findAll(org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "createdAt")));
    }

    @PostMapping
    public ResponseEntity<?> createPromo(@Valid @RequestBody PromoCode promoCode) {
        if (promoCodeRepository.findByCode(promoCode.getCode()).isPresent()) {
            return ResponseEntity.badRequest().body("Error: Promo code already exists!");
        }
        
        // uppercase the code
        promoCode.setCode(promoCode.getCode().toUpperCase());
        promoCode.setActive(true);
        promoCode.setCurrentUses(0);
        
        return ResponseEntity.ok(promoCodeRepository.save(promoCode));
    }

    @PutMapping("/{id}/toggle")
    public ResponseEntity<?> togglePromoStatus(@PathVariable Long id) {
        return promoCodeRepository.findById(id).map(promo -> {
            promo.setActive(!promo.isActive());
            return ResponseEntity.ok(promoCodeRepository.save(promo));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePromo(@PathVariable Long id) {
        return promoCodeRepository.findById(id).map(promo -> {
            promoCodeRepository.delete(promo);
            return ResponseEntity.ok().build();
        }).orElse(ResponseEntity.notFound().build());
    }
}
