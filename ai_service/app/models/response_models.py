"""
Response models for NalaMAI AI Service
"""

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class APIResponse(BaseModel):
    """Base API response model"""

    status: str = Field(..., description="Response status (success/error)")
    message: str = Field(..., description="Response message")
    data: Optional[Dict[str, Any]] = Field(None, description="Response data")


class ChatResponse(BaseModel):
    """Chat response model"""

    status: str = Field(default="success", description="Response status")
    message: str = Field(..., description="AI response message")
    suggested_actions: Optional[List[Dict[str, Any]]] = Field(
        None, description="Suggested actions from function calling"
    )
    function_calls: Optional[List[Dict[str, Any]]] = Field(
        None, description="Function calls made"
    )
    timestamp: str = Field(..., description="Response timestamp")


class PredictionResponse(BaseModel):
    """Health risk prediction response"""

    status: str = Field(default="success", description="Response status")
    risk_level: str = Field(
        ..., description="Risk level (low, medium, high, critical)"
    )
    risk_score: float = Field(..., description="Risk score (0-100)")
    confidence: float = Field(..., description="Confidence level (0-1)")
    recommendations: List[str] = Field(..., description="Health recommendations")
    alert_conditions: Optional[List[str]] = Field(
        None, description="Alert conditions detected"
    )
    timestamp: str = Field(..., description="Response timestamp")


class OCRResponse(BaseModel):
    """OCR response model"""

    status: str = Field(default="success", description="Response status")
    extracted_text: str = Field(..., description="Extracted text from document")
    structured_data: Optional[Dict[str, Any]] = Field(
        None, description="Structured data extracted"
    )
    confidence: float = Field(..., description="OCR confidence (0-1)")
    document_type: str = Field(..., description="Detected document type")
    timestamp: str = Field(..., description="Response timestamp")


class AnalysisResponse(BaseModel):
    """Patient analysis response"""

    status: str = Field(default="success", description="Response status")
    patient_id: str = Field(..., description="Patient ID")
    health_summary: str = Field(..., description="Health summary")
    vital_trends: Optional[Dict[str, Any]] = Field(None, description="Vital sign trends")
    current_medications: Optional[List[Dict[str, Any]]] = Field(
        None, description="Current medications"
    )
    upcoming_appointments: Optional[List[Dict[str, Any]]] = Field(
        None, description="Upcoming appointments"
    )
    recommendations: List[str] = Field(..., description="Health recommendations")
    risk_factors: Optional[List[str]] = Field(
        None, description="Identified risk factors"
    )
    timestamp: str = Field(..., description="Response timestamp")


class HealthTip(BaseModel):
    """Health tip model"""

    category: str = Field(..., description="Tip category")
    tip: str = Field(..., description="Health tip text")
    severity: str = Field(..., description="Importance level")


class ErrorResponse(BaseModel):
    """Error response model"""

    status: str = Field(default="error", description="Response status")
    message: str = Field(..., description="Error message")
    error_code: Optional[str] = Field(None, description="Error code")
    timestamp: str = Field(..., description="Error timestamp")
