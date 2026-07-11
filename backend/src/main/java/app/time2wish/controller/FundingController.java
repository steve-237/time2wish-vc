package app.time2wish.controller;

import app.time2wish.dto.FundraiserDto;
import app.time2wish.dto.PledgeRequest;
import app.time2wish.model.User;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.FundraiserService;
import app.time2wish.service.SettingService;
import app.time2wish.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import jakarta.validation.Valid;
import java.math.BigDecimal;

@RestController
@RequestMapping("/api/fundraisers")
public class FundingController {

    @Autowired
    private FundraiserService fundraiserService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SettingService settingService;

    private void checkModuleEnabled() {
        if (!settingService.getBooleanSetting(SettingService.MODULE_CAGNOTTE_ENABLED)) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Fundraiser module is disabled.");
        }
    }

    // Get or Create Fundraiser for a Gift
    @GetMapping("/gift/{giftId}")
    public ResponseEntity<FundraiserDto> getFundraiser(
            @PathVariable Long giftId,
            @RequestParam(required = false) BigDecimal target) {
        checkModuleEnabled();
        return ResponseEntity.ok(fundraiserService.getOrCreateFundraiser(giftId, target));
    }

    // Add a Pledge
    @PostMapping("/{fundraiserId}/pledges")
    public ResponseEntity<FundraiserDto> addPledge(
            @PathVariable Long fundraiserId,
            @Valid @RequestBody PledgeRequest request,
            @AuthenticationPrincipal UserDetailsImpl userDetails) {
        
        checkModuleEnabled();
        
        User user = null;
        if (userDetails != null) {
            user = userRepository.findById(userDetails.getId()).orElse(null);
        }

        FundraiserDto updated = fundraiserService.addPledge(fundraiserId, user, request);
        return ResponseEntity.ok(updated);
    }
}
