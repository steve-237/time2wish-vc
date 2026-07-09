package app.time2wish.security;

import app.time2wish.service.SettingService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class MaintenanceFilter extends OncePerRequestFilter {

    @Autowired
    private SettingService settingService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String path = request.getRequestURI();

        // Check if maintenance mode is active
        boolean isMaintenance = settingService.getBooleanSetting(SettingService.MAINTENANCE_MODE);

        if (isMaintenance) {
            // Always allow auth login and refresh so admins can log in
            if (path.startsWith("/api/auth/login") || path.startsWith("/api/auth/refresh")) {
                filterChain.doFilter(request, response);
                return;
            }

            // Check if user is authenticated and has ADMIN role
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            boolean isAdmin = false;
            
            if (auth != null && auth.isAuthenticated()) {
                isAdmin = auth.getAuthorities().stream()
                        .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
            }

            if (!isAdmin) {
                // Block the request
                response.setStatus(HttpStatus.SERVICE_UNAVAILABLE.value());
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write("{\"error\": \"Le site est actuellement en maintenance. Veuillez réessayer plus tard.\"}");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}
