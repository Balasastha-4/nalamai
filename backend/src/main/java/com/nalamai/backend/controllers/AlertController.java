package com.nalamai.backend.controllers;

import com.nalamai.backend.models.Alert;
import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.AlertRepository;
import com.nalamai.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/alerts")
@CrossOrigin(origins = "*")
public class AlertController {

    @Autowired
    private AlertRepository alertRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Get all alerts for a user
     * GET /api/alerts/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getUserAlerts(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "false") boolean includeResolved) {
        try {
            List<Alert> alerts = alertRepository.findByUserId(userId);
            
            if (!includeResolved) {
                alerts = alerts.stream()
                        .filter(a -> !a.getIsResolved())
                        .collect(Collectors.toList());
            }
            
            // Sort by severity and then by date
            alerts.sort((a, b) -> {
                int severityCompare = getSeverityOrder(b.getSeverity()) - getSeverityOrder(a.getSeverity());
                if (severityCompare != 0) return severityCompare;
                return b.getCreatedAt().compareTo(a.getCreatedAt());
            });
            
            List<Map<String, Object>> result = alerts.stream()
                    .map(this::alertToMap)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching alerts: " + e.getMessage());
        }
    }

    /**
     * Get unread alert count for a user
     * GET /api/alerts/user/{userId}/count
     */
    @GetMapping("/user/{userId}/count")
    public ResponseEntity<?> getAlertCount(@PathVariable Long userId) {
        try {
            List<Alert> alerts = alertRepository.findByUserId(userId);
            
            long unresolvedCount = alerts.stream()
                    .filter(a -> !a.getIsResolved())
                    .count();
            
            long highCount = alerts.stream()
                    .filter(a -> !a.getIsResolved() && "HIGH".equals(a.getSeverity()))
                    .count();
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "unresolved", unresolvedCount,
                    "high_priority", highCount
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching count: " + e.getMessage());
        }
    }

    /**
     * Create a new alert
     * POST /api/alerts/
     */
    @PostMapping("/")
    public ResponseEntity<?> createAlert(@RequestBody Map<String, Object> payload) {
        try {
            Long userId = Long.valueOf(payload.get("user_id").toString());
            String message = payload.get("message").toString();
            String severity = payload.containsKey("severity") ? payload.get("severity").toString() : "MEDIUM";
            
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("User not found");
            }
            
            Alert alert = new Alert(userOpt.get(), message, severity.toUpperCase());
            Alert saved = alertRepository.save(alert);
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "id", saved.getId(),
                    "message", "Alert created successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error creating alert: " + e.getMessage());
        }
    }

    /**
     * Mark alert as resolved
     * PUT /api/alerts/{alertId}/resolve
     */
    @PutMapping("/{alertId}/resolve")
    public ResponseEntity<?> resolveAlert(@PathVariable Long alertId) {
        try {
            Optional<Alert> alertOpt = alertRepository.findById(alertId);
            
            if (alertOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            Alert alert = alertOpt.get();
            alert.setIsResolved(true);
            alert.setResolvedAt(LocalDateTime.now());
            
            alertRepository.save(alert);
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "Alert resolved successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error resolving alert: " + e.getMessage());
        }
    }

    /**
     * Mark all alerts as resolved for a user
     * PUT /api/alerts/user/{userId}/resolve-all
     */
    @PutMapping("/user/{userId}/resolve-all")
    public ResponseEntity<?> resolveAllAlerts(@PathVariable Long userId) {
        try {
            List<Alert> alerts = alertRepository.findByUserId(userId);
            
            int resolved = 0;
            for (Alert alert : alerts) {
                if (!alert.getIsResolved()) {
                    alert.setIsResolved(true);
                    alert.setResolvedAt(LocalDateTime.now());
                    alertRepository.save(alert);
                    resolved++;
                }
            }
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "resolved_count", resolved,
                    "message", "All alerts resolved"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error resolving alerts: " + e.getMessage());
        }
    }

    /**
     * Delete an alert
     * DELETE /api/alerts/{alertId}
     */
    @DeleteMapping("/{alertId}")
    public ResponseEntity<?> deleteAlert(@PathVariable Long alertId) {
        try {
            Optional<Alert> alertOpt = alertRepository.findById(alertId);
            
            if (alertOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            alertRepository.delete(alertOpt.get());
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "Alert deleted successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error deleting alert: " + e.getMessage());
        }
    }

    /**
     * Get alert history for a user
     * GET /api/alerts/user/{userId}/history
     */
    @GetMapping("/user/{userId}/history")
    public ResponseEntity<?> getAlertHistory(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "30") int days) {
        try {
            List<Alert> alerts = alertRepository.findByUserId(userId);
            
            LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
            
            List<Map<String, Object>> history = alerts.stream()
                    .filter(a -> a.getCreatedAt().isAfter(cutoff))
                    .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
                    .map(this::alertToMap)
                    .collect(Collectors.toList());
            
            // Group by date for statistics
            Map<String, Long> byDate = alerts.stream()
                    .filter(a -> a.getCreatedAt().isAfter(cutoff))
                    .collect(Collectors.groupingBy(
                            a -> a.getCreatedAt().toLocalDate().toString(),
                            Collectors.counting()
                    ));
            
            Map<String, Long> bySeverity = alerts.stream()
                    .filter(a -> a.getCreatedAt().isAfter(cutoff))
                    .collect(Collectors.groupingBy(Alert::getSeverity, Collectors.counting()));
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "history", history,
                    "by_date", byDate,
                    "by_severity", bySeverity,
                    "total", history.size()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching history: " + e.getMessage());
        }
    }

    /**
     * Create health-related alert (used by AI service)
     * POST /api/alerts/health
     */
    @PostMapping("/health")
    public ResponseEntity<?> createHealthAlert(@RequestBody Map<String, Object> payload) {
        try {
            Long userId = Long.valueOf(payload.get("user_id").toString());
            String vitalType = payload.get("vital_type").toString();
            Double value = Double.valueOf(payload.get("value").toString());
            String status = payload.get("status").toString();
            
            Optional<User> userOpt = userRepository.findById(userId);
            if (userOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("User not found");
            }
            
            String severity = "critical".equals(status) ? "HIGH" : "MEDIUM";
            String message = String.format("Abnormal %s reading: %.1f. Status: %s. Please consult your healthcare provider.",
                    vitalType, value, status);
            
            Alert alert = new Alert(userOpt.get(), message, severity);
            Alert saved = alertRepository.save(alert);
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "id", saved.getId(),
                    "alert_severity", severity,
                    "message", "Health alert created"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error creating health alert: " + e.getMessage());
        }
    }

    // Helper methods
    
    private Map<String, Object> alertToMap(Alert alert) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", alert.getId());
        map.put("user_id", alert.getUser().getId());
        map.put("message", alert.getAlertMessage());
        map.put("severity", alert.getSeverity());
        map.put("is_resolved", alert.getIsResolved());
        map.put("created_at", alert.getCreatedAt().toString());
        map.put("resolved_at", alert.getResolvedAt() != null ? alert.getResolvedAt().toString() : null);
        return map;
    }
    
    private int getSeverityOrder(String severity) {
        return switch (severity.toUpperCase()) {
            case "HIGH" -> 3;
            case "MEDIUM" -> 2;
            case "LOW" -> 1;
            default -> 0;
        };
    }
}
