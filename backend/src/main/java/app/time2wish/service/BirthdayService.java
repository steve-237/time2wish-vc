package app.time2wish.service;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import app.time2wish.repository.BirthdayRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

@Service
public class BirthdayService {

    @Autowired
    private BirthdayRepository birthdayRepository;

    public List<Birthday> getActiveBirthdays(User user) {
        return birthdayRepository.findByUserAndIsDeletedFalse(user);
    }

    public Optional<Birthday> getBirthday(Long id, User user) {
        return birthdayRepository.findByIdAndUserAndIsDeletedFalse(id, user);
    }

    @Transactional
    public Birthday addBirthday(Birthday birthday, User user) {
        long currentCount = birthdayRepository.findByUserAndIsDeletedFalse(user).size();
        
        if (user.getPlan() == app.time2wish.model.PlanType.BASIC && currentCount >= 3) {
            throw new RuntimeException("LIMIT_REACHED: Vous avez atteint la limite de votre forfait BASIC (3 anniversaires). Veuillez passer au forfait supérieur.");
        }
        if (user.getPlan() == app.time2wish.model.PlanType.PLUS && currentCount >= 50) {
            throw new RuntimeException("LIMIT_REACHED: Vous avez atteint la limite de votre forfait PLUS (50 anniversaires). Veuillez passer au forfait supérieur.");
        }

        birthday.setUser(user);
        birthday.setIsDeleted(false);
        return birthdayRepository.save(birthday);
    }

    @Transactional
    public Birthday updateBirthday(Long id, Birthday details, User user) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(id, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found or unauthorized: " + id));

        birthday.setName(details.getName());
        birthday.setBirthdate(details.getBirthdate());
        birthday.setCategory(details.getCategory());
        birthday.setNotes(details.getNotes());
        birthday.setReminderDays(details.getReminderDays());
        birthday.setShowAge(details.getShowAge());
        birthday.setEmail(details.getEmail());
        birthday.setWhatsapp(details.getWhatsapp());
        birthday.setGender(details.getGender());
        birthday.setInterests(details.getInterests() == null ? new java.util.ArrayList<>() : details.getInterests());
        if (details.getIsFavorite() != null) {
            birthday.setIsFavorite(details.getIsFavorite());
        }

        if (details.getPhotoUrl() == null || details.getPhotoUrl().isEmpty()) {
            String defaultPhoto = "https://ui-avatars.com/api/?name=" + java.net.URLEncoder.encode(details.getName(), java.nio.charset.StandardCharsets.UTF_8) + "&background=" + String.format("%06x", new java.util.Random().nextInt(0xffffff + 1)) + "&color=fff&rounded=true&bold=true";
            birthday.setPhotoUrl(defaultPhoto);
        } else {
            birthday.setPhotoUrl(details.getPhotoUrl());
        }

        return birthdayRepository.save(birthday);
    }

    @Transactional
    public void deleteBirthday(Long id, User user) {
        Birthday birthday = birthdayRepository.findByIdAndUserAndIsDeletedFalse(id, user)
                .orElseThrow(() -> new RuntimeException("Birthday not found or unauthorized: " + id));
        
        birthday.setIsDeleted(true);
        birthdayRepository.save(birthday);
    }
}
