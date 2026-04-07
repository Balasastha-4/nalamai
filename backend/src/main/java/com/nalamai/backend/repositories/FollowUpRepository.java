package com.nalamai.backend.repositories;

import com.nalamai.backend.models.FollowUp;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FollowUpRepository extends JpaRepository<FollowUp, Long> {

    List<FollowUp> findByPatientOrderByScheduledDateDesc(User patient);

    List<FollowUp> findByPatientAndStatus(User patient, String status);

    List<FollowUp> findByPatientAndFollowUpType(User patient, String followUpType);

    List<FollowUp> findByStatus(String status);

    @Query("SELECT f FROM FollowUp f WHERE f.patient.id = :patientId ORDER BY f.scheduledDate DESC")
    List<FollowUp> findByPatientId(@Param("patientId") Long patientId);

    @Query("SELECT f FROM FollowUp f WHERE f.patient.id = :patientId AND f.status = 'PENDING'")
    List<FollowUp> findPendingByPatientId(@Param("patientId") Long patientId);

    @Query("SELECT f FROM FollowUp f WHERE f.status = 'PENDING' AND f.scheduledDate <= :now")
    List<FollowUp> findDueFollowUps(@Param("now") LocalDateTime now);

    @Query("SELECT f FROM FollowUp f WHERE f.status = 'SENT' AND f.respondedDate IS NULL AND f.sentDate < :cutoff")
    List<FollowUp> findOverdueResponses(@Param("cutoff") LocalDateTime cutoff);

    @Query("SELECT f FROM FollowUp f WHERE f.preventionPlan.id = :planId")
    List<FollowUp> findByPreventionPlanId(@Param("planId") Long planId);

    @Query("SELECT f FROM FollowUp f WHERE f.appointment.id = :appointmentId")
    List<FollowUp> findByAppointmentId(@Param("appointmentId") Long appointmentId);

    @Query("SELECT AVG(f.adherenceScore) FROM FollowUp f WHERE f.patient.id = :patientId AND f.adherenceScore IS NOT NULL")
    Double calculateAverageAdherence(@Param("patientId") Long patientId);

    @Query("SELECT COUNT(f) FROM FollowUp f WHERE f.patient.id = :patientId AND f.taskCompleted = true")
    Long countCompletedTasks(@Param("patientId") Long patientId);

    @Query("SELECT COUNT(f) FROM FollowUp f WHERE f.patient.id = :patientId")
    Long countTotalTasks(@Param("patientId") Long patientId);
}
