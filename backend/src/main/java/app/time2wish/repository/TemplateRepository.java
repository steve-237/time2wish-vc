package app.time2wish.repository;

import app.time2wish.model.MessageTemplate;
import app.time2wish.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TemplateRepository extends JpaRepository<MessageTemplate, Long> {
    List<MessageTemplate> findByUser(User user);
}
