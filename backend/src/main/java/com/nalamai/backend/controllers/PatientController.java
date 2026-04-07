package com.nalamai.backend.controllers;

import com.nalamai.backend.dtos.*;
import com.nalamai.backend.services.PatientService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api")
public class PatientController {

    @Autowired
    private PatientService patientService;

    /**
     * GET /api/doctor/{doctorId}/patients
     * Get all patients for a doctor with their latest vitals
     */
    @GetMapping("/doctor/{doctorId}/patients")
    public ResponseEntity<?> getDoctorPatients(@PathVariable Long doctorId) {
        try {
            List<PatientSummaryDTO> patients = patientService.getDoctorPatients(doctorId);
            return ResponseEntity.ok(patients);
        } catch (Exception e) {
            log.error("Error fetching doctor's patients", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch patients: " + e.getMessage()));
        }
    }

    /**
     * GET /api/patients/{patientId}
     * Get complete patient details including profile, vitals, medical records, and documents
     */
    @GetMapping("/patients/{patientId}")
    public ResponseEntity<?> getPatientDetails(@PathVariable Long patientId) {
        try {
            PatientDetailDTO patient = patientService.getPatientDetails(patientId);
            return ResponseEntity.ok(patient);
        } catch (RuntimeException e) {
            log.error("Error fetching patient details", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error fetching patient details", e);
            return ResponseEntity.status(500).body(createErrorResponse("Failed to fetch patient details"));
        }
    }

    /**
     * GET /api/patients/{patientId}/vitals
     * Get patient vitals (same as /api/vitals/patient/{patientId})
     */
    @GetMapping("/patients/{patientId}/vitals")
    public ResponseEntity<?> getPatientVitals(
            @PathVariable Long patientId,
            @RequestParam(required = false) String type,
            @RequestParam(required = false, defaultValue = "30") Integer days) {
        try {
            List<VitalDTO> vitals = patientService.getPatientVitals(patientId, type, days);
            return ResponseEntity.ok(vitals);
        } catch (Exception e) {
            log.error("Error fetching patient vitals", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch vitals: " + e.getMessage()));
        }
    }

    /**
     * GET /api/patients/{patientId}/records
     * Get patient medical records
     */
    @GetMapping("/patients/{patientId}/records")
    public ResponseEntity<?> getPatientRecords(@PathVariable Long patientId) {
        try {
            List<MedicalRecordDTO> records = patientService.getPatientRecords(patientId);
            return ResponseEntity.ok(records);
        } catch (Exception e) {
            log.error("Error fetching patient records", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch records: " + e.getMessage()));
        }
    }

    /**
     * GET /api/patients/{patientId}/documents
     * Get patient documents
     */
    @GetMapping("/patients/{patientId}/documents")
    public ResponseEntity<?> getPatientDocuments(@PathVariable Long patientId) {
        try {
            List<DocumentDTO> documents = patientService.getPatientDocuments(patientId);
            return ResponseEntity.ok(documents);
        } catch (Exception e) {
            log.error("Error fetching patient documents", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch documents: " + e.getMessage()));
        }
    }

    /**
     * GET /api/patients/{patientId}/summary
     * Get patient summary with latest vitals (convenience endpoint)
     */
    @GetMapping("/patients/{patientId}/summary")
    public ResponseEntity<?> getPatientSummary(@PathVariable Long patientId) {
        try {
            PatientSummaryDTO patient = patientService.getPatientSummary(patientId);
            return ResponseEntity.ok(patient);
        } catch (RuntimeException e) {
            log.error("Error fetching patient summary", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error fetching patient summary", e);
            return ResponseEntity.status(500).body(createErrorResponse("Failed to fetch patient summary"));
        }
    }

    private Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        return response;
    }
}
