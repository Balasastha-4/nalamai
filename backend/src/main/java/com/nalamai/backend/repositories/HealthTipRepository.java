package com.nalamai.backend.repositories;

import com.nalamai.backend.models.HealthTip;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HealthTipRepository extends JpaRepository<HealthTip, Long> {

    List<HealthTip> findByCategory(String category);

    @Query("SELECT ht FROM HealthTip ht WHERE LOWER(ht.category) = LOWER(:category)")
    List<HealthTip> findByCategoryIgnoreCase(@Param("category") String category);

    List<HealthTip> findByIsActiveTrue();

    List<HealthTip> findByIsFeaturedTrue();

    @Query("SELECT ht FROM HealthTip ht WHERE ht.isActive = true ORDER BY ht.publishedAt DESC")
    List<HealthTip> findAllActiveOrderByPublishedAtDesc();

    @Query("SELECT ht FROM HealthTip ht WHERE ht.category = :category AND ht.isActive = true")
    List<HealthTip> findByCategoryAndIsActiveTrue(@Param("category") String category);
}
