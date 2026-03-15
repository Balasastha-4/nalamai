from fastapi import APIRouter, Body
from pydantic import BaseModel
import random

router = APIRouter()

# Schema for the expected input payload from Spring Boot / Flutter
class PatientVitals(BaseModel):
    heartRate: int
    systolicBP: int
    diastolicBP: int
    oxygenLevel: int
    temperature: float
    age: int

@router.post("/")
async def predict_health_risk(vitals: PatientVitals = Body(...)):
    """
    Takes patient vitals and runs them through a prediction model.
    Currently mocked to demonstrate the architecture flow.
    """
    
    # 1. Feature extraction
    hr = vitals.heartRate
    sys = vitals.systolicBP
    dia = vitals.diastolicBP
    o2 = vitals.oxygenLevel
    
    # 2. Heuristic baseline logic simulating a linear regression or decision tree prediction
    risk_score = 0
    warnings = []
    
    # Analyze Heart Rate
    if hr > 100 or hr < 60:
        risk_score += 25
        warnings.append("Irregular Heart Rate detected.")
        
    # Analyze Blood Pressure (Normal is 120/80)
    if sys > 140 or sys < 90 or dia > 90 or dia < 60:
        risk_score += 30
        warnings.append("Blood Pressure is outside normal parameters.")
        
    # Analyze SpO2
    if o2 < 95:
        risk_score += 35
        warnings.append("Hypoxemia warning. Oxygen levels are severely low.")
        
    # Determine Status
    if risk_score > 60:
        prediction = "Critical"
    elif risk_score > 25:
        prediction = "Warning"
    else:
        prediction = "Stable"
        
    # Optionally, we can simulate an AI confidence percentage
    confidence = round(random.uniform(0.85, 0.98), 2)
    
    return {
        "status": "success",
        "health_prediction": prediction,
        "risk_score": risk_score,
        "warnings": warnings,
        "model_confidence": confidence
    }
