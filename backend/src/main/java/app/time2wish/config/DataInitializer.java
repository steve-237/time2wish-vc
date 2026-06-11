package app.time2wish.config;

import app.time2wish.model.PlanType;
import app.time2wish.model.Role;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataInitializer {

    @Bean
    public CommandLineRunner initData(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        return args -> {
            userRepository.findByEmail("superadmin@time2wish.com").ifPresentOrElse(user -> {
                user.setRole(Role.ROLE_SUPERADMIN);
                user.setPlan(PlanType.PRO);
                userRepository.save(user);
            }, () -> {
                User superAdmin = User.builder()
                        .email("superadmin@time2wish.com")
                        .password(passwordEncoder.encode("password123"))
                        .fullName("Super Administrateur")
                        .role(Role.ROLE_SUPERADMIN)
                        .status("ACTIVE")
                        .plan(PlanType.PRO)
                        .build();
                userRepository.save(superAdmin);
            });

            userRepository.findByEmail("demo-admin@time2wish.com").ifPresentOrElse(user -> {
                user.setRole(Role.ROLE_ADMIN);
                user.setPlan(PlanType.PRO);
                userRepository.save(user);
            }, () -> {
                User admin = User.builder()
                        .email("demo-admin@time2wish.com")
                        .password(passwordEncoder.encode("password123"))
                        .fullName("Admin Démo")
                        .role(Role.ROLE_ADMIN)
                        .status("ACTIVE")
                        .plan(PlanType.PRO)
                        .build();
                userRepository.save(admin);
            });
        };
    }
}
