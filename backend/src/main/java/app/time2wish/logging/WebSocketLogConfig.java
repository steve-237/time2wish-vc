package app.time2wish.logging;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import jakarta.annotation.PostConstruct;

@Configuration
public class WebSocketLogConfig {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @PostConstruct
    public void init() {
        LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();
        Logger rootLogger = loggerContext.getLogger(Logger.ROOT_LOGGER_NAME);

        WebSocketLogAppender appender = new WebSocketLogAppender(messagingTemplate);
        appender.setContext(loggerContext);
        appender.start();

        rootLogger.addAppender(appender);
    }
}
