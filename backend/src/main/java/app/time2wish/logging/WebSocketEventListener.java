package app.time2wish.logging;

import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.util.concurrent.atomic.AtomicInteger;

@Component
public class WebSocketEventListener {

    private final SimpMessagingTemplate messagingTemplate;
    private final AtomicInteger activeUsers = new AtomicInteger(0);

    public WebSocketEventListener(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @EventListener
    public void handleWebSocketConnectListener(SessionConnectedEvent event) {
        int count = activeUsers.incrementAndGet();
        broadcastActiveUsers(count);
    }

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        int count = activeUsers.decrementAndGet();
        if (count < 0) {
            count = 0;
            activeUsers.set(0);
        }
        broadcastActiveUsers(count);
    }

    private void broadcastActiveUsers(int count) {
        messagingTemplate.convertAndSend("/topic/admin.stats", new StatsMessage(count));
    }

    public int getActiveUsers() {
        return activeUsers.get();
    }

    public static class StatsMessage {
        public int activeUsers;

        public StatsMessage(int activeUsers) {
            this.activeUsers = activeUsers;
        }
    }
}
