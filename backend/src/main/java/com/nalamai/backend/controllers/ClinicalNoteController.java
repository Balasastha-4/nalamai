package com.nalamai.backend.controllers;

import com.nalamai.backend.models.ClinicalNote;
import com.nalamai.backend.models.User;
import com.nalamai.backend.repositories.ClinicalNoteRepository;
import com.nalamai.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/clinical-notes")
@CrossOrigin(origins = "*")
public class ClinicalNoteController {

    @Autowired
    private ClinicalNoteRepository clinicalNoteRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Get all clinical notes for a patient
     * GET /api/clinical-notes/patient/{patientId}
     */
    @GetMapping("/patient/{patientId}")
    public ResponseEntity<?> getPatientNotes(@PathVariable Long patientId) {
        try {
            List<ClinicalNote> notes = clinicalNoteRepository.findByPatientId(patientId);
            
            List<Map<String, Object>> result = notes.stream()
                    .map(this::noteToMap)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching notes: " + e.getMessage());
        }
    }

    /**
     * Get all clinical notes written by a doctor
     * GET /api/clinical-notes/doctor/{doctorId}
     */
    @GetMapping("/doctor/{doctorId}")
    public ResponseEntity<?> getDoctorNotes(@PathVariable Long doctorId) {
        try {
            List<ClinicalNote> notes = clinicalNoteRepository.findByDoctorId(doctorId);
            
            List<Map<String, Object>> result = notes.stream()
                    .map(this::noteToMap)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching notes: " + e.getMessage());
        }
    }

    /**
     * Get a specific clinical note
     * GET /api/clinical-notes/{noteId}
     */
    @GetMapping("/{noteId}")
    public ResponseEntity<?> getNoteById(@PathVariable Long noteId) {
        try {
            Optional<ClinicalNote> noteOpt = clinicalNoteRepository.findById(noteId);
            
            if (noteOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            return ResponseEntity.ok(noteToMap(noteOpt.get()));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching note: " + e.getMessage());
        }
    }

    /**
     * Create a new clinical note
     * POST /api/clinical-notes/
     */
    @PostMapping("/")
    public ResponseEntity<?> createNote(@RequestBody Map<String, Object> payload) {
        try {
            Long patientId = Long.valueOf(payload.get("patient_id").toString());
            Long doctorId = Long.valueOf(payload.get("doctor_id").toString());
            String noteText = payload.get("content").toString();
            String tag = payload.containsKey("tag") ? payload.get("tag").toString() : "Normal";
            
            Optional<User> patientOpt = userRepository.findById(patientId);
            Optional<User> doctorOpt = userRepository.findById(doctorId);
            
            if (patientOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Patient not found");
            }
            
            if (doctorOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Doctor not found");
            }
            
            ClinicalNote note = new ClinicalNote(patientOpt.get(), doctorOpt.get(), noteText, tag);
            ClinicalNote saved = clinicalNoteRepository.save(note);
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "id", saved.getId(),
                    "message", "Clinical note created successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error creating note: " + e.getMessage());
        }
    }

    /**
     * Update a clinical note
     * PUT /api/clinical-notes/{noteId}
     */
    @PutMapping("/{noteId}")
    public ResponseEntity<?> updateNote(
            @PathVariable Long noteId,
            @RequestBody Map<String, Object> payload) {
        try {
            Optional<ClinicalNote> noteOpt = clinicalNoteRepository.findById(noteId);
            
            if (noteOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            ClinicalNote note = noteOpt.get();
            
            if (payload.containsKey("content")) {
                note.setNoteText(payload.get("content").toString());
            }
            
            if (payload.containsKey("tag")) {
                note.setTag(payload.get("tag").toString());
            }
            
            ClinicalNote saved = clinicalNoteRepository.save(note);
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "id", saved.getId(),
                    "message", "Clinical note updated successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error updating note: " + e.getMessage());
        }
    }

    /**
     * Delete a clinical note
     * DELETE /api/clinical-notes/{noteId}
     */
    @DeleteMapping("/{noteId}")
    public ResponseEntity<?> deleteNote(@PathVariable Long noteId) {
        try {
            Optional<ClinicalNote> noteOpt = clinicalNoteRepository.findById(noteId);
            
            if (noteOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            clinicalNoteRepository.delete(noteOpt.get());
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "Clinical note deleted successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error deleting note: " + e.getMessage());
        }
    }

    /**
     * Search clinical notes
     * GET /api/clinical-notes/search
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchNotes(
            @RequestParam(required = false) Long patientId,
            @RequestParam(required = false) Long doctorId,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String keyword) {
        try {
            List<ClinicalNote> notes;
            
            if (patientId != null) {
                notes = clinicalNoteRepository.findByPatientId(patientId);
            } else if (doctorId != null) {
                notes = clinicalNoteRepository.findByDoctorId(doctorId);
            } else {
                notes = clinicalNoteRepository.findAll();
            }
            
            // Filter by tag
            if (tag != null && !tag.isEmpty()) {
                notes = notes.stream()
                        .filter(n -> n.getTag().equalsIgnoreCase(tag))
                        .collect(Collectors.toList());
            }
            
            // Filter by keyword
            if (keyword != null && !keyword.isEmpty()) {
                String lowerKeyword = keyword.toLowerCase();
                notes = notes.stream()
                        .filter(n -> n.getNoteText().toLowerCase().contains(lowerKeyword))
                        .collect(Collectors.toList());
            }
            
            List<Map<String, Object>> result = notes.stream()
                    .map(this::noteToMap)
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error searching notes: " + e.getMessage());
        }
    }

    /**
     * Get note statistics for a doctor
     * GET /api/clinical-notes/doctor/{doctorId}/stats
     */
    @GetMapping("/doctor/{doctorId}/stats")
    public ResponseEntity<?> getDoctorNoteStats(@PathVariable Long doctorId) {
        try {
            List<ClinicalNote> notes = clinicalNoteRepository.findByDoctorId(doctorId);
            
            Map<String, Long> tagCounts = notes.stream()
                    .collect(Collectors.groupingBy(ClinicalNote::getTag, Collectors.counting()));
            
            LocalDateTime today = LocalDateTime.now().toLocalDate().atStartOfDay();
            long todayCount = notes.stream()
                    .filter(n -> n.getCreatedAt().isAfter(today))
                    .count();
            
            LocalDateTime weekAgo = LocalDateTime.now().minusDays(7);
            long weekCount = notes.stream()
                    .filter(n -> n.getCreatedAt().isAfter(weekAgo))
                    .count();
            
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "total_notes", notes.size(),
                    "notes_today", todayCount,
                    "notes_this_week", weekCount,
                    "by_tag", tagCounts
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error fetching stats: " + e.getMessage());
        }
    }

    // Helper methods
    
    private Map<String, Object> noteToMap(ClinicalNote note) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", note.getId());
        map.put("patient_id", note.getPatient().getId());
        map.put("patient_name", note.getPatient().getName());
        map.put("doctor_id", note.getDoctor().getId());
        map.put("doctor_name", note.getDoctor().getName());
        map.put("content", note.getNoteText());
        map.put("tag", note.getTag());
        map.put("created_at", note.getCreatedAt().toString());
        map.put("updated_at", note.getUpdatedAt() != null ? note.getUpdatedAt().toString() : null);
        return map;
    }
}
