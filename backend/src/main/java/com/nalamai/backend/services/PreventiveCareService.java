package com.nalamai.backend.services;

import com.nalamai.backend.models.*;
import com.nalamai.backend.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Service for Preventive Healthcare operations.
 * Provides business logic for eligibility, risk assessment, and analytics.
 */
@Service
public class PreventiveCareService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private HealthRiskAssessmentRepository hraRepository;

    @Autowired
    private PreventionPlanRepository preventionPlanRepository;

    @Autowired
    private PatientEligibilityRepository eligibilityRepository;

    @Autowired
    private FollowUpRepository followUpRepository;

    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private VitalRepository vitalRepository;

    // ============ ELIGIBILITY METHODS ============

    public Map<String, Object> calculateEligibility(Long patientId) {
        Optional<User> patientOpt = userRepository.findById(patientId);
        if (patientOpt.isEmpty()) {
            return Map.of("error", "Patient not found");
        }

        User patient = patientOpt.get();
        Map<String, Object> result = new HashMap<>();
        result.put("patientId", patientId);
        result.put("patientName", patient.getName());

        List<Map<String, Object>> programs = new ArrayList<>();

        // Annual Wellness Visit eligibility
        programs.add(calculateProgramEligibility(patientId, "ANNUAL_WELLNESS"));

        // Preventive Screening eligibility
        programs.add(calculateProgramEligibility(patientId, "PREVENTIVE_SCREENING"));

        // Chronic Care Management eligibility
        programs.add(calculateProgramEligibility(patientId, "CHRONIC_CARE_MANAGEMENT"));

        result.put("programs", programs);
        return result;
    }

    public Map<String, Object> calculateProgramEligibility(Long patientId, String programType) {
        Optional<User> patientOpt = userRepository.findById(patientId);
        if (patientOpt.isEmpty()) {
            return Map.of("error", "Patient not found", "programType", programType);
        }

        User patient = patientOpt.get();
        Map<String, Object> result = new HashMap<>();
        result.put("programType", programType);
        result.put("patientId", patientId);

        // Calculate age
        int age = 0;
        if (patient.getDateOfBirth() != null) {
            age = Period.between(patient.getDateOfBirth(), LocalDate.now()).getYears();
        }
        result.put("age", age);

        // Check last appointment for this program type
        List<Appointment> appointments = appointmentRepository.findByPatientId(patientId);
        LocalDateTime lastCompleted = null;
        for (Appointment apt : appointments) {
            if ("COMPLETED".equals(apt.getStatus()) && apt.getAppointmentTime() != null) {
                if (lastCompleted == null || apt.getAppointmentTime().isAfter(lastCompleted)) {
                    lastCompleted = apt.getAppointmentTime();
                }
            }
        }
        result.put("lastCompletedDate", lastCompleted);

        boolean isEligible = false;
        String status = "NOT_ELIGIBLE";
        String reason = "";

        switch (programType) {
            case "ANNUAL_WELLNESS":
                // Eligible if 12+ months since last visit or never completed
                if (lastCompleted == null) {
                    isEligible = true;
                    status = "ELIGIBLE";
                    reason = "No previous wellness visit on record";
                } else {
                    long monthsSinceLastVisit = ChronoUnit.MONTHS.between(lastCompleted, LocalDateTime.now());
                    if (monthsSinceLastVisit >= 12) {
                        isEligible = true;
                        status = "ELIGIBLE";
                        reason = "More than 12 months since last wellness visit";
                    } else {
                        status = "RECENTLY_COMPLETED";
                        reason = String.format("Completed %d months ago. Eligible in %d months.", 
                            monthsSinceLastVisit, 12 - monthsSinceLastVisit);
                        result.put("nextEligibleDate", lastCompleted.plusMonths(12));
                    }
                }
                break;

            case "PREVENTIVE_SCREENING":
                // Age-based eligibility
                if (age >= 45) {
                    isEligible = true;
                    status = "ELIGIBLE";
                    reason = "Age-appropriate for preventive screenings";
                } else {
                    status = "NOT_ELIGIBLE";
                    reason = "Under recommended screening age";
                }
                break;

            case "CHRONIC_CARE_MANAGEMENT":
                // Check for chronic conditions (simplified - would normally check diagnoses)
                List<HealthRiskAssessment> hras = hraRepository.findByPatientId(patientId);
                boolean hasChronicCondition = false;
                for (HealthRiskAssessment hra : hras) {
                    if (hra.getOverallRisk() != null && hra.getOverallRisk() >= 60) {
                        hasChronicCondition = true;
                        break;
                    }
                }
                if (hasChronicCondition) {
                    isEligible = true;
                    status = "ELIGIBLE";
                    reason = "Patient has chronic condition indicators";
                } else {
                    status = "NOT_ELIGIBLE";
                    reason = "No chronic condition indicators found";
                }
                break;

            default:
                status = "UNKNOWN_PROGRAM";
                reason = "Unknown program type";
        }

        result.put("isEligible", isEligible);
        result.put("eligibilityStatus", status);
        result.put("reason", reason);
        result.put("calculatedDate", LocalDateTime.now());

        return result;
    }

    public Map<String, Object> calculateAndSaveEligibility(Long patientId) {
        Optional<User> patientOpt = userRepository.findById(patientId);
        if (patientOpt.isEmpty()) {
            return Map.of("error", "Patient not found");
        }

        User patient = patientOpt.get();
        List<PatientEligibility> savedEligibilities = new ArrayList<>();
        String[] programs = {"ANNUAL_WELLNESS", "PREVENTIVE_SCREENING", "CHRONIC_CARE_MANAGEMENT"};

        for (String program : programs) {
            Map<String, Object> calc = calculateProgramEligibility(patientId, program);

            PatientEligibility eligibility = eligibilityRepository
                .findByPatientIdAndProgramType(patientId, program)
                .orElse(new PatientEligibility());

            eligibility.setPatient(patient);
            eligibility.setProgramType(program);
            eligibility.setIsEligible((Boolean) calc.get("isEligible"));
            eligibility.setEligibilityStatus((String) calc.get("eligibilityStatus"));
            eligibility.setCalculatedDate(LocalDateTime.now());
            eligibility.setAgeYears((Integer) calc.get("age"));

            if (calc.get("lastCompletedDate") != null) {
                eligibility.setLastCompletedDate((LocalDateTime) calc.get("lastCompletedDate"));
            }
            if (calc.get("nextEligibleDate") != null) {
                eligibility.setNextEligibleDate((LocalDateTime) calc.get("nextEligibleDate"));
            }

            savedEligibilities.add(eligibilityRepository.save(eligibility));
        }

        return Map.of(
            "patientId", patientId,
            "eligibilities", savedEligibilities,
            "calculatedAt", LocalDateTime.now()
        );
    }

    // ============ RISK ASSESSMENT METHODS ============

    public void calculateRiskScores(Long hraId) {
        Optional<HealthRiskAssessment> hraOpt = hraRepository.findById(hraId);
        if (hraOpt.isEmpty()) return;

        HealthRiskAssessment hra = hraOpt.get();
        int cardiovascularRisk = 0;
        int diabetesRisk = 0;
        int overallRisk = 0;

        // BMI risk factor
        if (hra.getBmi() != null) {
            if (hra.getBmi() >= 30) {
                cardiovascularRisk += 20;
                diabetesRisk += 25;
            } else if (hra.getBmi() >= 25) {
                cardiovascularRisk += 10;
                diabetesRisk += 15;
            }
        }

        // Blood pressure risk
        if (hra.getSystolicBP() != null && hra.getDiastolicBP() != null) {
            if (hra.getSystolicBP() >= 140 || hra.getDiastolicBP() >= 90) {
                cardiovascularRisk += 30;
            } else if (hra.getSystolicBP() >= 130 || hra.getDiastolicBP() >= 80) {
                cardiovascularRisk += 15;
            }
        }

        // Lifestyle factors
        if (Boolean.TRUE.equals(hra.getIsSmoker())) {
            cardiovascularRisk += 25;
            overallRisk += 15;
        }
        if (Boolean.TRUE.equals(hra.getConsumesAlcohol())) {
            overallRisk += 10;
        }
        if ("NONE".equals(hra.getExerciseFrequency()) || "RARE".equals(hra.getExerciseFrequency())) {
            cardiovascularRisk += 15;
            diabetesRisk += 15;
        }
        if ("POOR".equals(hra.getDietQuality())) {
            diabetesRisk += 20;
            overallRisk += 10;
        }

        // Calculate overall risk
        overallRisk += (cardiovascularRisk + diabetesRisk) / 2;

        // Cap at 100
        hra.setCardiovascularRisk(Math.min(cardiovascularRisk, 100));
        hra.setDiabetesRisk(Math.min(diabetesRisk, 100));
        hra.setOverallRisk(Math.min(overallRisk, 100));

        hraRepository.save(hra);
    }

    public Map<String, Object> assessHealthRisk(Long patientId) {
        Optional<User> patientOpt = userRepository.findById(patientId);
        if (patientOpt.isEmpty()) {
            return Map.of("error", "Patient not found");
        }

        User patient = patientOpt.get();
        Map<String, Object> assessment = new HashMap<>();
        assessment.put("patientId", patientId);
        assessment.put("patientName", patient.getName());
        assessment.put("assessmentDate", LocalDateTime.now());

        // Get latest HRA
        Optional<HealthRiskAssessment> latestHra = hraRepository.findFirstByPatientOrderByCreatedAtDesc(patient);
        if (latestHra.isPresent()) {
            HealthRiskAssessment hra = latestHra.get();
            assessment.put("cardiovascularRisk", hra.getCardiovascularRisk());
            assessment.put("diabetesRisk", hra.getDiabetesRisk());
            assessment.put("overallRisk", hra.getOverallRisk());

            String riskLevel = "LOW";
            if (hra.getOverallRisk() != null) {
                if (hra.getOverallRisk() >= 70) riskLevel = "HIGH";
                else if (hra.getOverallRisk() >= 40) riskLevel = "MEDIUM";
            }
            assessment.put("riskLevel", riskLevel);
        } else {
            assessment.put("riskLevel", "UNKNOWN");
            assessment.put("message", "No health risk assessment on file");
        }

        // Get latest vitals
        List<Vital> vitals = vitalRepository.findByUserId(patientId);
        if (!vitals.isEmpty()) {
            Map<String, Object> vitalSummary = new HashMap<>();
            for (Vital vital : vitals) {
                String type = vital.getType() != null ? vital.getType() : "unknown";
                vitalSummary.put(type, Map.of(
                    "value", vital.getValue(),
                    "recordedAt", vital.getTimestamp()
                ));
            }
            assessment.put("latestVitals", vitalSummary);
        }

        // Generate recommendations
        List<String> recommendations = new ArrayList<>();
        if (latestHra.isPresent()) {
            HealthRiskAssessment hra = latestHra.get();
            if (hra.getCardiovascularRisk() != null && hra.getCardiovascularRisk() >= 50) {
                recommendations.add("Schedule cardiovascular screening");
                recommendations.add("Consider heart-healthy diet consultation");
            }
            if (hra.getDiabetesRisk() != null && hra.getDiabetesRisk() >= 50) {
                recommendations.add("Schedule glucose tolerance test");
                recommendations.add("Consider nutrition counseling");
            }
            if (Boolean.TRUE.equals(hra.getIsSmoker())) {
                recommendations.add("Smoking cessation program recommended");
            }
        }
        if (recommendations.isEmpty()) {
            recommendations.add("Continue regular health check-ups");
            recommendations.add("Maintain healthy lifestyle habits");
        }
        assessment.put("recommendations", recommendations);

        return assessment;
    }

    // ============ PREDICTION METHODS ============

    public Map<String, Object> predictNoShow(Long patientId) {
        Optional<User> patientOpt = userRepository.findById(patientId);
        if (patientOpt.isEmpty()) {
            return Map.of("error", "Patient not found");
        }

        User patient = patientOpt.get();
        Map<String, Object> prediction = new HashMap<>();
        prediction.put("patientId", patientId);
        prediction.put("patientName", patient.getName());
        prediction.put("predictionDate", LocalDateTime.now());

        // Get appointment history
        List<Appointment> appointments = appointmentRepository.findByPatientId(patientId);

        int totalAppointments = appointments.size();
        int completedAppointments = 0;
        int cancelledAppointments = 0;
        int noShowCount = 0;

        for (Appointment apt : appointments) {
            if ("COMPLETED".equals(apt.getStatus())) {
                completedAppointments++;
            } else if ("CANCELLED".equals(apt.getStatus())) {
                cancelledAppointments++;
            } else if ("NO_SHOW".equals(apt.getStatus())) {
                noShowCount++;
            }
        }

        prediction.put("totalAppointments", totalAppointments);
        prediction.put("completedAppointments", completedAppointments);
        prediction.put("cancelledAppointments", cancelledAppointments);
        prediction.put("noShowCount", noShowCount);

        // Calculate no-show probability
        double noShowProbability = 0.15; // Base probability
        if (totalAppointments > 0) {
            double historicalNoShowRate = (double) noShowCount / totalAppointments;
            noShowProbability = (noShowProbability + historicalNoShowRate) / 2;
        }

        // Adjust based on adherence
        Double avgAdherence = followUpRepository.calculateAverageAdherence(patientId);
        if (avgAdherence != null) {
            if (avgAdherence < 50) {
                noShowProbability += 0.2;
            } else if (avgAdherence >= 80) {
                noShowProbability -= 0.1;
            }
        }

        // Cap probability
        noShowProbability = Math.max(0, Math.min(1, noShowProbability));

        String riskCategory;
        if (noShowProbability >= 0.5) {
            riskCategory = "HIGH";
        } else if (noShowProbability >= 0.25) {
            riskCategory = "MEDIUM";
        } else {
            riskCategory = "LOW";
        }

        prediction.put("noShowProbability", Math.round(noShowProbability * 100) / 100.0);
        prediction.put("riskCategory", riskCategory);

        // Recommendations
        List<String> recommendations = new ArrayList<>();
        if (noShowProbability >= 0.4) {
            recommendations.add("Send multiple reminders before appointment");
            recommendations.add("Consider phone confirmation call");
            recommendations.add("Offer flexible rescheduling options");
        } else if (noShowProbability >= 0.2) {
            recommendations.add("Send standard appointment reminders");
        }
        prediction.put("recommendations", recommendations);

        return prediction;
    }

    // ============ ANALYTICS METHODS ============

    public Map<String, Object> getPatientAnalytics(Long patientId) {
        Optional<User> patientOpt = userRepository.findById(patientId);
        if (patientOpt.isEmpty()) {
            return Map.of("error", "Patient not found");
        }

        User patient = patientOpt.get();
        Map<String, Object> analytics = new HashMap<>();
        analytics.put("patientId", patientId);
        analytics.put("patientName", patient.getName());

        // Eligibility summary
        List<PatientEligibility> eligibilities = eligibilityRepository.findByPatientId(patientId);
        analytics.put("eligiblePrograms", eligibilities.stream()
            .filter(e -> Boolean.TRUE.equals(e.getIsEligible()))
            .count());

        // Risk assessment
        Map<String, Object> riskAssessment = assessHealthRisk(patientId);
        analytics.put("riskLevel", riskAssessment.get("riskLevel"));
        analytics.put("overallRisk", riskAssessment.get("overallRisk"));

        // No-show prediction
        Map<String, Object> noShowPrediction = predictNoShow(patientId);
        analytics.put("noShowRisk", noShowPrediction.get("riskCategory"));
        analytics.put("noShowProbability", noShowPrediction.get("noShowProbability"));

        // Adherence stats
        Double avgAdherence = followUpRepository.calculateAverageAdherence(patientId);
        Long completed = followUpRepository.countCompletedTasks(patientId);
        Long total = followUpRepository.countTotalTasks(patientId);
        analytics.put("adherenceScore", avgAdherence != null ? avgAdherence : 0);
        analytics.put("taskCompletionRate", total > 0 ? (completed * 100.0 / total) : 0);

        // Prevention plan status
        Optional<PreventionPlan> activePlan = preventionPlanRepository.findActiveByPatientId(patientId);
        if (activePlan.isPresent()) {
            analytics.put("hasActivePlan", true);
            analytics.put("planCompletion", activePlan.get().getCompletionPercentage());
        } else {
            analytics.put("hasActivePlan", false);
        }

        // Upcoming appointments
        List<Appointment> appointments = appointmentRepository.findByPatientId(patientId);
        long upcomingCount = appointments.stream()
            .filter(a -> "SCHEDULED".equals(a.getStatus()) && a.getAppointmentTime().isAfter(LocalDateTime.now()))
            .count();
        analytics.put("upcomingAppointments", upcomingCount);

        return analytics;
    }

    public Map<String, Object> getOverviewAnalytics() {
        Map<String, Object> analytics = new HashMap<>();
        analytics.put("generatedAt", LocalDateTime.now());

        // Total patients
        long totalPatients = userRepository.count();
        analytics.put("totalPatients", totalPatients);

        // Eligibility stats
        for (String program : Arrays.asList("ANNUAL_WELLNESS", "PREVENTIVE_SCREENING", "CHRONIC_CARE_MANAGEMENT")) {
            Long eligible = eligibilityRepository.countEligibleByProgram(program);
            analytics.put(program.toLowerCase() + "_eligible", eligible);
        }

        // High-risk patients
        List<HealthRiskAssessment> highRisk = hraRepository.findHighRiskPatients(70);
        analytics.put("highRiskPatients", highRisk.size());

        // Pending HRA validations
        List<HealthRiskAssessment> pendingValidation = hraRepository.findPendingValidation();
        analytics.put("pendingHraValidations", pendingValidation.size());

        // Pending plan approvals
        List<PreventionPlan> pendingApproval = preventionPlanRepository.findPendingApproval();
        analytics.put("pendingPlanApprovals", pendingApproval.size());

        // Due follow-ups
        List<FollowUp> dueFollowUps = followUpRepository.findDueFollowUps(LocalDateTime.now());
        analytics.put("dueFollowUps", dueFollowUps.size());

        // Priority outreach
        List<PatientEligibility> priorityPatients = eligibilityRepository.findPriorityPatients();
        analytics.put("priorityOutreachCount", priorityPatients.size());

        return analytics;
    }
}
