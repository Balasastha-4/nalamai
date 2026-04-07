package com.nalamai.backend.controllers;

import com.nalamai.backend.dtos.CreateVitalRequest;
import com.nalamai.backend.dtos.VitalDTO;
import com.nalamai.backend.services.VitalService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/vitals")
public class VitalController {

    @Autowired
    private VitalService vitalService;

    /**
     * GET /api/vitals/patient/{patientId}
     * Get all vitals for a patient, optionally filtered by type and days
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getPatientVitals(
            @PathVariable Long patientId,
            @RequestParam(required = false) String type,
            @RequestParam(required = false, defaultValue = "30") Integer days) {
        try {
            List<VitalDTO> vitals = vitalService.getPatientVitals(patientId, type, days);
            return ResponseEntity.ok(vitals);
        } catch (Exception e) {
            log.error("Error fetching patient vitals", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch vitals: " + e.getMessage()));
        }
    }

    /**
     * GET /api/vitals/patient/{patientId}/latest
     * Get latest vital readings for a patient
     */
    @GetMapping("/patient/{patientId}/latest")
    public ResponseEntity<?> getLatestVitals(@PathVariable Long patientId) {
        try {
            List<VitalDTO> vitals = vitalService.getLatestVitals(patientId);
            return ResponseEntity.ok(vitals);
        } catch (Exception e) {
            log.error("Error fetching latest vitals", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch latest vitals: " + e.getMessage()));
        }
    }

    /**
     * POST /api/vitals
     * Record a new vital reading
     */
    @PostMapping
    public ResponseEntity<?> recordVital(@Valid @RequestBody CreateVitalRequest request) {
        try {
            VitalDTO vital = vitalService.recordVital(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(vital);
        } catch (RuntimeException e) {
            log.error("Error recording vital", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error recording vital", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to record vital"));
        }
    }

    /**
     * GET /api/vitals/patient/{patientId}/trend/{type}
     * Get trend data for a specific vital type
     */
    @GetMapping("/patient/{patientId}/trend/{type}")
    public ResponseEntity<?> getVitalTrend(
            @PathVariable Long patientId,
            @PathVariable String type) {
        try {
            List<VitalDTO> trendData = vitalService.getVitalTrend(patientId, type);
            return ResponseEntity.ok(trendData);
        } catch (Exception e) {
            log.error("Error fetching vital trend", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch vital trend: " + e.getMessage()));
        }
    }

    private Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        return response;
    }
}
