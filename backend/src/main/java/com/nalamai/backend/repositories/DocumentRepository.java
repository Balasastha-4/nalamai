package com.nalamai.backend.repositories;

import com.nalamai.backend.models.Document;
import com.nalamai.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DocumentRepository extends JpaRepository<Document, Long> {

    List<Document> findByUser(User user);

    @Query("SELECT d FROM Document d WHERE d.user.id = :userId")
    List<Document> findByUserId(@Param("userId") Long userId);

    List<Document> findByUserAndDocumentType(User user, String documentType);

    @Query("SELECT d FROM Document d WHERE d.user.id = :userId AND d.documentType = :documentType")
    List<Document> findByUserIdAndDocumentType(@Param("userId") Long userId, @Param("documentType") String documentType);

    @Query("SELECT d FROM Document d WHERE d.user.id = :userId ORDER BY d.uploadDate DESC")
    List<Document> findByUserIdOrderByUploadDateDesc(@Param("userId") Long userId);
}
