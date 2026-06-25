package app.time2wish.service;

import app.time2wish.dto.GiftDto;
import app.time2wish.dto.ReserveGiftDto;
import app.time2wish.dto.SharedBirthdayDto;
import app.time2wish.model.Birthday;
import app.time2wish.model.Gift;
import app.time2wish.repository.BirthdayRepository;
import app.time2wish.repository.GiftRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SharedListService {

    private final BirthdayRepository birthdayRepository;
    private final GiftRepository giftRepository;
    private final GiftService giftService;

    public SharedBirthdayDto getSharedBirthday(String token) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        List<GiftDto> gifts = giftRepository.findByBirthdayId(birthday.getId()).stream()
                .map(giftService::mapToDto)
                .collect(Collectors.toList());

        return SharedBirthdayDto.builder()
                .id(birthday.getId())
                .name(birthday.getName())
                .birthdate(birthday.getBirthdate())
                .showAge(birthday.getShowAge())
                .gender(birthday.getGender())
                .gifts(gifts)
                .build();
    }

    public GiftDto reserveGift(String token, Long giftId, ReserveGiftDto dto) {
        Birthday birthday = birthdayRepository.findByShareTokenAndIsDeletedFalse(token)
                .orElseThrow(() -> new RuntimeException("Shared list not found or expired"));

        Gift gift = giftRepository.findById(giftId)
                .orElseThrow(() -> new RuntimeException("Gift not found"));

        if (!gift.getBirthday().getId().equals(birthday.getId())) {
            throw new RuntimeException("Gift does not belong to this shared list");
        }

        if (gift.getIsReserved()) {
            throw new RuntimeException("Gift is already reserved");
        }

        gift.setIsReserved(true);
        gift.setReservedByName(dto.getGuestName());
        gift = giftRepository.save(gift);

        return giftService.mapToDto(gift);
    }
}
