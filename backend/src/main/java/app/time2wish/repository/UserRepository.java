package app.time2wish.repository;

import app.time2wish.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Boolean existsByEmail(String email);
    java.util.List<User> findByRole(app.time2wish.model.Role role);
    java.util.List<User> findByRoleNot(app.time2wish.model.Role role);
}
