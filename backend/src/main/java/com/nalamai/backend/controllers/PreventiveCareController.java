package com.nalamai.backend.controllers;

import com.nalamai.backend.models.*;
import com.nalamai.backend.repositories.*;
import com.nalamai.backend.services.PreventiveCareService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Controller for Preventive Healthcare Agentic AI endpoints.
 * Provides data for the AI agents to perform intelligent healthcare automation.
 */
@RestController
@RequestMapping("/api/preventive")
@CrossOrigin(origins = "*")
public class PreventiveCareController {

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

    @Autowired
    private PreventiveCareService preventiveCareService;

    // ============ ELIGIBILITY ENDPOINTS ============

    @GetMapping("/eligibility/{patientId}")
    public ResponseEntity<?> getPatientEligibility(@PathVariable Long patientId) {
        try {
            List<PatientEligibility> eligibility = eligibilityRepository.findByPatientId(patientId);
            if (eligibility.isEmpty()) {
                // Calculate eligibility if not exists
                Map<String, Object> calculated = preventiveCareService.calculateEligibility(patientId);
                return ResponseEntity.ok(calculated);
            }
            return ResponseEntity.ok(eligibility);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/eligibility/{patientId}/{programType}")
    public ResponseEntity<?> getEligibilityByProgram(
            @PathVariable Long patientId,
            @PathVariable String programType) {
        try {
            Optional<PatientEligibility> eligibility = eligibilityRepository.findByPatientIdAndProgramType(patientId, programType);
            if (eligibility.isPresent()) {
                return ResponseEntity.ok(eligibility.get());
            }
            // Calculate if not found
            Map<String, Object> calculated = preventiveCareService.calculateProgramEligibility(patientId, programType);
            return ResponseEntity.ok(calculated);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/eligibility/eligible/{programType}")
    public ResponseEntity<?> getEligiblePatients(@PathVariable String programType) {
        try {
            List<PatientEligibility> eligible = eligibilityRepository.findEligiblePatients(programType);
            return ResponseEntity.ok(Map.of(
                "programType", programType,
                "count", eligible.size(),
                "patients", eligible
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/eligibility/priority")
    public ResponseEntity<?> getPriorityPatients() {
        try {
            List<PatientEligibility> priority = eligibilityRepository.findPriorityPatients();
            return ResponseEntity.ok(priority);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/eligibility/calculate/{patientId}")
    public ResponseEntity<?> calculateAndSaveEligibility(@PathVariable Long patientId) {
        try {
            Map<String, Object> result = preventiveCareService.calculateAndSaveEligibility(patientId);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ============ HRA ENDPOINTS ============

    @GetMapping("/hra/{patientId}")
    public ResponseEntity<?> getPatientHRA(@PathVariable Long patientId) {
        try {
            List<HealthRiskAssessment> hras = hraRepository.findByPatientId(patientId);
            return ResponseEntity.ok(hras);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/hra/{patientId}/latest")
    public ResponseEntity<?> getLatestHRA(@PathVariable Long patientId) {
        try {
            Optional<User> patient = userRepository.findById(patientId);
            if (patient.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            Optional<HealthRiskAssessment> hra = hraRepository.findFirstByPatientOrderByCreatedAtDesc(patient.get());
            return hra.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/hra")
    public ResponseEntity<?> submitHRA(@RequestBody Map<String, Object> hraData) {
        try {
            Long patientId = Long.valueOf(hraData.get("patientId").toString());
            Optional<User> patient = userRepository.findById(patientId);
            if (patient.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Patient not found"));
            }

            HealthRiskAssessment hra = new HealthRiskAssessment();
            hra.setPatient(patient.get());
            hra.setStatus("SUBMITTED");
            hra.setAssessmentDate(LocalDateTime.now());

            // Set lifestyle factors
            if (hraData.containsKey("isSmoker")) {
                hra.setIsSmoker((Boolean) hraData.get("isSmoker"));
            }
            if (hraData.containsKey("consumesAlcohol")) {
                hra.setConsumesAlcohol((Boolean) hraData.get("consumesAlcohol"));
            }
            if (hraData.containsKey("exerciseFrequency")) {
                hra.setExerciseFrequency((String) hraData.get("exerciseFrequency"));
            }
            if (hraData.containsKey("dietQuality")) {
                hra.setDietQuality((String) hraData.get("dietQuality"));
            }

            // Set health history
            if (hraData.containsKey("familyHistory")) {
                hra.setFamilyHistory(hraData.get("familyHistory").toString());
            }
            if (hraData.containsKey("personalHistory")) {
                hra.setPersonalHistory(hraData.get("personalHistory").toString());
            }
            if (hraData.containsKey("currentMedications")) {
                hra.setCurrentMedications(hraData.get("currentMedications").toString());
            }
            if (hraData.containsKey("allergies")) {
                hra.setAllergies(hraData.get("allergies").toString());
            }

            // Set biometrics
            if (hraData.containsKey("height")) {
                hra.setHeight(Double.valueOf(hraData.get("height").toString()));
            }
            if (hraData.containsKey("weight")) {
                hra.setWeight(Double.valueOf(hraData.get("weight").toString()));
            }
            if (hraData.containsKey("systolicBP")) {
                hra.setSystolicBP(Integer.valueOf(hraData.get("systolicBP").toString()));
            }
            if (hraData.containsKey("diastolicBP")) {
                hra.setDiastolicBP(Integer.valueOf(hraData.get("diastolicBP").toString()));
            }

            // Calculate BMI if height and weight provided
            if (hra.getHeight() != null && hra.getWeight() != null) {
                double heightM = hra.getHeight() / 100.0;
                double bmi = hra.getWeight() / (heightM * heightM);
                hra.setBmi(Math.round(bmi * 10.0) / 10.0);
            }

            HealthRiskAssessment saved = hraRepository.save(hra);

            // Trigger AI risk calculation
            preventiveCareService.calculateRiskScores(saved.getId());

            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/hra/{hraId}/validate")
    public ResponseEntity<?> validateHRA(@PathVariable Long hraId, @RequestBody Map<String, Object> validationData) {
        try {
            Optional<HealthRiskAssessment> hraOpt = hraRepository.findById(hraId);
            if (hraOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }

            HealthRiskAssessment hra = hraOpt.get();
            hra.setStatus("VALIDATED");
            hra.setValidatedDate(LocalDateTime.now());

            if (validationData.containsKey("flags")) {
                hra.setFlags(validationData.get("flags").toString());
                if (!validationData.get("flags").toString().equals("[]")) {
                    hra.setStatus("FLAGGED");
                }
            }

            if (validationData.containsKey("aiInsights")) {
                hra.setAiInsights(validationData.get("aiInsights").toString());
            }

            HealthRiskAssessment saved = hraRepository.save(hra);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/hra/pending-validation")
    public ResponseEntity<?> getPendingValidation() {
        try {
            List<HealthRiskAssessment> pending = hraRepository.findPendingValidation();
            return ResponseEntity.ok(pending);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/hra/high-risk")
    public ResponseEntity<?> getHighRiskPatients(@RequestParam(defaultValue = "70") Integer threshold) {
        try {
            List<HealthRiskAssessment> highRisk = hraRepository.findHighRiskPatients(threshold);
            return ResponseEntity.ok(highRisk);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ============ PREVENTION PLAN ENDPOINTS ============

    @GetMapping("/plans/{patientId}")
    public ResponseEntity<?> getPatientPlans(@PathVariable Long patientId) {
        try {
            List<PreventionPlan> plans = preventionPlanRepository.findByPatientId(patientId);
            return ResponseEntity.ok(plans);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/plans/{patientId}/active")
    public ResponseEntity<?> getActivePlan(@PathVariable Long patientId) {
        try {
            Optional<PreventionPlan> plan = preventionPlanRepository.findActiveByPatientId(patientId);
            return plan.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/plans")
    public ResponseEntity<?> createPreventionPlan(@RequestBody Map<String, Object> planData) {
        try {
            Long patientId = Long.valueOf(planData.get("patientId").toString());
            Optional<User> patient = userRepository.findById(patientId);
            if (patient.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Patient not found"));
            }

            PreventionPlan plan = new PreventionPlan();
            plan.setPatient(patient.get());
            plan.setStatus("DRAFT");
            plan.setPlanType(planData.getOrDefault("planType", "ANNUAL_WELLNESS").toString());
            plan.setStartDate(LocalDateTime.now());
            plan.setEndDate(LocalDateTime.now().plusYears(1));

            if (planData.containsKey("doctorId")) {
                Long doctorId = Long.valueOf(planData.get("doctorId").toString());
                userRepository.findById(doctorId).ifPresent(plan::setDoctor);
            }

            if (planData.containsKey("hraId")) {
                Long hraId = Long.valueOf(planData.get("hraId").toString());
                hraRepository.findById(hraId).ifPresent(plan::setHra);
            }

            // Set plan content
            if (planData.containsKey("healthGoals")) {
                plan.setHealthGoals(planData.get("healthGoals").toString());
            }
            if (planData.containsKey("preventiveMeasures")) {
                plan.setPreventiveMeasures(planData.get("preventiveMeasures").toString());
            }
            if (planData.containsKey("recommendedScreenings")) {
                plan.setRecommendedScreenings(planData.get("recommendedScreenings").toString());
            }
            if (planData.containsKey("lifestyleRecommendations")) {
                plan.setLifestyleRecommendations(planData.get("lifestyleRecommendations").toString());
            }
            if (planData.containsKey("medicationPlan")) {
                plan.setMedicationPlan(planData.get("medicationPlan").toString());
            }
            if (planData.containsKey("specialistReferrals")) {
                plan.setSpecialistReferrals(planData.get("specialistReferrals").toString());
            }

            // AI-generated flag
            if (planData.containsKey("aiGenerated")) {
                plan.setAiGenerated((Boolean) planData.get("aiGenerated"));
            }
            if (planData.containsKey("aiRecommendations")) {
                plan.setAiRecommendations(planData.get("aiRecommendations").toString());
            }

            plan.setCompletionPercentage(0);
            plan.setProviderApproved(false);

            PreventionPlan saved = preventionPlanRepository.save(plan);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/plans/{planId}/approve")
    public ResponseEntity<?> approvePlan(@PathVariable Long planId) {
        try {
            Optional<PreventionPlan> planOpt = preventionPlanRepository.findById(planId);
            if (planOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }

            PreventionPlan plan = planOpt.get();
            plan.setProviderApproved(true);
            plan.setApprovedDate(LocalDateTime.now());
            plan.setStatus("ACTIVE");

            PreventionPlan saved = preventionPlanRepository.save(plan);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/plans/{planId}/progress")
    public ResponseEntity<?> updatePlanProgress(@PathVariable Long planId, @RequestBody Map<String, Object> progressData) {
        try {
            Optional<PreventionPlan> planOpt = preventionPlanRepository.findById(planId);
            if (planOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }

            PreventionPlan plan = planOpt.get();
            if (progressData.containsKey("completionPercentage")) {
                plan.setCompletionPercentage(Integer.valueOf(progressData.get("completionPercentage").toString()));
            }
            if (progressData.containsKey("progressNotes")) {
                plan.setProgressNotes(progressData.get("progressNotes").toString());
            }
            if (plan.getCompletionPercentage() >= 100) {
                plan.setStatus("COMPLETED");
            }

            PreventionPlan saved = preventionPlanRepository.save(plan);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/plans/pending-approval")
    public ResponseEntity<?> getPendingApproval() {
        try {
            List<PreventionPlan> pending = preventionPlanRepository.findPendingApproval();
            return ResponseEntity.ok(pending);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ============ FOLLOW-UP ENDPOINTS ============

    @GetMapping("/followups/{patientId}")
    public ResponseEntity<?> getPatientFollowUps(@PathVariable Long patientId) {
        try {
            List<FollowUp> followUps = followUpRepository.findByPatientId(patientId);
            return ResponseEntity.ok(followUps);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/followups/{patientId}/pending")
    public ResponseEntity<?> getPendingFollowUps(@PathVariable Long patientId) {
        try {
            List<FollowUp> pending = followUpRepository.findPendingByPatientId(patientId);
            return ResponseEntity.ok(pending);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/followups")
    public ResponseEntity<?> createFollowUp(@RequestBody Map<String, Object> followUpData) {
        try {
            Long patientId = Long.valueOf(followUpData.get("patientId").toString());
            Optional<User> patient = userRepository.findById(patientId);
            if (patient.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Patient not found"));
            }

            FollowUp followUp = new FollowUp();
            followUp.setPatient(patient.get());
            followUp.setFollowUpType(followUpData.getOrDefault("followUpType", "APPOINTMENT").toString());
            followUp.setStatus("PENDING");
            followUp.setScheduledDate(LocalDateTime.now().plusDays(1));
            followUp.setChannel(followUpData.getOrDefault("channel", "IN_APP").toString());
            followUp.setAttemptCount(0);
            followUp.setMaxAttempts(3);

            if (followUpData.containsKey("message")) {
                followUp.setMessage(followUpData.get("message").toString());
            }
            if (followUpData.containsKey("scheduledDate")) {
                followUp.setScheduledDate(LocalDateTime.parse(followUpData.get("scheduledDate").toString()));
            }
            if (followUpData.containsKey("preventionPlanId")) {
                Long planId = Long.valueOf(followUpData.get("preventionPlanId").toString());
                preventionPlanRepository.findById(planId).ifPresent(followUp::setPreventionPlan);
            }
            if (followUpData.containsKey("appointmentId")) {
                Long appointmentId = Long.valueOf(followUpData.get("appointmentId").toString());
                appointmentRepository.findById(appointmentId).ifPresent(followUp::setAppointment);
            }

            FollowUp saved = followUpRepository.save(followUp);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/followups/{followUpId}/respond")
    public ResponseEntity<?> respondToFollowUp(@PathVariable Long followUpId, @RequestBody Map<String, Object> responseData) {
        try {
            Optional<FollowUp> followUpOpt = followUpRepository.findById(followUpId);
            if (followUpOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }

            FollowUp followUp = followUpOpt.get();
            followUp.setStatus("ACKNOWLEDGED");
            followUp.setRespondedDate(LocalDateTime.now());

            if (responseData.containsKey("patientResponse")) {
                followUp.setPatientResponse(responseData.get("patientResponse").toString());
            }
            if (responseData.containsKey("taskCompleted")) {
                followUp.setTaskCompleted((Boolean) responseData.get("taskCompleted"));
                if ((Boolean) responseData.get("taskCompleted")) {
                    followUp.setStatus("COMPLETED");
                }
            }
            if (responseData.containsKey("feedback")) {
                followUp.setFeedback(responseData.get("feedback").toString());
            }
            if (responseData.containsKey("adherenceScore")) {
                followUp.setAdherenceScore(Integer.valueOf(responseData.get("adherenceScore").toString()));
            }

            FollowUp saved = followUpRepository.save(followUp);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/followups/due")
    public ResponseEntity<?> getDueFollowUps() {
        try {
            List<FollowUp> due = followUpRepository.findDueFollowUps(LocalDateTime.now());
            return ResponseEntity.ok(due);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/followups/{patientId}/adherence")
    public ResponseEntity<?> getAdherenceStats(@PathVariable Long patientId) {
        try {
            Double avgAdherence = followUpRepository.calculateAverageAdherence(patientId);
            Long completed = followUpRepository.countCompletedTasks(patientId);
            Long total = followUpRepository.countTotalTasks(patientId);

            return ResponseEntity.ok(Map.of(
                "patientId", patientId,
                "averageAdherenceScore", avgAdherence != null ? avgAdherence : 0,
                "completedTasks", completed,
                "totalTasks", total,
                "completionRate", total > 0 ? (completed * 100.0 / total) : 0
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ============ ANALYTICS ENDPOINTS ============

    @GetMapping("/analytics/patient/{patientId}")
    public ResponseEntity<?> getPatientAnalytics(@PathVariable Long patientId) {
        try {
            Map<String, Object> analytics = preventiveCareService.getPatientAnalytics(patientId);
            return ResponseEntity.ok(analytics);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/analytics/overview")
    public ResponseEntity<?> getOverviewAnalytics() {
        try {
            Map<String, Object> analytics = preventiveCareService.getOverviewAnalytics();
            return ResponseEntity.ok(analytics);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/noshow/predict/{patientId}")
    public ResponseEntity<?> predictNoShow(@PathVariable Long patientId) {
        try {
            Map<String, Object> prediction = preventiveCareService.predictNoShow(patientId);
            return ResponseEntity.ok(prediction);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/risk/assess/{patientId}")
    public ResponseEntity<?> assessRisk(@PathVariable Long patientId) {
        try {
            Map<String, Object> assessment = preventiveCareService.assessHealthRisk(patientId);
            return ResponseEntity.ok(assessment);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
