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
            BigDecimal initialTarget = targetAmount;
            if (initialTarget == null && gift.getPriceRange() != null) {
                initialTarget = parsePriceFromRange(gift.getPriceRange());
            }
            if (initialTarget == null || initialTarget.compareTo(BigDecimal.ZERO) <= 0) {
                initialTarget = new BigDecimal("100.0");
            }
            Fundraiser newF = Fundraiser.builder()
                    .gift(gift)
                    .targetAmount(initialTarget)
                    .build();
            return fundraiserRepository.save(newF);
        });

        // If targetAmount was explicitly specified and no pledges exist yet, sync it
        if (targetAmount != null && targetAmount.compareTo(BigDecimal.ZERO) > 0) {
            List<Pledge> pledges = pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(f.getId());
            if (pledges.isEmpty() && f.getTargetAmount().compareTo(targetAmount) != 0) {
                f.setTargetAmount(targetAmount);
                f = fundraiserRepository.save(f);
            }
        }

        return toDto(f);
    }

    public FundraiserDto addPledge(Long fundraiserId, User user, PledgeRequest req) {
        Fundraiser f = fundraiserRepository.findById(fundraiserId)
                .orElseThrow(() -> new RuntimeException("Cagnotte introuvable"));

        if (!Boolean.TRUE.equals(f.getActive())) {
            throw new RuntimeException("Cette cagnotte est clôturée.");
        }

        if (req.getAmount() == null || req.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("Le montant de la participation doit être supérieur à zéro.");
        }

        List<Pledge> pledges = pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(f.getId());
        BigDecimal current = pledges.stream().map(Pledge::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal remaining = f.getTargetAmount().subtract(current);

        if (remaining.compareTo(BigDecimal.ZERO) <= 0) {
            f.setActive(false);
            fundraiserRepository.save(f);
            throw new RuntimeException("L'objectif de cette cagnotte a déjà été atteint à 100%.");
        }

        if (req.getAmount().compareTo(remaining) > 0) {
            throw new RuntimeException("Le montant de votre participation (" + req.getAmount() + " " + f.getCurrency() 
                    + ") ne peut pas dépasser la somme restante à collecter (" + remaining + " " + f.getCurrency() + ").");
        }

        Pledge p = Pledge.builder()
                .fundraiser(f)
                .user(user)
                .guestName(req.getGuestName())
                .amount(req.getAmount())
                .message(req.getMessage())
                .build();
        pledgeRepository.save(p);

        // Check if target is now reached
        BigDecimal newTotal = current.add(req.getAmount());
        if (newTotal.compareTo(f.getTargetAmount()) >= 0) {
            f.setActive(false);
            fundraiserRepository.save(f);
        }

        return toDto(f);
    }

    public FundraiserDto updateTargetAmount(Long fundraiserId, BigDecimal newTarget) {
        if (newTarget == null || newTarget.compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("Le montant cible doit être supérieur à zéro.");
        }
        Fundraiser f = fundraiserRepository.findById(fundraiserId)
                .orElseThrow(() -> new RuntimeException("Cagnotte introuvable"));

        List<Pledge> pledges = pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(f.getId());
        BigDecimal current = pledges.stream().map(Pledge::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        if (newTarget.compareTo(current) < 0) {
            throw new RuntimeException("Le montant cible ne peut pas être inférieur aux promesses déjà enregistrées (" 
                    + current + " " + f.getCurrency() + ").");
        }

        f.setTargetAmount(newTarget);
        f.setActive(current.compareTo(newTarget) < 0);
        fundraiserRepository.save(f);

        return toDto(f);
    }

    private BigDecimal parsePriceFromRange(String priceRange) {
        if (priceRange == null || priceRange.isBlank()) return null;
        try {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("(\\d+(?:[.,]\\d+)?)").matcher(priceRange);
            BigDecimal maxVal = null;
            while (matcher.find()) {
                String numStr = matcher.group(1).replace(',', '.');
                BigDecimal val = new BigDecimal(numStr);
                if (maxVal == null || val.compareTo(maxVal) > 0) {
                    maxVal = val;
                }
            }
            return maxVal;
        } catch (Exception e) {
            return null;
        }
    }

    private FundraiserDto toDto(Fundraiser f) {
        List<Pledge> pledges = pledgeRepository.findByFundraiserIdOrderByCreatedAtDesc(f.getId());
        BigDecimal current = pledges.stream().map(Pledge::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal remaining = f.getTargetAmount().subtract(current);
        if (remaining.compareTo(BigDecimal.ZERO) < 0) {
            remaining = BigDecimal.ZERO;
        }
        boolean isCompleted = current.compareTo(f.getTargetAmount()) >= 0 || !Boolean.TRUE.equals(f.getActive());

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
                .remainingAmount(remaining)
                .isCompleted(isCompleted)
                .currency(f.getCurrency())
                .active(f.getActive())
                .pledges(pledgeDtos)
                .build();
    }
}
