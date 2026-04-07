package com.nalamai.backend.repositories;

import com.nalamai.backend.models.PreventionPlan;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PreventionPlanRepository extends JpaRepository<PreventionPlan, Long> {

    List<PreventionPlan> findByPatientOrderByCreatedAtDesc(User patient);

    Optional<PreventionPlan> findFirstByPatientAndStatusOrderByCreatedAtDesc(User patient, String status);

    List<PreventionPlan> findByPatientAndStatus(User patient, String status);

    List<PreventionPlan> findByDoctorAndStatus(User doctor, String status);

    List<PreventionPlan> findByStatus(String status);

    @Query("SELECT p FROM PreventionPlan p WHERE p.patient.id = :patientId ORDER BY p.createdAt DESC")
    List<PreventionPlan> findByPatientId(@Param("patientId") Long patientId);

    @Query("SELECT p FROM PreventionPlan p WHERE p.patient.id = :patientId AND p.status = 'ACTIVE'")
    Optional<PreventionPlan> findActiveByPatientId(@Param("patientId") Long patientId);

    @Query("SELECT p FROM PreventionPlan p WHERE p.doctor.id = :doctorId AND p.status = 'ACTIVE'")
    List<PreventionPlan> findActiveByDoctorId(@Param("doctorId") Long doctorId);

    @Query("SELECT p FROM PreventionPlan p WHERE p.providerApproved = false AND p.aiGenerated = true")
    List<PreventionPlan> findPendingApproval();

    @Query("SELECT p FROM PreventionPlan p WHERE p.endDate < :date AND p.status = 'ACTIVE'")
    List<PreventionPlan> findExpiredPlans(@Param("date") LocalDateTime date);

    @Query("SELECT COUNT(p) FROM PreventionPlan p WHERE p.patient.id = :patientId AND p.status = 'COMPLETED'")
    Long countCompletedPlans(@Param("patientId") Long patientId);
}
