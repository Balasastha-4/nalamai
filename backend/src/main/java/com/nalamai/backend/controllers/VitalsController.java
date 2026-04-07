package com.nalamai.backend.controllers;

import com.nalamai.backend.models.User;
import com.nalamai.backend.models.Vital;
import com.nalamai.backend.repositories.UserRepository;
import com.nalamai.backend.repositories.VitalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/vitals/advanced")
@CrossOrigin(origins = "*")
public class VitalsController {

    @Autowired
    private VitalRepository vitalRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Get all vitals for a patient
     * GET /api/vitals/patient/{patientId}
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getPatientVitals(
            @PathVariable Long patientId,
            @RequestParam(defaultValue = "7") int days) {
        try {
            List<Vital> vitals = vitalRepository.findByUserIdOrderByTimestampDesc(patientId);
            
            // Filter by days
            LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
            List<Map<String, Object>> result = vitals.stream()
                    .filter(v -> v.getTimestamp().isAfter(cutoff))
                    .map(this::vitalToMap)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching vitals: " + e.getMessage());
        }
    }

    /**
     * Get latest vitals for a patient
     * GET /api/vitals/patient/{patientId}/latest
     */
    @GetMapping("/patient/{patientId}/latest")
    public ResponseEntity<?> getLatestVitals(@PathVariable Long patientId) {
        try {
            Map<String, Object> latestVitals = new HashMap<>();
            
            String[] vitalTypes = {"HeartRate", "BP_Systolic", "BP_Diastolic", "SpO2", "Temperature"};
            
            for (String type : vitalTypes) {
                Optional<Vital> latest = vitalRepository.findLatestByUserIdAndType(patientId, type);
                if (latest.isPresent()) {
                    Vital v = latest.get();
                    Map<String, Object> vitalData = new HashMap<>();
                    vitalData.put("value", v.getValue());
                    vitalData.put("unit", v.getUnit());
                    vitalData.put("status", getVitalStatus(type, v.getValue()));
                    vitalData.put("timestamp", v.getTimestamp().toString());
                    latestVitals.put(type, vitalData);
                }
            }
            
            // If no data, return defaults
            if (latestVitals.isEmpty()) {
                latestVitals.put("HeartRate", Map.of("value", 75, "unit", "bpm", "status", "normal"));
                latestVitals.put("BP_Systolic", Map.of("value", 120, "unit", "mmHg", "status", "normal"));
                latestVitals.put("BP_Diastolic", Map.of("value", 80, "unit", "mmHg", "status", "normal"));
                latestVitals.put("SpO2", Map.of("value", 98, "unit", "%", "status", "normal"));
                latestVitals.put("Temperature", Map.of("value", 36.6, "unit", "°C", "status", "normal"));
            }
            
            return ResponseEntity.ok(latestVitals);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching latest vitals: " + e.getMessage());
        }
    }

