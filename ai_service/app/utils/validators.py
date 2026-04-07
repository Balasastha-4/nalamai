"""
Validation utilities for NalaMAI AI Service
"""

import re
from typing import Optional, List
from fastapi import HTTPException, status


def validate_email(email: str) -> bool:
    """Validate email format"""
    pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    return re.match(pattern, email) is not None


def validate_phone(phone: str) -> bool:
    """Validate phone number format"""
    pattern = r"^\d{10,15}$"
    return re.match(pattern, phone) is not None


def validate_patient_id(patient_id: str) -> bool:
    """Validate patient ID format"""
    return len(patient_id) > 0 and len(patient_id) <= 50


def validate_vital_signs(
    heart_rate: Optional[int] = None,
    blood_pressure_systolic: Optional[int] = None,
    blood_pressure_diastolic: Optional[int] = None,
    blood_oxygen: Optional[float] = None,
    temperature: Optional[float] = None,
) -> List[str]:
    """
    Validate vital signs

    Returns:
        List of validation errors (empty if valid)
    """
    errors = []

    if heart_rate is not None:
        if heart_rate < 40 or heart_rate > 200:
            errors.append("Heart rate must be between 40 and 200 bpm")

    if blood_pressure_systolic is not None:
        if blood_pressure_systolic < 60 or blood_pressure_systolic > 250:
            errors.append("Systolic blood pressure must be between 60 and 250 mmHg")

    if blood_pressure_diastolic is not None:
        if blood_pressure_diastolic < 30 or blood_pressure_diastolic > 150:
            errors.append("Diastolic blood pressure must be between 30 and 150 mmHg")

    if blood_oxygen is not None:
        if blood_oxygen < 50 or blood_oxygen > 100:
            errors.append("Blood oxygen must be between 50 and 100%")

    if temperature is not None:
        if temperature < 35.0 or temperature > 43.0:
            errors.append("Temperature must be between 35.0 and 43.0°C")

    return errors


def validate_token(token: str) -> bool:
    """Validate JWT token format"""
    return len(token) > 0 and token.count(".") == 2


def raise_validation_error(message: str, status_code: int = 400):
    """Raise validation error"""
    raise HTTPException(
        status_code=status_code,
        detail={"status": "error", "message": message},
    )
