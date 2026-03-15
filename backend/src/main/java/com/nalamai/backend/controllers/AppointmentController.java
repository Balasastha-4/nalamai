package com.nalamai.backend.controllers;

import com.nalamai.backend.models.Appointment;
import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.AppointmentRepository;
import com.nalamai.backend.repositories.UserRepository;
import com.nalamai.backend.repositories.MedicalResourceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private MedicalResourceRepository medicalResourceRepository;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<Appointment>> getPatientAppointments(@PathVariable Long patientId) {
        return ResponseEntity.ok(appointmentRepository.findByPatientId(patientId));
    }

    @GetMapping("/doctor/{doctorId}")
    public ResponseEntity<List<Appointment>> getDoctorAppointments(@PathVariable Long doctorId) {
        return ResponseEntity.ok(appointmentRepository.findByDoctorId(doctorId));
    }

    @PostMapping("/")
    public ResponseEntity<?> createAppointment(@RequestBody Map<String, Object> payload) {
        try {
            Long patientId = Long.valueOf(payload.get("patient_id").toString());
            Long doctorId = Long.valueOf(payload.get("doctor_id").toString());
            
            Optional<User> patientOpt = userRepository.findById(patientId);
            Optional<User> doctorOpt = userRepository.findById(doctorId);

            if (patientOpt.isEmpty() || doctorOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Doctor or Patient not found.");
            }

            Appointment appointment = new Appointment();
            appointment.setPatient(patientOpt.get());
            appointment.setDoctor(doctorOpt.get());
            appointment.setStatus("SCHEDULED");
            appointment.setAppointmentTime(java.time.LocalDateTime.parse(payload.get("appointment_time").toString()));
            
            if (payload.containsKey("notes")) {
                appointment.setNotes(payload.get("notes").toString());
            }

            return ResponseEntity.ok(appointmentRepository.save(appointment));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Invalid appointment data: " + e.getMessage());
        }
    }
}
