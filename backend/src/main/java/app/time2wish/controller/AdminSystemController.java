package app.time2wish.controller;

import app.time2wish.logging.WebSocketEventListener;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;

import java.lang.management.ManagementFactory;
import java.lang.management.OperatingSystemMXBean;
import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import java.util.List;

@RestController
@RequestMapping("/api/admin/system")
@PreAuthorize("hasRole('SUPERADMIN')")
public class AdminSystemController {

    @Autowired
    private WebSocketEventListener webSocketEventListener;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @GetMapping("/metrics")
    public ResponseEntity<Map<String, Object>> getSystemMetrics() {
        Map<String, Object> metrics = new HashMap<>();

        metrics.put("activeUsers", webSocketEventListener.getActiveUsers());

        // Memory Metrics
        Runtime runtime = Runtime.getRuntime();
        long maxMemory = runtime.maxMemory();
        long allocatedMemory = runtime.totalMemory();
        long freeMemory = runtime.freeMemory();
        long usedMemory = allocatedMemory - freeMemory;
        
        metrics.put("memoryMax", maxMemory);
        metrics.put("memoryAllocated", allocatedMemory);
        metrics.put("memoryFree", freeMemory);
        metrics.put("memoryUsed", usedMemory);

        // CPU Metrics (approximate for the JVM)
        OperatingSystemMXBean osBean = ManagementFactory.getOperatingSystemMXBean();
        metrics.put("cpuLoad", osBean.getSystemLoadAverage());
        metrics.put("availableProcessors", osBean.getAvailableProcessors());

        return ResponseEntity.ok(metrics);
    }

    @GetMapping("/logs")
    public ResponseEntity<List<app.time2wish.logging.WebSocketLogAppender.LogMessage>> getInitialLogs() {
        return ResponseEntity.ok(app.time2wish.logging.WebSocketLogAppender.getCachedLogs());
    }

    @GetMapping("/backup")
    public ResponseEntity<byte[]> downloadBackup() {
        try {
            Map<String, Object> backupData = new HashMap<>();
            
            // Get all public tables
            List<String> tables = jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'", String.class);
            
            for (String table : tables) {
                List<Map<String, Object>> rows = jdbcTemplate.queryForList("SELECT * FROM " + table);
                backupData.put(table, rows);
            }

            ObjectMapper mapper = objectMapper.copy().enable(SerializationFeature.INDENT_OUTPUT);
            byte[] jsonData = mapper.writeValueAsBytes(backupData);

            String filename = "time2wish_backup_" + System.currentTimeMillis() + ".json";

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                    .contentType(MediaType.APPLICATION_JSON)
                    .contentLength(jsonData.length)
                    .body(jsonData);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
