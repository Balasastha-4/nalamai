package com.nalamai.backend.controllers;

import com.nalamai.backend.dtos.AppointmentDTO;
import com.nalamai.backend.dtos.CreateAppointmentRequest;
import com.nalamai.backend.dtos.UpdateAppointmentRequest;
import com.nalamai.backend.services.AppointmentService;
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
@RequestMapping("/api/appointments")
public class AppointmentController {

    @Autowired
    private AppointmentService appointmentService;

    /**
     * GET /api/appointments/patient/{patientId}
     * Get all appointments for a patient with optional filtering
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getPatientAppointments(
            @PathVariable Long patientId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Integer offset) {
        try {
            List<AppointmentDTO> appointments = appointmentService.getPatientAppointments(patientId, status, limit, offset);
            return ResponseEntity.ok(appointments);
        } catch (Exception e) {
            log.error("Error fetching patient appointments", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch appointments: " + e.getMessage()));
        }
    }

    /**
     * GET /api/appointments/doctor/{doctorId}
     * Get all appointments for a doctor
     */
    @GetMapping("/doctor/{doctorId}")
    public ResponseEntity<?> getDoctorAppointments(@PathVariable Long doctorId) {
        try {
            List<AppointmentDTO> appointments = appointmentService.getDoctorAppointments(doctorId);
            return ResponseEntity.ok(appointments);
        } catch (Exception e) {
            log.error("Error fetching doctor appointments", e);
            return ResponseEntity.badRequest().body(createErrorResponse("Failed to fetch appointments: " + e.getMessage()));
        }
    }

    /**
     * POST /api/appointments
     * Create a new appointment
     */
    @PostMapping
    public ResponseEntity<?> createAppointment(@Valid @RequestBody CreateAppointmentRequest request) {
        try {
            AppointmentDTO appointment = appointmentService.createAppointment(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(appointment);
        } catch (RuntimeException e) {
            log.error("Error creating appointment", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error creating appointment", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to create appointment"));
        }
    }

    /**
     * PUT /api/appointments/{appointmentId}
     * Update an existing appointment
     */
    @PutMapping("/{appointmentId}")
    public ResponseEntity<?> updateAppointment(
            @PathVariable Long appointmentId,
            @RequestBody UpdateAppointmentRequest request) {
        try {
            AppointmentDTO appointment = appointmentService.updateAppointment(appointmentId, request);
            return ResponseEntity.ok(appointment);
        } catch (RuntimeException e) {
            log.error("Error updating appointment", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error updating appointment", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to update appointment"));
        }
    }

    /**
     * DELETE /api/appointments/{appointmentId}
     * Cancel/delete an appointment
     */
    @DeleteMapping("/{appointmentId}")
    public ResponseEntity<?> deleteAppointment(@PathVariable Long appointmentId) {
        try {
            appointmentService.deleteAppointment(appointmentId);
            return ResponseEntity.ok(createSuccessResponse("Appointment deleted successfully"));
        } catch (RuntimeException e) {
            log.error("Error deleting appointment", e);
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error deleting appointment", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(createErrorResponse("Failed to delete appointment"));
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
