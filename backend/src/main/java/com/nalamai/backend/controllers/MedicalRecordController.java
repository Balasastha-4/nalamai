package com.nalamai.backend.controllers;

import com.nalamai.backend.models.MedicalRecord;
import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.MedicalRecordRepository;
import com.nalamai.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/records")
public class MedicalRecordController {

    @Autowired
    private MedicalRecordRepository medicalRecordRepository;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<MedicalRecord>> getPatientRecords(@PathVariable Long patientId) {
        return ResponseEntity.ok(medicalRecordRepository.findByPatientId(patientId));
    }

    @PostMapping("/")
    public ResponseEntity<?> createMedicalRecord(@RequestBody Map<String, Object> payload) {
        try {
            Long patientId = Long.valueOf(payload.get("patient_id").toString());
            Optional<User> patientOpt = userRepository.findById(patientId);

            if (patientOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Patient not found.");
            }

            MedicalRecord record = new MedicalRecord();
            record.setPatient(patientOpt.get());
            
            if (payload.containsKey("doctor_id")) {
                Long doctorId = Long.valueOf(payload.get("doctor_id").toString());
                userRepository.findById(doctorId).ifPresent(record::setDoctor);
            }

            record.setDiagnosis(payload.get("diagnosis").toString());
            
            if (payload.containsKey("prescription")) {
                record.setPrescription(payload.get("prescription").toString());
            }
            if (payload.containsKey("notes")) {
                record.setNotes(payload.get("notes").toString());
            }
            
            record.setRecordDate(LocalDateTime.now());

            return ResponseEntity.ok(medicalRecordRepository.save(record));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Invalid medical record data: " + e.getMessage());
        }
    }
}
