package com.nalamai.backend.controllers;

import com.nalamai.backend.dtos.AuthRequest;
import com.nalamai.backend.dtos.AuthResponse;
import com.nalamai.backend.dtos.ErrorResponse;
import com.nalamai.backend.models.DoctorProfile;
import com.nalamai.backend.models.User;
import com.nalamai.backend.models.UserProfile;
import com.nalamai.backend.repositories.DoctorProfileRepository;
import com.nalamai.backend.repositories.UserProfileRepository;
import com.nalamai.backend.repositories.UserRepository;
import com.nalamai.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private DoctorProfileRepository doctorProfileRepository;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * Register a new user (patient or doctor)
     * POST /api/auth/register
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody AuthRequest request) {
        try {
            // Validate required fields
            if (request.getEmail() == null || request.getEmail().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Email is required", "VALIDATION_ERROR", 400));
            }

            if (request.getPassword() == null || request.getPassword().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Password is required", "VALIDATION_ERROR", 400));
            }

            if (request.getName() == null || request.getName().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Name is required", "VALIDATION_ERROR", 400));
            }

            if (request.getRole() == null || request.getRole().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Role is required (patient or doctor)", "VALIDATION_ERROR", 400));
            }

            // Check if email already exists
            if (userRepository.existsByEmail(request.getEmail())) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Email is already taken", "DUPLICATE_EMAIL", 400));
            }

            // Create new user
            User user = new User();
            user.setEmail(request.getEmail().toLowerCase().trim());
            user.setPassword(request.getPassword()); // In production, hash this with BCrypt
            user.setName(request.getName());
            user.setRole(request.getRole().toLowerCase());
            user.setPhone(request.getPhone());
            user.setAddress(request.getAddress());

            // Parse dateOfBirth if provided
            if (request.getDateOfBirth() != null && !request.getDateOfBirth().isEmpty()) {
                try {
                    DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE;
                    user.setDateOfBirth(LocalDate.parse(request.getDateOfBirth(), formatter));
                } catch (Exception e) {
                    return ResponseEntity.badRequest()
                            .body(new ErrorResponse("Invalid date format for dateOfBirth. Use YYYY-MM-DD", "INVALID_DATE_FORMAT", 400));
                }
            }

            // Save user
            User savedUser = userRepository.save(user);

            // Create extended profile based on role
            if ("patient".equalsIgnoreCase(savedUser.getRole())) {
                UserProfile userProfile = new UserProfile(savedUser);
                userProfileRepository.save(userProfile);
                savedUser.setUserProfile(userProfile);
            } else if ("doctor".equalsIgnoreCase(savedUser.getRole())) {
                DoctorProfile doctorProfile = new DoctorProfile(savedUser);
                doctorProfileRepository.save(doctorProfile);
                savedUser.setDoctorProfile(doctorProfile);
            }

            // Generate JWT token
            String token = jwtUtil.generateToken(savedUser.getEmail(), savedUser.getRole());

            // Build response
            AuthResponse response = new AuthResponse(
                    savedUser.getId(),
                    savedUser.getEmail(),
                    savedUser.getName(),
                    savedUser.getRole(),
                    token,
                    savedUser.getUserProfile(),
                    savedUser.getDoctorProfile()
            );

            return ResponseEntity.status(HttpStatus.CREATED).body(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error registering user: " + e.getMessage(), "REGISTRATION_ERROR", 500));
        }
    }

    /**
     * Authenticate user and return token
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody AuthRequest request) {
        try {
            // Validate required fields
            if (request.getEmail() == null || request.getEmail().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Email is required", "VALIDATION_ERROR", 400));
            }

            if (request.getPassword() == null || request.getPassword().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new ErrorResponse("Password is required", "VALIDATION_ERROR", 400));
            }

            // Find user by email
            String email = request.getEmail().toLowerCase().trim();
            Optional<User> userOptional = userRepository.findByEmailIgnoreCase(email);

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ErrorResponse("Invalid email or password", "INVALID_CREDENTIALS", 401));
            }

            User user = userOptional.get();

            // Validate password
            if (!user.getPassword().equals(request.getPassword())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ErrorResponse("Invalid email or password", "INVALID_CREDENTIALS", 401));
            }

            // Load extended profile
            if ("patient".equalsIgnoreCase(user.getRole())) {
                Optional<UserProfile> userProfile = userProfileRepository.findByUserId(user.getId());
                userProfile.ifPresent(user::setUserProfile);
            } else if ("doctor".equalsIgnoreCase(user.getRole())) {
                Optional<DoctorProfile> doctorProfile = doctorProfileRepository.findByUserId(user.getId());
                doctorProfile.ifPresent(user::setDoctorProfile);
            }

            // Generate JWT token
            String token = jwtUtil.generateToken(user.getEmail(), user.getRole());

            // Build response
            AuthResponse response = new AuthResponse(
                    user.getId(),
                    user.getEmail(),
                    user.getName(),
                    user.getRole(),
                    token,
                    user.getUserProfile(),
                    user.getDoctorProfile()
            );

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error during login: " + e.getMessage(), "LOGIN_ERROR", 500));
        }
    }

    /**
     * Logout user (invalidate token)
     * POST /api/auth/logout
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            // In a real implementation, you would add the token to a blacklist
            // For now, we just return a success message
            Map<String, String> response = new HashMap<>();
            response.put("message", "Logged out successfully");
            response.put("status", "success");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error during logout: " + e.getMessage(), "LOGOUT_ERROR", 500));
        }
    }

    /**
     * Exception handler for controller
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleException(Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("An error occurred: " + e.getMessage(), "INTERNAL_ERROR", 500));
    }
}
