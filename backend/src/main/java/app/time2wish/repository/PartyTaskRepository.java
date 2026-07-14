package app.time2wish.repository;

import app.time2wish.model.Birthday;
import app.time2wish.model.PartyTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PartyTaskRepository extends JpaRepository<PartyTask, Long> {
    List<PartyTask> findByBirthday(Birthday birthday);
    void deleteByBirthday(Birthday birthday);
}
