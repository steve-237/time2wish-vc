package app.time2wish.config;

import app.time2wish.repository.ConversationMemberRepository;
import app.time2wish.security.JwtUtils;
import app.time2wish.security.UserDetailsImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

@Component
public class WebSocketAuthInterceptor implements ChannelInterceptor {

    private static final Logger logger = LoggerFactory.getLogger(WebSocketAuthInterceptor.class);

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private ConversationMemberRepository conversationMemberRepository;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) {
            return message;
        }

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authorization = accessor.getFirstNativeHeader("Authorization");
            logger.debug("WebSocket CONNECT with Authorization: {}", authorization != null ? "Present" : "Missing");

            if (authorization != null && authorization.startsWith("Bearer ")) {
                String token = authorization.substring(7);
                if (jwtUtils.validateJwtToken(token)) {
                    String username = jwtUtils.getUserNameFromJwtToken(token);
                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    accessor.setUser(authentication);
                } else {
                    logger.warn("Invalid JWT Token in WebSocket Connect");
                }
            }
        } else if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            String destination = accessor.getDestination();
            if (destination != null && destination.startsWith("/topic/conversation/")) {
                try {
                    String idStr = destination.substring("/topic/conversation/".length());
                    Long conversationId = Long.valueOf(idStr);
                    Authentication auth = (Authentication) accessor.getUser();
                    if (auth == null || !(auth.getPrincipal() instanceof UserDetailsImpl userDetails)) {
                        logger.warn("Unauthenticated attempt to subscribe to {}", destination);
                        throw new IllegalArgumentException("Unauthorized WebSocket subscription");
                    }
                    if (conversationMemberRepository.findByConversationIdAndUserId(conversationId, userDetails.getId()).isEmpty()) {
                        logger.warn("User {} is not a member of conversation {}", userDetails.getId(), conversationId);
                        throw new IllegalArgumentException("Unauthorized subscription: not a member of this conversation");
                    }
                } catch (NumberFormatException e) {
                    logger.warn("Invalid conversation ID in destination: {}", destination);
                    throw new IllegalArgumentException("Invalid conversation destination");
                }
            }
        }
        return message;
    }
}
