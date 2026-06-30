package app.time2wish.controller;

import app.time2wish.dto.FundraiserDto;
import app.time2wish.dto.PledgeRequest;
import app.time2wish.model.User;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.FundraiserService;
import app.time2wish.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.math.BigDecimal;

@RestController
@RequestMapping("/api/fundraisers")
public class FundingController {

    @Autowired
    private FundraiserService fundraiserService;

    @Autowired
    private UserRepository userRepository;

    // Get or Create Fundraiser for a Gift
    @GetMapping("/gift/{giftId}")
    public ResponseEntity<FundraiserDto> getFundraiser(
            @PathVariable Long giftId,
            @RequestParam(required = false) BigDecimal target) {
        return ResponseEntity.ok(fundraiserService.getOrCreateFundraiser(giftId, target));
    }

    // Add a Pledge
    @PostMapping("/{fundraiserId}/pledges")
    public ResponseEntity<FundraiserDto> addPledge(
            @PathVariable Long fundraiserId,
            @Valid @RequestBody PledgeRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        
        User user = null;
        if (userDetails != null) {
            user = userRepository.findById(userDetails.getId()).orElse(null);
        }

        FundraiserDto updated = fundraiserService.addPledge(fundraiserId, user, request);
        return ResponseEntity.ok(updated);
    }
}
