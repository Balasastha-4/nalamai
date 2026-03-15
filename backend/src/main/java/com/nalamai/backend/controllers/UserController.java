package com.nalamai.backend.controllers;

import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.UserRepository;
import com.nalamai.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*") // Allows Flutter web/emulator to hit API
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Nalamai Spring Boot API is running and connected to PostgreSQL!");
    }

    @GetMapping
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            return ResponseEntity.badRequest().body("Error: Email is already taken!");
        }

        // Note: Password should be hashed here with BCrypt in a real scenario
        User savedUser = userRepository.save(user);
        return ResponseEntity.ok(savedUser);
    }

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
}
