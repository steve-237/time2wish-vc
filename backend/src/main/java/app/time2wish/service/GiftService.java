package app.time2wish.service;

import app.time2wish.dto.GiftCreateDto;
import app.time2wish.dto.GiftDto;
import app.time2wish.model.Birthday;
import app.time2wish.model.Gift;
import app.time2wish.model.User;
import app.time2wish.model.GiftVote;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.repository.GiftRepository;
import app.time2wish.repository.GiftVoteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GiftService {

    private final GiftRepository giftRepository;
    private final BirthdayRepository birthdayRepository;
    private final GiftVoteRepository giftVoteRepository;

    public List<GiftDto> getGiftsForBirthday(Long birthdayId, User user) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(birthdayId, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));
        return giftRepository.findByBirthdayId(birthday.getId()).stream()
                .map(g -> mapToDto(g, null))
                .collect(Collectors.toList());
    }

    public GiftDto addGift(Long birthdayId, User user, GiftCreateDto dto) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(birthdayId, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        Gift gift = Gift.builder()
                .birthday(birthday)
                .name(dto.getName())
                .description(dto.getDescription())
                .priceRange(dto.getPriceRange())
                .url(dto.getUrl())
                .imageUrl(dto.getImageUrl())
                .isReserved(false)
                .build();

        gift = giftRepository.save(gift);
        return mapToDto(gift, null);
    }

    public void removeGift(Long birthdayId, Long giftId, User user) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(birthdayId, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        Gift gift = giftRepository.findById(giftId)
                .orElseThrow(() -> new RuntimeException("Gift not found"));

        if (!gift.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Gift does not belong to this birthday");
        }

        giftRepository.delete(gift);
    }

    public GiftDto updateGift(Long birthdayId, Long giftId, User user, GiftCreateDto dto) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(birthdayId, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        Gift gift = giftRepository.findById(giftId)
                .orElseThrow(() -> new RuntimeException("Gift not found"));

        if (!gift.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Gift does not belong to this birthday");
        }

        gift.setName(dto.getName());
        gift.setDescription(dto.getDescription());
        gift.setPriceRange(dto.getPriceRange());
        gift.setUrl(dto.getUrl());
        gift.setImageUrl(dto.getImageUrl());

        gift = giftRepository.save(gift);
        return mapToDto(gift, null);
    }

    public String generateShareToken(Long birthdayId, User user) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(birthdayId, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found"));

        if (birthday.getShareToken() == null) {
            birthday.setShareToken(UUID.randomUUID().toString());
            birthdayRepository.save(birthday);
        }

        return birthday.getShareToken();
    }

    public GiftDto mapToDto(Gift gift, String voterSessionId) {
        List<GiftVote> votes = giftVoteRepository.findByGift(gift);
        int up = (int) votes.stream().filter(v -> v.getVoteType() == GiftVote.VoteType.UP).count();
        int down = (int) votes.stream().filter(v -> v.getVoteType() == GiftVote.VoteType.DOWN).count();
        String userVote = null;
        if (voterSessionId != null) {
            userVote = votes.stream()
                .filter(v -> voterSessionId.equals(v.getVoterSessionId()))
                .map(v -> v.getVoteType().name())
                .findFirst().orElse(null);
        }

        return GiftDto.builder()
                .id(gift.getId())
                .birthdayId(gift.getBirthday().getId())
                .name(gift.getName())
                .description(gift.getDescription())
                .priceRange(gift.getPriceRange())
                .url(gift.getUrl())
                .imageUrl(gift.getImageUrl())
                .isReserved(gift.getIsReserved())
                .reservedByName(gift.getReservedByName())
                .createdAt(gift.getCreatedAt())
                .upvotes(up)
                .downvotes(down)
                .userVote(userVote)
                .build();
    }
}
