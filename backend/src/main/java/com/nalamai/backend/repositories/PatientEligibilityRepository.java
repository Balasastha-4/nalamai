package com.nalamai.backend.repositories;

import com.nalamai.backend.models.PatientEligibility;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PatientEligibilityRepository extends JpaRepository<PatientEligibility, Long> {

    List<PatientEligibility> findByPatient(User patient);

    Optional<PatientEligibility> findByPatientAndProgramType(User patient, String programType);

    List<PatientEligibility> findByProgramType(String programType);

    List<PatientEligibility> findByIsEligibleAndProgramType(Boolean isEligible, String programType);

    @Query("SELECT e FROM PatientEligibility e WHERE e.patient.id = :patientId")
    List<PatientEligibility> findByPatientId(@Param("patientId") Long patientId);

    @Query("SELECT e FROM PatientEligibility e WHERE e.patient.id = :patientId AND e.programType = :programType")
    Optional<PatientEligibility> findByPatientIdAndProgramType(@Param("patientId") Long patientId, @Param("programType") String programType);

    @Query("SELECT e FROM PatientEligibility e WHERE e.isEligible = true AND e.eligibilityStatus = 'ELIGIBLE' AND e.programType = :programType")
    List<PatientEligibility> findEligiblePatients(@Param("programType") String programType);

    @Query("SELECT e FROM PatientEligibility e WHERE e.priorityOutreach = true AND e.isEligible = true")
    List<PatientEligibility> findPriorityPatients();

    @Query("SELECT e FROM PatientEligibility e WHERE e.nextEligibleDate <= :date AND e.isEligible = false")
    List<PatientEligibility> findUpcomingEligible(@Param("date") LocalDateTime date);

    @Query("SELECT e FROM PatientEligibility e WHERE e.riskCategory = 'HIGH' AND e.isEligible = true")
    List<PatientEligibility> findHighRiskEligible();

    @Query("SELECT COUNT(e) FROM PatientEligibility e WHERE e.isEligible = true AND e.programType = :programType")
    Long countEligibleByProgram(@Param("programType") String programType);
}
