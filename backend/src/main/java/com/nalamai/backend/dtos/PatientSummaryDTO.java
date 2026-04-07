package com.nalamai.backend.dtos;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PatientSummaryDTO {

    private Long id;
    private String name;
    private String email;
    private String phone;
    private String address;
    private LocalDate dateOfBirth;
    private String profilePictureUrl;
    private VitalDTO latestHeartRate;
    private VitalDTO latestBloodPressure;
    private VitalDTO latestSpO2;
    private VitalDTO latestTemperature;
    private VitalDTO latestWeight;
    private String bloodGroup;
    private String allergies;
}
