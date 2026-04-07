package com.nalamai.backend.dtos;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PatientDetailDTO {

    private Long id;
    private String name;
    private String email;
    private String phone;
    private String address;
    private LocalDate dateOfBirth;
    private String profilePictureUrl;
    private String bloodGroup;
    private String allergies;
    private String medicalHistory;
    private String emergencyContactName;
    private String emergencyContactPhone;
    private Double height; // in cm
    private Double weight; // in kg

    // Latest vitals
    private Map<String, VitalDTO> latestVitals; // type -> VitalDTO

    // Medical records list
    private List<MedicalRecordDTO> medicalRecords;

    // Documents list
    private List<DocumentDTO> documents;

    // Upcoming appointments
    private List<AppointmentDTO> upcomingAppointments;
}
