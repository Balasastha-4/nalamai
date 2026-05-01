package com.nalamai.backend.controllers;

import com.nalamai.backend.dtos.ErrorResponse;
import com.nalamai.backend.dtos.UserResponse;
import com.nalamai.backend.dtos.UserUpdateRequest;
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
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private DoctorProfileRepository doctorProfileRepository;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * Health check endpoint
     * GET /api/users/health
     */
    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Nalamai Spring Boot API is running and connected to PostgreSQL!");
    }

    /**
     * Get all users (legacy endpoint)
     * GET /api/users
     */
    @GetMapping
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    /**
     * Get user profile by ID
     * GET /api/users/{userId}
     */
    @GetMapping("/{userId}")
    public ResponseEntity<?> getUserProfile(@PathVariable Long userId) {
        try {
            Optional<User> userOptional = userRepository.findById(userId);

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("User not found", "USER_NOT_FOUND", 404));
            }

            User user = userOptional.get();

            // Build response
            UserResponse response = new UserResponse(
                    user.getId(),
                    user.getEmail(),
                    user.getName(),
                    user.getRole(),
                    user.getPhone(),
                    user.getAddress(),
                    user.getProfilePictureUrl(),
                    user.getDateOfBirth() != null ? user.getDateOfBirth().toString() : null
            );

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error retrieving user profile: " + e.getMessage(), "INTERNAL_ERROR", 500));
        }
    }

    /**
     * Update user profile
     * PUT /api/users/{userId}
     */
    @PutMapping("/{userId}")
    public ResponseEntity<?> updateUserProfile(@PathVariable Long userId, @RequestBody UserUpdateRequest request) {
        try {
            Optional<User> userOptional = userRepository.findById(userId);

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("User not found", "USER_NOT_FOUND", 404));
            }

            User user = userOptional.get();

            // Update fields if provided
            if (request.getName() != null && !request.getName().isEmpty()) {
                user.setName(request.getName());
            }

            if (request.getPhone() != null && !request.getPhone().isEmpty()) {
                user.setPhone(request.getPhone());
            }

            if (request.getAddress() != null && !request.getAddress().isEmpty()) {
                user.setAddress(request.getAddress());
            }

            if (request.getProfilePictureUrl() != null && !request.getProfilePictureUrl().isEmpty()) {
                user.setProfilePictureUrl(request.getProfilePictureUrl());
            }

            if (request.getDateOfBirth() != null && !request.getDateOfBirth().isEmpty()) {
                try {
                    DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE;
                    user.setDateOfBirth(LocalDate.parse(request.getDateOfBirth(), formatter));
                } catch (Exception e) {
                    return ResponseEntity.badRequest()
                            .body(new ErrorResponse("Invalid date format for dateOfBirth. Use YYYY-MM-DD", "INVALID_DATE_FORMAT", 400));
                }
            }

            // Save updated user
            User updatedUser = userRepository.save(user);

            // Build response
            UserResponse response = new UserResponse(
                    updatedUser.getId(),
                    updatedUser.getEmail(),
                    updatedUser.getName(),
                    updatedUser.getRole(),
                    updatedUser.getPhone(),
                    updatedUser.getAddress(),
                    updatedUser.getProfilePictureUrl(),
                    updatedUser.getDateOfBirth() != null ? updatedUser.getDateOfBirth().toString() : null
            );

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error updating user profile: " + e.getMessage(), "INTERNAL_ERROR", 500));
        }
    }

    /**
     * Get extended profile (UserProfile for patient or DoctorProfile for doctor)
     * GET /api/users/{userId}/profile
     */
    @GetMapping("/{userId}/profile")
    public ResponseEntity<?> getExtendedProfile(@PathVariable Long userId) {
        try {
            Optional<User> userOptional = userRepository.findById(userId);

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("User not found", "USER_NOT_FOUND", 404));
            }

            User user = userOptional.get();

            if ("patient".equalsIgnoreCase(user.getRole())) {
                Optional<UserProfile> userProfile = userProfileRepository.findByUserId(userId);
                if (userProfile.isEmpty()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ErrorResponse("User profile not found", "PROFILE_NOT_FOUND", 404));
                }
                return ResponseEntity.ok(flattenProfile(user, userProfile.get()));
            } else if ("doctor".equalsIgnoreCase(user.getRole())) {
                Optional<DoctorProfile> doctorProfile = doctorProfileRepository.findByUserId(userId);
                if (doctorProfile.isEmpty()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ErrorResponse("Doctor profile not found", "PROFILE_NOT_FOUND", 404));
                }
                return ResponseEntity.ok(flattenDoctorProfile(user, doctorProfile.get()));
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(new ErrorResponse("Invalid user role", "INVALID_ROLE", 400));
            }

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error retrieving extended profile: " + e.getMessage(), "INTERNAL_ERROR", 500));
        }
    }

    private java.util.Map<String, Object> flattenProfile(User user, UserProfile profile) {
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        map.put("name", user.getName());
        map.put("age", user.getDateOfBirth() != null ? user.getDateOfBirth().toString() : "");
        if (profile != null) {
            map.put("bloodGroup", profile.getBloodGroup());
            map.put("allergies", profile.getAllergies());
            map.put("medicalHistory", profile.getMedicalHistory());
            map.put("emergencyContactName", profile.getEmergencyContactName());
            map.put("emergencyContactPhone", profile.getEmergencyContactPhone());
        }
        return map;
    }

    private java.util.Map<String, Object> flattenDoctorProfile(User user, DoctorProfile profile) {
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        map.put("name", user.getName());
        if (profile != null) {
            map.put("specialization", profile.getSpecialty());
            map.put("experienceYears", profile.getYearsOfExperience());
            map.put("licenseNumber", profile.getLicenseNumber());
            map.put("hospitalAffiliation", profile.getHospitalName());
        }
        return map;
    }

    /**
     * Update extended profile (UserProfile for patient or DoctorProfile for doctor)
     * PUT /api/users/{userId}/profile
     */
    @PutMapping("/{userId}/profile")
    public ResponseEntity<?> updateExtendedProfile(@PathVariable Long userId, @RequestBody java.util.Map<String, Object> data) {
        try {
            Optional<User> userOptional = userRepository.findById(userId);

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("User not found", "USER_NOT_FOUND", 404));
            }

            User user = userOptional.get();

            if ("patient".equalsIgnoreCase(user.getRole())) {
                Optional<UserProfile> userProfileOptional = userProfileRepository.findByUserId(userId);
                UserProfile userProfile = userProfileOptional.orElseGet(() -> new UserProfile(user));

                // Update User fields if present in payload



                // Update User fields if present in payload
                if (data.containsKey("name") && data.get("name") != null) {
                    user.setName(data.get("name").toString());
                    userRepository.save(user);
                }

                // Update UserProfile fields
                if (data.containsKey("bloodGroup") && data.get("bloodGroup") != null) {
                    userProfile.setBloodGroup(data.get("bloodGroup").toString());
                }
                if (data.containsKey("allergies") && data.get("allergies") != null) {
                    userProfile.setAllergies(data.get("allergies").toString());
                }
                if (data.containsKey("medicalHistory") && data.get("medicalHistory") != null) {
                    userProfile.setMedicalHistory(data.get("medicalHistory").toString());
                }
                if (data.containsKey("emergencyContactName") && data.get("emergencyContactName") != null) {
                    userProfile.setEmergencyContactName(data.get("emergencyContactName").toString());
                }
                if (data.containsKey("emergencyContactPhone") && data.get("emergencyContactPhone") != null) {
                    userProfile.setEmergencyContactPhone(data.get("emergencyContactPhone").toString());
                }

                UserProfile updated = userProfileRepository.save(userProfile);
                return ResponseEntity.ok(flattenProfile(user, updated));

            } else if ("doctor".equalsIgnoreCase(user.getRole())) {
                Optional<DoctorProfile> doctorProfileOptional = doctorProfileRepository.findByUserId(userId);

                if (doctorProfileOptional.isEmpty()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(new ErrorResponse("Doctor profile not found", "PROFILE_NOT_FOUND", 404));
                }

                DoctorProfile doctorProfile = doctorProfileOptional.get();

                // Update fields from request
                if (data.containsKey("specialization") && data.get("specialization") != null) {
                    doctorProfile.setSpecialty(data.get("specialization").toString());
                }

                DoctorProfile updated = doctorProfileRepository.save(doctorProfile);
                return ResponseEntity.ok(flattenDoctorProfile(user, updated));

            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(new ErrorResponse("Invalid user role", "INVALID_ROLE", 400));
            }

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error updating extended profile: " + e.getMessage(), "INTERNAL_ERROR", 500));
        }
    }

    /**
     * Deactivate user account (soft delete)
     * DELETE /api/users/{userId}
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<?> deactivateUser(@PathVariable Long userId) {
        try {
            Optional<User> userOptional = userRepository.findById(userId);

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("User not found", "USER_NOT_FOUND", 404));
            }

            User user = userOptional.get();

            // Perform soft delete by removing user data or marking as inactive
            // For now, we'll actually delete the user
            // In production, consider implementing a soft delete strategy with an 'active' field
            userRepository.delete(user);

            return ResponseEntity.ok(new java.util.HashMap<String, String>() {{
                put("message", "User account deactivated successfully");
                put("status", "success");
            }});

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ErrorResponse("Error deactivating user account: " + e.getMessage(), "INTERNAL_ERROR", 500));
        }
    }

    /**
     * Legacy register endpoint (kept for backward compatibility)
     * POST /api/users/register
     */
    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            return ResponseEntity.badRequest().body("Error: Email is already taken!");
        }

        User savedUser = userRepository.save(user);
        return ResponseEntity.ok(savedUser);
    }

    /**
     * Legacy login endpoint (kept for backward compatibility)
     * POST /api/users/login
     */
    @PostMapping("/login")
    public ResponseEntity<?> loginUser(@RequestBody java.util.Map<String, String> request) {
        String email = request.get("email").toLowerCase().trim();
        String password = request.get("password");

        System.out.println("Login attempt for email: " + email);

        java.util.Optional<User> userOptional = userRepository.findByEmailIgnoreCase(email);
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            System.out.println("User found: " + user.getEmail() + " | Role: " + user.getRole());

            if (user.getPassword().equals(password)) {
                String token = jwtUtil.generateToken(user.getEmail(), user.getRole() != null ? user.getRole() : "patient");

                java.util.Map<String, Object> responseFields = new java.util.HashMap<>();
                responseFields.put("user", user);
                responseFields.put("token", token);
                responseFields.put("role", user.getRole() != null ? user.getRole() : "patient");

                return ResponseEntity.ok(responseFields);
            } else {
                System.out.println("Password mismatch for user: " + email);
            }
        } else {
            System.out.println("User not found in database: " + email);
        }
        return ResponseEntity.status(401).body("Error: Invalid email or password");
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
