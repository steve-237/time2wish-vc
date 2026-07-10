package app.time2wish.controller;

import app.time2wish.model.Gift;
import app.time2wish.repository.GiftRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/gifts")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
public class AdminGiftController {

    @Autowired
    private GiftRepository giftRepository;

    @GetMapping
    public ResponseEntity<List<Gift>> getAllGifts() {
        // Fetch all gifts sorted by ID descending to see newest first
        return ResponseEntity.ok(giftRepository.findAll(org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "id")));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteGift(@PathVariable Long id) {
        return giftRepository.findById(id).map(gift -> {
            giftRepository.delete(gift);
            return ResponseEntity.ok().build();
        }).orElse(ResponseEntity.notFound().build());
    }
}
