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
        
        if (details.getPhotoUrl() != null && !details.getPhotoUrl().isEmpty()) {
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
