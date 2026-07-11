package app.time2wish.logging;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.AppenderBase;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;

public class WebSocketLogAppender extends AppenderBase<ILoggingEvent> {

    private final SimpMessagingTemplate messagingTemplate;
    private static final int MAX_LOGS = 200;
    public static final ConcurrentLinkedQueue<LogMessage> logCache = new ConcurrentLinkedQueue<>();
    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm:ss.SSS").withZone(ZoneId.systemDefault());

    public WebSocketLogAppender(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    protected void append(ILoggingEvent eventObject) {
        if (eventObject == null) return;

        String timestamp = formatter.format(Instant.ofEpochMilli(eventObject.getTimeStamp()));
        String level = eventObject.getLevel().toString();
        String logger = eventObject.getLoggerName();
        // Shorten logger name (e.g. app.time2wish... -> a.t...)
        String[] parts = logger.split("\\.");
        String shortLogger = parts[parts.length - 1];
        if (parts.length > 2) {
             shortLogger = parts[parts.length - 2] + "." + shortLogger;
        }

        String thread = eventObject.getThreadName();
        String message = eventObject.getFormattedMessage();

        LogMessage logMessage = new LogMessage(timestamp, level, shortLogger, thread, message);

        // Add to cache
        logCache.add(logMessage);
        while (logCache.size() > MAX_LOGS) {
            logCache.poll();
        }

        // Broadcast to websocket
        if (messagingTemplate != null) {
            try {
                messagingTemplate.convertAndSend("/topic/admin.logs", logMessage);
            } catch (Exception e) {
                // Ignore to prevent loop
            }
        }
    }

    public static List<LogMessage> getCachedLogs() {
        return new LinkedList<>(logCache);
    }

    public static class LogMessage {
        public String timestamp;
        public String level;
        public String logger;
        public String thread;
        public String message;

        public LogMessage(String timestamp, String level, String logger, String thread, String message) {
            this.timestamp = timestamp;
            this.level = level;
            this.logger = logger;
            this.thread = thread;
            this.message = message;
        }
    }
}
