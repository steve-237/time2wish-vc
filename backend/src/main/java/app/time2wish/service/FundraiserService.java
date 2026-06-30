package app.time2wish.service;

import app.time2wish.dto.FundraiserDto;
import app.time2wish.dto.PledgeDto;
import app.time2wish.dto.PledgeRequest;
import app.time2wish.model.Fundraiser;
import app.time2wish.model.Gift;
import app.time2wish.model.Pledge;
import app.time2wish.model.User;
import app.time2wish.repository.FundraiserRepository;
import app.time2wish.repository.GiftRepository;
import app.time2wish.repository.PledgeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class FundraiserService {

    @Autowired
    private FundraiserRepository fundraiserRepository;

    @Autowired
    private PledgeRepository pledgeRepository;

    @Autowired
    private GiftRepository giftRepository;

    public FundraiserDto getOrCreateFundraiser(Long giftId, BigDecimal targetAmount) {
        Fundraiser f = fundraiserRepository.findByGiftId(giftId).orElseGet(() -> {
            Gift gift = giftRepository.findById(giftId).orElseThrow(() -> new RuntimeException("Gift not found"));
            Fundraiser newF = Fundraiser.builder()
                    .gift(gift)
                    .targetAmount(targetAmount != null ? targetAmount : new BigDecimal("100.0"))
                    .build();
            return fundraiserRepository.save(newF);
        });
        return toDto(f);
    }

    public FundraiserDto addPledge(Long fundraiserId, User user, PledgeRequest req) {
        Fundraiser f = fundraiserRepository.findById(fundraiserId).orElseThrow();
        if (!f.getActive()) {
            throw new RuntimeException("Fundraiser is closed");
        }

        Pledge p = Pledge.builder()
                .fundraiser(f)
                .user(user)
                .guestName(req.getGuestName())
                .amount(req.getAmount())
                .message(req.getMessage())
                .build();
        pledgeRepository.save(p);
        return toDto(f);
    }

    private FundraiserDto toDto(Fundraiser f) {
        List<Pledge> pledges = pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(f.getId());
        BigDecimal current = pledges.stream().map(Pledge::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        
        List<PledgeDto> pledgeDtos = pledges.stream().map(p -> PledgeDto.builder()
                .id(p.getId())
                .contributorName(p.getUser() != null ? p.getUser().getFullName() : p.getGuestName())
                .amount(p.getAmount())
                .message(p.getMessage())
                .createdAt(p.getCreatedAt())
                .build()).collect(Collectors.toList());

        return FundraiserDto.builder()
                .id(f.getId())
                .giftId(f.getGift().getId())
                .targetAmount(f.getTargetAmount())
                .currentAmount(current)
                .currency(f.getCurrency())
                .active(f.getActive())
                .pledges(pledgeDtos)
                .build();
    }
}