    /**
     * Record a single vital
     * POST /api/vitals/
     */
    @PostMapping("/")
    public ResponseEntity<?> recordVital(@RequestBody Map<String, Object> payload) {
        try {
            Long patientId = Long.valueOf(payload.get("patient_id").toString());
            String type = payload.get("type").toString();
            Double value = Double.valueOf(payload.get("value").toString());
            String unit = payload.containsKey("unit") ? payload.get("unit").toString() : getDefaultUnit(type);
            
            Optional<User> userOpt = userRepository.findById(patientId);
            if (userOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Patient not found");
            }
            
            Vital vital = new Vital(userOpt.get(), type, value, unit);
            vital.setIsAlert(isAbnormalValue(type, value));
            
            Vital saved = vitalRepository.save(vital);
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "id", saved.getId(),
                    "message", "Vital recorded successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error recording vital: " + e.getMessage());
        }
    }

    /**
     * Record multiple vitals at once
     * POST /api/vitals/batch
     */
    @PostMapping("/batch")
    public ResponseEntity<?> recordVitalsBatch(@RequestBody Map<String, Object> payload) {
        try {
            Long patientId = Long.valueOf(payload.get("patient_id").toString());
            List<Map<String, Object>> vitals = (List<Map<String, Object>>) payload.get("vitals");
            
            Optional<User> userOpt = userRepository.findById(patientId);
            if (userOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Patient not found");
            }
            
            User user = userOpt.get();
            List<Vital> savedVitals = new ArrayList<>();
            
            for (Map<String, Object> vitalData : vitals) {
                String type = vitalData.get("type").toString();
                Double value = Double.valueOf(vitalData.get("value").toString());
                String unit = vitalData.containsKey("unit") ? vitalData.get("unit").toString() : getDefaultUnit(type);
                
                Vital vital = new Vital(user, type, value, unit);
                vital.setIsAlert(isAbnormalValue(type, value));
                
                if (vitalData.containsKey("timestamp")) {
                    vital.setTimestamp(LocalDateTime.parse(vitalData.get("timestamp").toString()));
                }
                
                savedVitals.add(vitalRepository.save(vital));
            }
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "saved", savedVitals.size(),
                    "message", "Vitals recorded successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error recording vitals: " + e.getMessage());
        }
    }

    /**
     * Get vital statistics for a patient
     * GET /api/vitals/patient/{patientId}/stats
     */
    @GetMapping("/patient/{patientId}/stats")
    public ResponseEntity<?> getVitalStats(
            @PathVariable Long patientId,
            @RequestParam(defaultValue = "7") int days) {
        try {
            List<Vital> vitals = vitalRepository.findByUserId(patientId);
            LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
            
            Map<String, Map<String, Object>> stats = new HashMap<>();
            String[] vitalTypes = {"HeartRate", "BP_Systolic", "BP_Diastolic", "SpO2", "Temperature"};
            
            for (String type : vitalTypes) {
                List<Double> values = vitals.stream()
                        .filter(v -> v.getType().equals(type) && v.getTimestamp().isAfter(cutoff))
                        .map(Vital::getValue)
                        .collect(Collectors.toList());
                
                if (!values.isEmpty()) {
                    DoubleSummaryStatistics statsResult = values.stream()
                            .mapToDouble(Double::doubleValue)
                            .summaryStatistics();
                    
                    stats.put(type, Map.of(
                            "count", values.size(),
                            "average", Math.round(statsResult.getAverage() * 10) / 10.0,
                            "min", statsResult.getMin(),
                            "max", statsResult.getMax(),
                            "latest", values.get(values.size() - 1)
                    ));
                }
            }
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "patient_id", patientId,
                    "period_days", days,
                    "statistics", stats
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching stats: " + e.getMessage());
        }
    }

    /**
     * Get alerts for abnormal vitals
     * GET /api/vitals/patient/{patientId}/alerts
     */
    @GetMapping("/patient/{patientId}/alerts")
    public ResponseEntity<?> getVitalAlerts(@PathVariable Long patientId) {
        try {
            List<Vital> vitals = vitalRepository.findByUserId(patientId);
            
            List<Map<String, Object>> alerts = vitals.stream()
                    .filter(Vital::getIsAlert)
                    .sorted((a, b) -> b.getTimestamp().compareTo(a.getTimestamp()))
                    .limit(10)
                    .map(v -> {
                        Map<String, Object> alert = new HashMap<>();
                        alert.put("type", v.getType());
                        alert.put("value", v.getValue());
                        alert.put("unit", v.getUnit());
                        alert.put("timestamp", v.getTimestamp().toString());
                        alert.put("message", getAlertMessage(v.getType(), v.getValue()));
                        return alert;
                    })
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "alerts", alerts,
                    "count", alerts.size()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching alerts: " + e.getMessage());
        }
    }

    // Helper methods
    
    private Map<String, Object> vitalToMap(Vital vital) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", vital.getId());
        map.put("type", vital.getType());
        map.put("value", vital.getValue());
        map.put("unit", vital.getUnit());
        map.put("isAlert", vital.getIsAlert());
        map.put("timestamp", vital.getTimestamp().toString());
        return map;
    }
    
    private String getDefaultUnit(String type) {
        return switch (type) {
            case "HeartRate" -> "bpm";
            case "BP_Systolic", "BP_Diastolic" -> "mmHg";
            case "SpO2" -> "%";
            case "Temperature" -> "°C";
            case "Weight" -> "kg";
            default -> "";
        };
    }
    
    private String getVitalStatus(String type, Double value) {
        return switch (type) {
            case "HeartRate" -> (value >= 60 && value <= 100) ? "normal" : ((value >= 50 && value <= 120) ? "warning" : "critical");
            case "BP_Systolic" -> (value >= 90 && value <= 120) ? "normal" : ((value >= 80 && value <= 140) ? "warning" : "critical");
            case "BP_Diastolic" -> (value >= 60 && value <= 80) ? "normal" : ((value >= 50 && value <= 90) ? "warning" : "critical");
            case "SpO2" -> (value >= 95) ? "normal" : ((value >= 90) ? "warning" : "critical");
            case "Temperature" -> (value >= 36.1 && value <= 37.2) ? "normal" : ((value >= 35.5 && value <= 38.0) ? "warning" : "critical");
            default -> "normal";
        };
    }
    
    private boolean isAbnormalValue(String type, Double value) {
        String status = getVitalStatus(type, value);
        return status.equals("warning") || status.equals("critical");
    }
    
    private String getAlertMessage(String type, Double value) {
        String status = getVitalStatus(type, value);
        if (status.equals("critical")) {
            return type + " is critically abnormal at " + value + ". Seek immediate medical attention.";
        } else if (status.equals("warning")) {
            return type + " is outside normal range at " + value + ". Monitor closely.";
        }
        return type + " is normal.";
    }
}
