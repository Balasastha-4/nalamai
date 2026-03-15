package com.nalamai.backend.controllers;

import com.nalamai.backend.models.MedicalResource;
import com.nalamai.backend.repositories.MedicalResourceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/resources")
public class MedicalResourceController {

    @Autowired
    private MedicalResourceRepository medicalResourceRepository;

    @GetMapping
    public List<MedicalResource> getAllResources() {
        return medicalResourceRepository.findAll();
    }

    @GetMapping("/type/{type}")
    public List<MedicalResource> getByGeneralType(@PathVariable String type) {
        return medicalResourceRepository.findByType(type);
    }

    @PostMapping("/")
    public ResponseEntity<MedicalResource> addResource(@RequestBody MedicalResource resource) {
        return ResponseEntity.ok(medicalResourceRepository.save(resource));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestParam String status) {
        return medicalResourceRepository.findById(id).map(r -> {
            r.setStatus(status);
            return ResponseEntity.ok(medicalResourceRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }
}
