package com.nalamai.backend.services;

import com.nalamai.backend.dtos.AppointmentDTO;
import com.nalamai.backend.dtos.CreateAppointmentRequest;
import com.nalamai.backend.dtos.UpdateAppointmentRequest;
import com.nalamai.backend.models.Appointment;
import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.AppointmentRepository;
import com.nalamai.backend.repositories.UserRepository;
import com.nalamai.backend.repositories.MedicalResourceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@Transactional
public class AppointmentService {

    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MedicalResourceRepository medicalResourceRepository;

    /**
     * Get appointments for a patient with optional filtering by status
     */
    public List<AppointmentDTO> getPatientAppointments(Long patientId, String status, Integer limit, Integer offset) {
        List<Appointment> appointments = appointmentRepository.findByPatientId(patientId);

        if (status != null && !status.isEmpty()) {
            appointments = appointments.stream()
                    .filter(a -> a.getStatus().equals(status))
                    .collect(Collectors.toList());
        }

        // Apply pagination
        int start = offset != null ? offset : 0;
        int end = limit != null ? Math.min(start + limit, appointments.size()) : appointments.size();

        return appointments.stream()
                .skip(start)
                .limit(limit != null ? limit : appointments.size())
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Get appointments for a doctor
     */
    public List<AppointmentDTO> getDoctorAppointments(Long doctorId) {
        List<Appointment> appointments = appointmentRepository.findByDoctorId(doctorId);

        return appointments.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Create a new appointment
     */
    public AppointmentDTO createAppointment(CreateAppointmentRequest request) {
        // Validate patient and doctor exist
        User patient = userRepository.findById(request.getPatientId())
                .orElseThrow(() -> new RuntimeException("Patient not found with ID: " + request.getPatientId()));

        User doctor = userRepository.findById(request.getDoctorId())
                .orElseThrow(() -> new RuntimeException("Doctor not found with ID: " + request.getDoctorId()));

        Appointment appointment = new Appointment();
        appointment.setPatient(patient);
        appointment.setDoctor(doctor);
        appointment.setAppointmentTime(request.getAppointmentTime());
        appointment.setStatus("SCHEDULED");
        appointment.setNotes(request.getNotes());

        if (request.getResourceId() != null) {
            appointment.setResource(medicalResourceRepository.findById(request.getResourceId()).orElse(null));
        }

        Appointment savedAppointment = appointmentRepository.save(appointment);
        log.info("Appointment created: ID={}, Patient={}, Doctor={}",
                savedAppointment.getId(), patient.getId(), doctor.getId());

        return convertToDTO(savedAppointment);
    }

    /**
     * Update an existing appointment
     */
    public AppointmentDTO updateAppointment(Long appointmentId, UpdateAppointmentRequest request) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new RuntimeException("Appointment not found with ID: " + appointmentId));

        if (request.getStatus() != null) {
            appointment.setStatus(request.getStatus());
        }

        if (request.getAppointmentTime() != null) {
            appointment.setAppointmentTime(request.getAppointmentTime());
        }

        if (request.getNotes() != null) {
            appointment.setNotes(request.getNotes());
        }

        Appointment updatedAppointment = appointmentRepository.save(appointment);
        log.info("Appointment updated: ID={}, Status={}", appointmentId, request.getStatus());

        return convertToDTO(updatedAppointment);
    }

    /**
     * Cancel (delete) an appointment
     */
    public void deleteAppointment(Long appointmentId) {
        Appointment appointment = appointmentRepository.findById(appointmentId)
                .orElseThrow(() -> new RuntimeException("Appointment not found with ID: " + appointmentId));

        appointmentRepository.delete(appointment);
        log.info("Appointment deleted: ID={}", appointmentId);
    }

    /**
     * Convert Appointment entity to DTO
     */
    private AppointmentDTO convertToDTO(Appointment appointment) {
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
