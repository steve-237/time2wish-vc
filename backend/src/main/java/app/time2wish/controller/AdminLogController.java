package app.time2wish.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/logs")
@PreAuthorize("hasRole('ADMIN') or hasRole('SUPERADMIN')")
public class AdminLogController {

    private static final String LOG_FILE_PATH = "scratch/logs/time2wish.log";
    private static final int MAX_LINES = 500;

    @GetMapping
    public ResponseEntity<?> getLogs() {
        try {
            Path path = Paths.get(LOG_FILE_PATH);
            if (!Files.exists(path)) {
                return ResponseEntity.ok(Collections.singletonList("Log file not found or empty."));
            }

            List<String> allLines = Files.readAllLines(path);
            int start = Math.max(0, allLines.size() - MAX_LINES);
            List<String> lastLines = allLines.subList(start, allLines.size());

            return ResponseEntity.ok(lastLines);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Collections.singletonList("Error reading logs: " + e.getMessage()));
        }
    }
    
    @DeleteMapping
    public ResponseEntity<?> clearLogs() {
        try {
            Path path = Paths.get(LOG_FILE_PATH);
            if (Files.exists(path)) {
                Files.write(path, new byte[0], java.nio.file.StandardOpenOption.TRUNCATE_EXISTING);
            }
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error clearing logs: " + e.getMessage());
        }
    }
}
