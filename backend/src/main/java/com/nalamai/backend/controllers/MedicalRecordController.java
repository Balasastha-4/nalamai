package com.nalamai.backend.controllers;

import com.nalamai.backend.dtos.CreateMedicalRecordRequest;
import com.nalamai.backend.dtos.MedicalRecordDTO;
import com.nalamai.backend.services.MedicalRecordService;
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
@RequestMapping("/api/records")
public class MedicalRecordController {

    @Autowired
    private MedicalRecordService medicalRecordService;

    /**
     * GET /api/records/patient/{patientId}
     * Get all medical records for a patient, ordered by date descending
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getPatientRecords(@PathVariable Long patientId) {
        try {
            List<MedicalRecordDTO> records = medicalRecordService.getPatientRecords(patientId);
            return ResponseEntity.ok(records);
        } catch (Exception e) {
            log.error("Error fetching patient medical records", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch medical records: " + e.getMessage()));
        }
    }

    /**
     * POST /api/records
     * Create a new medical record
     */
    @PostMapping
    public ResponseEntity<?> createMedicalRecord(@Valid @RequestBody CreateMedicalRecordRequest request) {
        try {
            MedicalRecordDTO record = medicalRecordService.createMedicalRecord(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(record);
        } catch (RuntimeException e) {
            log.error("Error creating medical record", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error creating medical record", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to create medical record"));
        }
    }

    /**
     * PUT /api/records/{recordId}
     * Update an existing medical record
     */
    @PutMapping("/{recordId}")
    public ResponseEntity<?> updateMedicalRecord(
            @PathVariable Long recordId,
            @RequestBody CreateMedicalRecordRequest request) {
        try {
            MedicalRecordDTO record = medicalRecordService.updateMedicalRecord(recordId, request);
            return ResponseEntity.ok(record);
        } catch (RuntimeException e) {
            log.error("Error updating medical record", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error updating medical record", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to update medical record"));
        }
    }

    /**
     * DELETE /api/records/{recordId}
     * Delete a medical record
     */
    @DeleteMapping("/{recordId}")
    public ResponseEntity<?> deleteMedicalRecord(@PathVariable Long recordId) {
        try {
            medicalRecordService.deleteMedicalRecord(recordId);
            return ResponseEntity.ok(createSuccessResponse("Medical record deleted successfully"));
        } catch (RuntimeException e) {
            log.error("Error deleting medical record", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error deleting medical record", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to delete medical record"));
        }
    }

    private Map<String, Object> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        return response;
    }

    private Map<String, Object> createSuccessResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", message);
        return response;
    }
}
