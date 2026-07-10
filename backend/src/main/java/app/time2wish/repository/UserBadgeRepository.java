package app.time2wish.repository;

import app.time2wish.model.User;
import app.time2wish.model.UserBadge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserBadgeRepository extends JpaRepository<UserBadge, Long> {
    List<UserBadge> findByUser(User user);
    void deleteByUserAndBadgeName(User user, String badgeName);
}
