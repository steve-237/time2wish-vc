package app.time2wish.repository;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BirthdayRepository extends JpaRepository<Birthday, Long> {
    List<Birthday> findByUserAndIsDeletedFalse(User user);
    long countByUserAndIsDeletedFalse(User user);
    long countByIsDeletedFalse();
    List<Birthday> findByUser(User user);
    Optional<Birthday> findByIdAndUserAndIsDeletedFalse(Long id, User user);
    Optional<Birthday> findByShareTokenAndIsDeletedFalse(String shareToken);
    void deleteAllByUser(User user);

    /**
     * Find all active birthdays where today + reminder_days = upcoming anniversary (same month/day).
     * We compute the "days until next anniversary" and compare with reminder_days.
     * Uses PostgreSQL date arithmetic with year intervals to safely handle leap years (e.g. Feb 29).
     */
    @Query(value = 
        "SELECT b.* FROM birthdays b " +
        "WHERE b.is_deleted = false " +
        "AND ( " +
            "CASE " +
                "WHEN (b.birthdate + ((EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM b.birthdate)) || ' years')\\:\\:interval)\\:\\:date >= CURRENT_DATE " +
                "THEN (b.birthdate + ((EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM b.birthdate)) || ' years')\\:\\:interval)\\:\\:date " +
                "ELSE (b.birthdate + ((EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM b.birthdate) + 1) || ' years')\\:\\:interval)\\:\\:date " +
            "END " +
            "- CURRENT_DATE " +
        ") = b.reminder_days ", nativeQuery = true)
    List<Birthday> findBirthdaysWithUpcomingReminders();
}
