package app.time2wish.repository;

import app.time2wish.model.Birthday;
import app.time2wish.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface BirthdayRepository extends JpaRepository<Birthday, Long> {
    List<Birthday> findByUserAndIsDeletedFalse(User user);
    Optional<Birthday> findByIdAndUserAndIsDeletedFalse(Long id, User user);

    /**
     * Find all active birthdays where today + reminder_days = upcoming anniversary (same month/day).
     * We compute the "days until next anniversary" and compare with reminder_days.
     * Uses PostgreSQL date arithmetic: next anniversary in current or next year.
     */
    @Query(value = """
        SELECT b.* FROM birthdays b
        WHERE b.is_deleted = false
        AND (
            CASE
                WHEN (MAKE_DATE(EXTRACT(YEAR FROM CURRENT_DATE)::int,
                               EXTRACT(MONTH FROM b.birthdate)::int,
                               EXTRACT(DAY FROM b.birthdate)::int) >= CURRENT_DATE)
                THEN MAKE_DATE(EXTRACT(YEAR FROM CURRENT_DATE)::int,
                              EXTRACT(MONTH FROM b.birthdate)::int,
                              EXTRACT(DAY FROM b.birthdate)::int)
                ELSE MAKE_DATE(EXTRACT(YEAR FROM CURRENT_DATE)::int + 1,
                              EXTRACT(MONTH FROM b.birthdate)::int,
                              EXTRACT(DAY FROM b.birthdate)::int)
            END
            - CURRENT_DATE
        ) = b.reminder_days
        """, nativeQuery = true)
    List<Birthday> findBirthdaysWithUpcomingReminders();
}

