package com.nalamai.backend.controllers;

import com.nalamai.backend.models.Billing;
import com.nalamai.backend.repositories.BillingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/billings")
@CrossOrigin(origins = "*")
public class BillingController {

    @Autowired
    private BillingRepository billingRepository;

    @GetMapping("/patient/{patientId}")
    public List<Billing> getBillingsByPatient(@PathVariable Long patientId) {
        return billingRepository.findByPatientId(patientId);
    }

    @PostMapping("/")
    public ResponseEntity<Billing> createBilling(@RequestBody Billing billing) {
        if (billing.getStatus() == null) {
            billing.setStatus("PENDING");
        }
        return ResponseEntity.ok(billingRepository.save(billing));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestParam String status) {
        return billingRepository.findById(id).map(b -> {
            b.setStatus(status);
            return ResponseEntity.ok(billingRepository.save(b));
        }).orElse(ResponseEntity.notFound().build());
    }
}
