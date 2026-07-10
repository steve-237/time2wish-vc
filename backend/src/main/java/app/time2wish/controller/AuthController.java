package app.time2wish.controller;

import app.time2wish.dto.JwtResponse;
import app.time2wish.dto.LoginRequest;
import app.time2wish.dto.MessageResponse;
import app.time2wish.dto.SignupRequest;
import app.time2wish.dto.ProfileUpdateRequest;
import app.time2wish.dto.PasswordUpdateRequest;
import app.time2wish.model.RefreshToken;
import app.time2wish.model.User;
import app.time2wish.repository.UserRepository;
import app.time2wish.security.JwtUtils;
import app.time2wish.security.UserDetailsImpl;
import app.time2wish.service.RefreshTokenService;
import app.time2wish.payload.request.GoogleLoginRequest;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder encoder;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private RefreshTokenService refreshTokenService;
    
    @Autowired
    private app.time2wish.service.SettingService settingService;

    @Autowired
    private app.time2wish.repository.UserBadgeRepository userBadgeRepository;

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest, HttpServletResponse response) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

        String jwt = jwtUtils.generateJwtToken(userDetails.getUsername());
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(userDetails.getId());

        // Save refresh token in HTTP-only cookie
        ResponseCookie cookie = ResponseCookie.from("t2w_refresh", refreshToken.getToken().toString())
                .httpOnly(true)
                .secure(false) // Set to true in prod, false in dev localhost
                .path("/")
                .maxAge(30 * 24 * 60 * 60) // 30 days
                .sameSite("Lax")
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());

        User user = userRepository.findById(userDetails.getId()).orElseThrow();

        return ResponseEntity.ok(JwtResponse.builder()
                .token(jwt)
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .roles(java.util.Collections.singletonList(user.getRole().name()))
                .plan(user.getPlan().name())
                .lastAiWishGeneration(user.getLastAiWishGeneration())
                .lastAiGiftGeneration(user.getLastAiGiftGeneration())
                .badges(userBadgeRepository.findByUser(user).stream().map(app.time2wish.model.UserBadge::getBadgeName).collect(java.util.stream.Collectors.toList()))
                .build());
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody SignupRequest signUpRequest) {
        if (!settingService.getBooleanSetting(app.time2wish.service.SettingService.ALLOW_REGISTRATION)) {
            return ResponseEntity
                    .status(HttpStatus.FORBIDDEN)
                    .body(new MessageResponse("Error: Les inscriptions sont actuellement fermées."));
        }

        if (userRepository.existsByEmail(signUpRequest.getEmail())) {
            return ResponseEntity
                    .badRequest()
                    .body(new MessageResponse("Error: Email is already in use!"));
        }

        // Create new user's account
        String randomHex = String.format("%06x", new java.util.Random().nextInt(0xffffff + 1));
        User user = User.builder()
                .email(signUpRequest.getEmail())
                .password(encoder.encode(signUpRequest.getPassword()))
                .fullName(signUpRequest.getFullName())
                .avatarUrl("https://ui-avatars.com/api/?name=" + java.net.URLEncoder.encode(signUpRequest.getFullName(), java.nio.charset.StandardCharsets.UTF_8) + "&background=" + randomHex + "&color=fff&rounded=true&bold=true")
                .status("ACTIVE")
                .role(app.time2wish.model.Role.ROLE_USER)
                .build();

        userRepository.save(user);

        return ResponseEntity.ok(new MessageResponse("User registered successfully!"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@CookieValue(name = "t2w_refresh", required = false) String requestRefreshToken) {
        System.out.println("======> /api/auth/refresh CALLED <======");
        System.out.println("t2w_refresh Cookie Value: " + requestRefreshToken);

        if (requestRefreshToken == null || requestRefreshToken.isEmpty()) {
            System.out.println("Refresh token missing, returning 400");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new MessageResponse("Refresh Token is missing"));
        }

        try {
            UUID tokenUuid = UUID.fromString(requestRefreshToken);
            Optional<RefreshToken> tokenOpt = refreshTokenService.findByToken(tokenUuid);
            if (tokenOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new MessageResponse("Refresh token is not in database"));
            }

            RefreshToken refreshToken = refreshTokenService.verifyExpiration(tokenOpt.get());
            User user = refreshToken.getUser();
            String token = jwtUtils.generateJwtToken(user.getEmail());

            return ResponseEntity.ok(JwtResponse.builder()
                    .token(token)
                    .id(user.getId())
                    .email(user.getEmail())
                    .fullName(user.getFullName())
                    .bio(user.getBio())
                    .avatarUrl(user.getAvatarUrl())
                    .roles(java.util.Collections.singletonList(user.getRole().name()))
                    .plan(user.getPlan().name())
                    .lastAiWishGeneration(user.getLastAiWishGeneration())
                    .lastAiGiftGeneration(user.getLastAiGiftGeneration())
                    .badges(userBadgeRepository.findByUser(user).stream().map(app.time2wish.model.UserBadge::getBadgeName).collect(java.util.stream.Collectors.toList()))
                    .build());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new MessageResponse("Invalid token format"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new MessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logoutUser(HttpServletResponse response) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl userDetails) {
            refreshTokenService.deleteByUserId(userDetails.getId());
        }

        // Delete refresh token cookie
        ResponseCookie cookie = ResponseCookie.from("t2w_refresh", "")
                .httpOnly(true)
                .path("/")
                .maxAge(0) // delete immediately
                .sameSite("Lax")
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());

        return ResponseEntity.ok(new MessageResponse("Log out successful!"));
    }

    @Value("${app.google.client-id:}")
    private String googleClientId;

    @PostMapping("/google")
    public ResponseEntity<?> authenticateGoogle(@Valid @RequestBody GoogleLoginRequest request, HttpServletResponse response) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), GsonFactory.getDefaultInstance())
                    .setAudience(java.util.Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken idToken = verifier.verify(request.getIdToken());
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                String email = payload.getEmail();
                String name = (String) payload.get("name");
                String pictureUrl = (String) payload.get("picture");

                Optional<User> userOpt = userRepository.findByEmail(email);
                User user;
                if (userOpt.isPresent()) {
                    user = userOpt.get();
                } else {
                    if (!settingService.getBooleanSetting(app.time2wish.service.SettingService.ALLOW_REGISTRATION)) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(new MessageResponse("Error: Les inscriptions sont actuellement fermées."));
                    }
                    user = User.builder()
                            .email(email)
                            .password(encoder.encode(UUID.randomUUID().toString()))
                            .fullName(name)
                            .avatarUrl(pictureUrl)
                            .role(app.time2wish.model.Role.ROLE_USER)
                            .plan(app.time2wish.model.PlanType.BASIC)
                            .status("ACTIVE")
                            .build();
                    user = userRepository.save(user);
                }

                String jwt = jwtUtils.generateJwtToken(user.getEmail());
                RefreshToken refreshToken = refreshTokenService.createRefreshToken(user.getId());

                ResponseCookie cookie = ResponseCookie.from("t2w_refresh", refreshToken.getToken().toString())
                        .httpOnly(true)
                        .secure(false)
                        .path("/")
                        .maxAge(30 * 24 * 60 * 60)
                        .sameSite("Lax")
                        .build();
                response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());

                return ResponseEntity.ok(JwtResponse.builder()
                        .token(jwt)
                        .id(user.getId())
                        .email(user.getEmail())
                        .fullName(user.getFullName())
                        .bio(user.getBio())
                        .avatarUrl(user.getAvatarUrl())
                        .roles(java.util.Collections.singletonList(user.getRole().name()))
                        .plan(user.getPlan().name())
                        .lastAiWishGeneration(user.getLastAiWishGeneration())
                        .lastAiGiftGeneration(user.getLastAiGiftGeneration())
                        .badges(userBadgeRepository.findByUser(user).stream().map(app.time2wish.model.UserBadge::getBadgeName).collect(java.util.stream.Collectors.toList()))
                        .build());
            } else {
                return ResponseEntity.badRequest().body(new MessageResponse("Error: Invalid Google Token."));
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(new MessageResponse("Error: Google authentication failed."));
        }
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@Valid @RequestBody ProfileUpdateRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof UserDetailsImpl userDetails)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new MessageResponse("Unauthorized"));
        }

        User user = userRepository.findById(userDetails.getId()).orElseThrow();
        user.setFullName(request.getFullName());
        user.setBio(request.getBio());
        user.setAvatarUrl(request.getAvatarUrl());

        userRepository.save(user);

        return ResponseEntity.ok(JwtResponse.builder()
                .token(jwtUtils.generateJwtToken(user.getEmail()))
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .roles(java.util.Collections.singletonList(user.getRole().name()))
                .plan(user.getPlan().name())
                .lastAiWishGeneration(user.getLastAiWishGeneration())
                .lastAiGiftGeneration(user.getLastAiGiftGeneration())
                .badges(userBadgeRepository.findByUser(user).stream().map(app.time2wish.model.UserBadge::getBadgeName).collect(java.util.stream.Collectors.toList()))
                .build());
    }

    @PutMapping("/password")
    public ResponseEntity<?> updatePassword(@Valid @RequestBody PasswordUpdateRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof UserDetailsImpl userDetails)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new MessageResponse("Unauthorized"));
        }

        User user = userRepository.findById(userDetails.getId()).orElseThrow();

        if (!encoder.matches(request.getCurrentPassword(), user.getPassword())) {
            return ResponseEntity.badRequest().body(new MessageResponse("Error: Incorrect current password"));
        }

        user.setPassword(encoder.encode(request.getNewPassword()));
        userRepository.save(user);

        return ResponseEntity.ok(new MessageResponse("Password updated successfully!"));
    }
}
