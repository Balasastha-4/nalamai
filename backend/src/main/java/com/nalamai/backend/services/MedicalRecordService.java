package com.nalamai.backend.services;

import com.nalamai.backend.dtos.CreateMedicalRecordRequest;
import com.nalamai.backend.dtos.MedicalRecordDTO;
import com.nalamai.backend.models.MedicalRecord;
import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.MedicalRecordRepository;
import com.nalamai.backend.repositories.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@Transactional
public class MedicalRecordService {

    @Autowired
    private MedicalRecordRepository medicalRecordRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Get all medical records for a patient, ordered by date descending
     */
    public List<MedicalRecordDTO> getPatientRecords(Long patientId) {
        List<MedicalRecord> records = medicalRecordRepository.findByPatientId(patientId);

        return records.stream()
                .sorted((r1, r2) -> r2.getRecordDate().compareTo(r1.getRecordDate())) // Descending order
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Create a new medical record
     */
    public MedicalRecordDTO createMedicalRecord(CreateMedicalRecordRequest request) {
        User patient = userRepository.findById(request.getPatientId())
                .orElseThrow(() -> new RuntimeException("Patient not found with ID: " + request.getPatientId()));

        MedicalRecord record = new MedicalRecord();
        record.setPatient(patient);
        record.setDiagnosis(request.getDiagnosis());
        record.setPrescription(request.getPrescription());
        record.setNotes(request.getNotes());
        record.setRecordDate(LocalDateTime.now());

        // Set doctor if provided
        if (request.getDoctorId() != null) {
            User doctor = userRepository.findById(request.getDoctorId())
                    .orElseThrow(() -> new RuntimeException("Doctor not found with ID: " + request.getDoctorId()));
            record.setDoctor(doctor);
        }

        MedicalRecord savedRecord = medicalRecordRepository.save(record);
        log.info("Medical record created: ID={}, Patient={}, Diagnosis={}",
                savedRecord.getId(), patient.getId(), request.getDiagnosis());

        return convertToDTO(savedRecord);
    }

    /**
     * Update a medical record
     */
    public MedicalRecordDTO updateMedicalRecord(Long recordId, CreateMedicalRecordRequest request) {
        MedicalRecord record = medicalRecordRepository.findById(recordId)
                .orElseThrow(() -> new RuntimeException("Medical record not found with ID: " + recordId));

        if (request.getDiagnosis() != null) {
            record.setDiagnosis(request.getDiagnosis());
        }

        if (request.getPrescription() != null) {
            record.setPrescription(request.getPrescription());
        }

        if (request.getNotes() != null) {
            record.setNotes(request.getNotes());
        }

        MedicalRecord updatedRecord = medicalRecordRepository.save(record);
        log.info("Medical record updated: ID={}", recordId);

        return convertToDTO(updatedRecord);
    }

    /**
     * Delete a medical record
     */
    public void deleteMedicalRecord(Long recordId) {
        MedicalRecord record = medicalRecordRepository.findById(recordId)
                .orElseThrow(() -> new RuntimeException("Medical record not found with ID: " + recordId));

        medicalRecordRepository.delete(record);
        log.info("Medical record deleted: ID={}", recordId);
    }

    /**
     * Convert MedicalRecord entity to DTO
     */
    private MedicalRecordDTO convertToDTO(MedicalRecord record) {
        return MedicalRecordDTO.builder()
                .id(record.getId())
                .patientId(record.getPatient().getId())
                .patientName(record.getPatient().getName())
                .doctorId(record.getDoctor() != null ? record.getDoctor().getId() : null)
                .doctorName(record.getDoctor() != null ? record.getDoctor().getName() : null)
                .doctorSpecialty(record.getDoctor() != null && record.getDoctor().getDoctorProfile() != null
                        ? record.getDoctor().getDoctorProfile().getSpecialty() : null)
                .diagnosis(record.getDiagnosis())
                .prescription(record.getPrescription())
                .notes(record.getNotes())
                .recordDate(record.getRecordDate())
                .build();
    }
}
