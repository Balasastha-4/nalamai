package com.nalamai.backend.services;

import com.nalamai.backend.dtos.*;
import com.nalamai.backend.models.*;
import com.nalamai.backend.repositories.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@Transactional
public class PatientService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VitalRepository vitalRepository;

    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private MedicalRecordRepository medicalRecordRepository;

    @Autowired
    private DocumentRepository documentRepository;

    @Autowired
    private UserProfileRepository userProfileRepository;

    /**
     * Get all patients for a doctor with their latest vitals
     */
    public List<PatientSummaryDTO> getDoctorPatients(Long doctorId) {
        // Get all appointments for the doctor to find patients
        List<Appointment> appointments = appointmentRepository.findByDoctorId(doctorId);

        Set<Long> patientIds = appointments.stream()
                .map(a -> a.getPatient().getId())
                .collect(Collectors.toSet());

        return patientIds.stream()
                .map(patientId -> userRepository.findById(patientId))
                .filter(Optional::isPresent)
                .map(Optional::get)
                .map(this::convertToPatientSummary)
                .collect(Collectors.toList());
    }

    /**
     * Get patient summary with latest vitals
     */
    public PatientSummaryDTO getPatientSummary(Long patientId) {
        User patient = userRepository.findById(patientId)
                .orElseThrow(() -> new RuntimeException("Patient not found with ID: " + patientId));

        return convertToPatientSummary(patient);
    }

    /**
     * Get complete patient details including profile, vitals, medical records, and documents
     */
    public PatientDetailDTO getPatientDetails(Long patientId) {
        User patient = userRepository.findById(patientId)
                .orElseThrow(() -> new RuntimeException("Patient not found with ID: " + patientId));

        UserProfile profile = userProfileRepository.findByUserId(patientId).orElse(null);

        // Get latest vitals by type
        List<String> vitalTypes = List.of("HeartRate", "BloodPressure", "SpO2", "Temperature", "Weight");
        Map<String, VitalDTO> latestVitals = new HashMap<>();

        for (String type : vitalTypes) {
            vitalRepository.findLatestByUserIdAndType(patientId, type)
                    .ifPresent(vital -> latestVitals.put(type, convertVitalToDTO(vital)));
        }

        // Get medical records
        List<MedicalRecordDTO> records = medicalRecordRepository.findByPatientId(patientId).stream()
                .map(this::convertMedicalRecordToDTO)
                .collect(Collectors.toList());

        // Get documents
        List<DocumentDTO> documents = documentRepository.findByUserId(patientId).stream()
                .map(this::convertDocumentToDTO)
                .collect(Collectors.toList());

        // Get upcoming appointments
        List<AppointmentDTO> appointments = appointmentRepository.findByPatientId(patientId).stream()
                .filter(a -> a.getStatus().equals("SCHEDULED"))
                .map(this::convertAppointmentToDTO)
                .collect(Collectors.toList());

        return PatientDetailDTO.builder()
                .id(patient.getId())
                .name(patient.getName())
                .email(patient.getEmail())
                .phone(patient.getPhone())
                .address(patient.getAddress())
                .dateOfBirth(patient.getDateOfBirth())
                .profilePictureUrl(patient.getProfilePictureUrl())
                .bloodGroup(profile != null ? profile.getBloodGroup() : null)
                .allergies(profile != null ? profile.getAllergies() : null)
                .medicalHistory(profile != null ? profile.getMedicalHistory() : null)
                .emergencyContactName(profile != null ? profile.getEmergencyContactName() : null)
                .emergencyContactPhone(profile != null ? profile.getEmergencyContactPhone() : null)
                .height(profile != null ? profile.getHeight() : null)
                .weight(profile != null ? profile.getWeight() : null)
                .latestVitals(latestVitals)
                .medicalRecords(records)
                .documents(documents)
                .upcomingAppointments(appointments)
                .build();
    }

    /**
     * Get patient vitals (delegates to VitalService)
     */
    public List<VitalDTO> getPatientVitals(Long patientId, String type, Integer days) {
        List<Vital> vitals;

        if (type != null && !type.isEmpty()) {
            vitals = vitalRepository.findByUserIdAndType(patientId, type);
        } else {
            vitals = vitalRepository.findByUserIdOrderByTimestampDesc(patientId);
        }

        int daysToFilter = days != null ? days : 30;
        java.time.LocalDateTime cutoffDate = java.time.LocalDateTime.now().minusDays(daysToFilter);

        return vitals.stream()
                .filter(v -> v.getTimestamp().isAfter(cutoffDate))
                .sorted((v1, v2) -> v2.getTimestamp().compareTo(v1.getTimestamp()))
                .map(this::convertVitalToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get patient medical records
     */
    public List<MedicalRecordDTO> getPatientRecords(Long patientId) {
        return medicalRecordRepository.findByPatientId(patientId).stream()
                .sorted((r1, r2) -> r2.getRecordDate().compareTo(r1.getRecordDate()))
                .map(this::convertMedicalRecordToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get patient documents
     */
    public List<DocumentDTO> getPatientDocuments(Long patientId) {
        return documentRepository.findByUserIdOrderByUploadDateDesc(patientId).stream()
                .map(this::convertDocumentToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Convert User to PatientSummaryDTO with latest vitals
     */
    private PatientSummaryDTO convertToPatientSummary(User patient) {
        UserProfile profile = userProfileRepository.findByUserId(patient.getId()).orElse(null);

        PatientSummaryDTO.PatientSummaryDTOBuilder builder = PatientSummaryDTO.builder()
                .id(patient.getId())
                .name(patient.getName())
                .email(patient.getEmail())
                .phone(patient.getPhone())
                .address(patient.getAddress())
                .dateOfBirth(patient.getDateOfBirth())
                .profilePictureUrl(patient.getProfilePictureUrl());

        // Add latest vitals
        vitalRepository.findLatestByUserIdAndType(patient.getId(), "HeartRate")
                .ifPresent(v -> builder.latestHeartRate(convertVitalToDTO(v)));

        vitalRepository.findLatestByUserIdAndType(patient.getId(), "BloodPressure")
                .ifPresent(v -> builder.latestBloodPressure(convertVitalToDTO(v)));

        vitalRepository.findLatestByUserIdAndType(patient.getId(), "SpO2")
                .ifPresent(v -> builder.latestSpO2(convertVitalToDTO(v)));

        vitalRepository.findLatestByUserIdAndType(patient.getId(), "Temperature")
                .ifPresent(v -> builder.latestTemperature(convertVitalToDTO(v)));

        vitalRepository.findLatestByUserIdAndType(patient.getId(), "Weight")
                .ifPresent(v -> builder.latestWeight(convertVitalToDTO(v)));

        if (profile != null) {
            builder.bloodGroup(profile.getBloodGroup())
                    .allergies(profile.getAllergies());
        }

        return builder.build();
    }

    /**
     * Convert Vital to VitalDTO
     */
    private VitalDTO convertVitalToDTO(Vital vital) {
        return VitalDTO.builder()
                .id(vital.getId())
                .userId(vital.getUser().getId())
                .userName(vital.getUser().getName())
                .type(vital.getType())
                .value(vital.getValue())
                .unit(vital.getUnit())
                .isAlert(vital.getIsAlert())
                .timestamp(vital.getTimestamp())
                .createdAt(vital.getCreatedAt())
                .build();
    }

    /**
     * Convert MedicalRecord to MedicalRecordDTO
     */
    private MedicalRecordDTO convertMedicalRecordToDTO(MedicalRecord record) {
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

    /**
     * Convert Document to DocumentDTO
     */
    private DocumentDTO convertDocumentToDTO(Document document) {
        return DocumentDTO.builder()
                .id(document.getId())
                .userId(document.getUser().getId())
                .fileName(document.getFileName())
                .fileType(document.getFileType())
                .fileUrl(document.getFileUrl())
                .uploadDate(document.getUploadDate())
                .documentType(document.getDocumentType())
                .build();
    }

    /**
     * Convert Appointment to AppointmentDTO
     */
    private AppointmentDTO convertAppointmentToDTO(Appointment appointment) {
        return AppointmentDTO.builder()
                .id(appointment.getId())
                .patientId(appointment.getPatient().getId())
                .patientName(appointment.getPatient().getName())
                .patientEmail(appointment.getPatient().getEmail())
                .patientPhone(appointment.getPatient().getPhone())
                .doctorId(appointment.getDoctor().getId())
                .doctorName(appointment.getDoctor().getName())
                .doctorEmail(appointment.getDoctor().getEmail())
                .doctorSpecialty(appointment.getDoctor().getDoctorProfile() != null
                        ? appointment.getDoctor().getDoctorProfile().getSpecialty() : null)
                .appointmentTime(appointment.getAppointmentTime())
                .status(appointment.getStatus())
                .resourceId(appointment.getResource() != null ? appointment.getResource().getId() : null)
                .resourceName(appointment.getResource() != null ? appointment.getResource().getName() : null)
                .notes(appointment.getNotes())
                .build();
    }
}
