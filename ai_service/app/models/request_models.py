"""
Request models for NalaMAI AI Service
"""

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, validator


class ChatMessage(BaseModel):
    """Chat message model"""

    role: str = Field(..., description="Role: 'user' or 'assistant'")
    content: str = Field(..., description="Message content")


class ChatRequest(BaseModel):
    """Chat request model"""

    patient_id: str = Field(..., description="Patient ID")
    message: str = Field(..., description="User message")
    token: str = Field(..., description="Authentication token")
    conversation_history: Optional[List[ChatMessage]] = Field(
        default=None, description="Previous messages in conversation"
    )

    @validator("patient_id")
    def patient_id_not_empty(cls, v):
        if not v or len(v) == 0:
            raise ValueError("patient_id cannot be empty")
        return v

    @validator("message")
    def message_not_empty(cls, v):
        if not v or len(v) == 0:
            raise ValueError("message cannot be empty")
        return v

    @validator("token")
    def token_not_empty(cls, v):
        if not v or len(v) == 0:
            raise ValueError("token cannot be empty")
        return v


class VitalSigns(BaseModel):
    """Vital signs model"""

    heart_rate: Optional[int] = Field(None, description="Heart rate in bpm", ge=40, le=200)
    blood_pressure_systolic: Optional[int] = Field(
        None, description="Systolic blood pressure in mmHg", ge=60, le=250
    )
    blood_pressure_diastolic: Optional[int] = Field(
        None, description="Diastolic blood pressure in mmHg", ge=30, le=150
    )
    blood_oxygen: Optional[float] = Field(
        None, description="Blood oxygen saturation %", ge=50, le=100
    )
    temperature: Optional[float] = Field(
        None, description="Temperature in Celsius", ge=35.0, le=43.0
    )
    respiratory_rate: Optional[int] = Field(
        None, description="Respiratory rate in breaths/min", ge=8, le=60
    )
    blood_glucose: Optional[float] = Field(
        None, description="Blood glucose in mg/dL", ge=40, le=500
    )


class PredictionRequest(BaseModel):
    """Health risk prediction request"""

    patient_id: str = Field(..., description="Patient ID")
    vital_signs: VitalSigns = Field(..., description="Vital signs data")
    medical_history: Optional[Dict[str, Any]] = Field(
        None, description="Medical history"
    )
    token: str = Field(..., description="Authentication token")


class OCRRequest(BaseModel):
    """OCR request model"""

    patient_id: str = Field(..., description="Patient ID")
    document_type: str = Field(
        ..., description="Document type (prescription, lab_report, etc)"
    )
    token: str = Field(..., description="Authentication token")


class AnalysisRequest(BaseModel):
    """Patient analysis request"""

    include_vitals: bool = Field(default=True, description="Include vital signs")
    include_medications: bool = Field(default=True, description="Include medications")
    include_appointments: bool = Field(default=True, description="Include appointments")
    token: str = Field(..., description="Authentication token")


class AppointmentBooking(BaseModel):
    """Appointment booking model"""

    doctor_id: str = Field(..., description="Doctor ID")
    date: str = Field(..., description="Appointment date (YYYY-MM-DD)")
    time: str = Field(..., description="Appointment time (HH:MM)")
    reason: str = Field(..., description="Reason for appointment")


class SymptomCheck(BaseModel):
    """Symptom check model"""

    symptoms: List[str] = Field(..., description="List of symptoms")
    duration: Optional[str] = Field(None, description="Duration of symptoms")
    severity: Optional[str] = Field(None, description="Severity (mild, moderate, severe)")
