package app.time2wish.scheduler;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Self-pinging keep-alive scheduler to prevent free cloud hosting providers
 * (e.g. Render) from spinning down the Spring Boot backend container after inactivity.
 *
 * Runs every 10 minutes (600,000 ms).
 */
@Slf4j
@Component
public class KeepAliveScheduler {

    @Value("${app.keep-alive.url:https://time2wish-backend.onrender.com/api/public/health}")
    private String keepAliveUrl;

    @Value("${app.keep-alive.enabled:true}")
    private boolean keepAliveEnabled;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    /**
     * Executes every 10 minutes (600000 ms).
     */
    @Scheduled(fixedRate = 600000, initialDelay = 60000)
    public void pingKeepAliveEndpoint() {
        if (!keepAliveEnabled || keepAliveUrl == null || keepAliveUrl.trim().isEmpty()) {
            return;
        }

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(keepAliveUrl))
                    .timeout(Duration.ofSeconds(15))
                    .header("User-Agent", "Time2Wish-KeepAlive-Scheduler/1.8.0")
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            log.info("[KeepAliveScheduler] 💓 Keep-Alive ping to {} returned HTTP {}", keepAliveUrl, response.statusCode());
        } catch (Exception e) {
            log.warn("[KeepAliveScheduler] ⚠️ Keep-Alive ping attempt failed: {}", e.getMessage());
        }
    }
}
