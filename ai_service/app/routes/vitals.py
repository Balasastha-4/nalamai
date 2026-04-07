"""
Vitals analysis endpoints with AI-powered insights
"""

from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
import random
import json

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.gemini_service import get_gemini_service
from app.utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()


# ========== Models ==========

class VitalReading(BaseModel):
    type: str  # HeartRate, BP_Systolic, BP_Diastolic, SpO2, Temperature
    value: float
    unit: Optional[str] = None
    timestamp: Optional[str] = None


class VitalsInput(BaseModel):
    patient_id: str
    vitals: List[VitalReading]
    token: Optional[str] = None


class VitalsAnalysisRequest(BaseModel):
    patient_id: str
    token: Optional[str] = None
    days: int = 7


class VitalTrend(BaseModel):
    type: str
    current: float
    average: float
    min_val: float
    max_val: float
    trend: str  # "increasing", "decreasing", "stable"
    status: str  # "normal", "warning", "critical"


class VitalsAnalysisResponse(BaseModel):
    status: str
    trends: List[VitalTrend]
    ai_insights: str
    recommendations: List[str]
    risk_level: str  # "low", "medium", "high"


# ========== Helper Functions ==========

def analyze_trend(values: List[float]) -> str:
    """Analyze if values are trending up, down, or stable"""
    if len(values) < 2:
        return "stable"
    
    first_half = sum(values[:len(values)//2]) / max(len(values)//2, 1)
    second_half = sum(values[len(values)//2:]) / max(len(values) - len(values)//2, 1)
    
    diff_percent = ((second_half - first_half) / max(first_half, 1)) * 100
    
    if diff_percent > 5:
        return "increasing"
    elif diff_percent < -5:
        return "decreasing"
    return "stable"


def get_vital_status(vital_type: str, value: float) -> str:
    """Determine if a vital reading is normal, warning, or critical"""
    ranges = {
        "HeartRate": {"normal": (60, 100), "warning": (50, 120)},
        "BP_Systolic": {"normal": (90, 120), "warning": (80, 140)},
        "BP_Diastolic": {"normal": (60, 80), "warning": (50, 90)},
        "SpO2": {"normal": (95, 100), "warning": (90, 100)},
        "Temperature": {"normal": (36.1, 37.2), "warning": (35.5, 38.0)}
    }
    
    if vital_type not in ranges:
        return "normal"
    
    normal = ranges[vital_type]["normal"]
    warning = ranges[vital_type]["warning"]
    
    if normal[0] <= value <= normal[1]:
        return "normal"
    elif warning[0] <= value <= warning[1]:
        return "warning"
    return "critical"


def get_default_unit(vital_type: str) -> str:
    """Get default unit for a vital type"""
    units = {
        "HeartRate": "bpm",
        "BP_Systolic": "mmHg",
        "BP_Diastolic": "mmHg",
        "SpO2": "%",
        "Temperature": "°C",
        "Weight": "kg",
        "BMI": "kg/m²"
    }
    return units.get(vital_type, "")


def get_status_message(vital_type: str, value: float, status: str) -> str:
    """Get a human-readable status message"""
    if status == "normal":
        return f"Your {vital_type} is within normal range."
    elif status == "warning":
        return f"Your {vital_type} is slightly outside normal range. Monitor closely."
    else:
        return f"Your {vital_type} requires immediate attention!"


def generate_mock_history(days: int) -> List[dict]:
    """Generate mock vital history for demo purposes"""
    history = []
    base_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        date = base_date + timedelta(days=day)
        history.extend([
            {"type": "HeartRate", "value": random.randint(65, 85), "timestamp": date.isoformat()},
            {"type": "BP_Systolic", "value": random.randint(115, 130), "timestamp": date.isoformat()},
            {"type": "BP_Diastolic", "value": random.randint(75, 85), "timestamp": date.isoformat()},
            {"type": "SpO2", "value": random.randint(96, 99), "timestamp": date.isoformat()},
            {"type": "Temperature", "value": round(random.uniform(36.2, 37.0), 1), "timestamp": date.isoformat()}
        ])
    
    return history


# ========== Endpoints ==========

@router.post("/vitals/record")
async def record_vitals(data: VitalsInput):
    """
    Record new vital readings for a patient.
    Provides instant AI analysis of the readings.
    """
    try:
        logger.info(f"Recording vitals for patient: {data.patient_id}")
        
        # Quick analysis
        analysis = []
        for vital in data.vitals:
            status = get_vital_status(vital.type, vital.value)
            analysis.append({
                "type": vital.type,
                "value": vital.value,
                "unit": vital.unit or get_default_unit(vital.type),
                "status": status,
                "message": get_status_message(vital.type, vital.value, status)
            })
        
        # Check for any critical readings
        critical_count = sum(1 for a in analysis if a["status"] == "critical")
        warning_count = sum(1 for a in analysis if a["status"] == "warning")
        
        return {
            "status": "success",
            "patient_id": data.patient_id,
            "recorded_at": datetime.now().isoformat(),
            "instant_analysis": analysis,
            "alert_level": "critical" if critical_count > 0 else ("warning" if warning_count > 0 else "normal"),
            "message": f"Recorded {len(analysis)} vital readings"
        }
    except Exception as e:
        logger.error(f"Error recording vitals: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/vitals/analyze", response_model=VitalsAnalysisResponse)
async def analyze_vitals(request: VitalsAnalysisRequest):
    """
    Analyze patient vitals with AI-powered insights and recommendations.
    Uses Gemini AI for comprehensive health analysis.
    """
    try:
        logger.info(f"Analyzing vitals for patient: {request.patient_id}")
        
        # Generate mock history for demo (in production, fetch from backend)
        history = generate_mock_history(request.days)
        
        # Calculate trends
        trends = []
        grouped: Dict[str, List[float]] = {}
        for vital in history:
            vtype = vital.get("type", "Unknown")
            if vtype not in grouped:
                grouped[vtype] = []
            grouped[vtype].append(vital.get("value", 0))
        
        for vtype, values in grouped.items():
            if values:
                current = values[-1] if values else 0
                avg = sum(values) / len(values)
                trends.append(VitalTrend(
                    type=vtype,
                    current=current,
                    average=round(avg, 1),
                    min_val=min(values),
                    max_val=max(values),
                    trend=analyze_trend(values),
                    status=get_vital_status(vtype, current)
                ))
        
        # Determine overall risk
        critical_count = sum(1 for t in trends if t.status == "critical")
        warning_count = sum(1 for t in trends if t.status == "warning")
        
        if critical_count > 0:
            risk_level = "high"
        elif warning_count > 1:
            risk_level = "medium"
        else:
            risk_level = "low"
        
        # Get AI insights
        ai_insights, recommendations = await get_ai_vitals_insights(trends, risk_level)
        
        return VitalsAnalysisResponse(
            status="success",
            trends=trends,
            ai_insights=ai_insights,
            recommendations=recommendations,
            risk_level=risk_level
        )
    except Exception as e:
        logger.error(f"Error analyzing vitals: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/vitals/latest/{patient_id}")
async def get_latest_vitals(patient_id: str):
    """Get the most recent vital readings for a patient"""
    try:
        logger.info(f"Fetching latest vitals for patient: {patient_id}")
        
        # Return mock data (in production, fetch from backend)
        return {
            "status": "success",
            "patient_id": patient_id,
            "timestamp": datetime.now().isoformat(),
            "vitals": {
                "HeartRate": {"value": 75, "unit": "bpm", "status": "normal"},
                "BP_Systolic": {"value": 120, "unit": "mmHg", "status": "normal"},
                "BP_Diastolic": {"value": 80, "unit": "mmHg", "status": "normal"},
                "SpO2": {"value": 98, "unit": "%", "status": "normal"},
                "Temperature": {"value": 36.6, "unit": "°C", "status": "normal"}
            },
            "source": "demo"
        }
    except Exception as e:
        logger.error(f"Error fetching vitals: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def get_ai_vitals_insights(trends: List[VitalTrend], risk_level: str) -> tuple:
    """Use Gemini AI to generate insights and recommendations"""
    try:
        gemini_service = get_gemini_service()
        
        trends_text = "\n".join([
            f"- {t.type}: Current={t.current}, Avg={t.average}, Trend={t.trend}, Status={t.status}"
            for t in trends
        ])
        
        prompt = f"""Analyze these patient vitals and provide brief health insights:

Vitals Summary:
{trends_text}

Overall Risk Level: {risk_level}

Provide:
1. A brief 2-3 sentence health insight summary
2. 3-4 specific actionable recommendations

Format as JSON: {{"insight": "...", "recommendations": ["...", "..."]}}"""

        response = await gemini_service.generate_response(prompt)
        
        # Parse response
        if isinstance(response, dict) and "response" in response:
            text = response["response"]
            if "{" in text and "}" in text:
                json_str = text[text.find("{"):text.rfind("}")+1]
                data = json.loads(json_str)
                return (data.get("insight", text), data.get("recommendations", []))
        
        return ("Your vitals are being monitored. Consult your healthcare provider for personalized advice.",
                ["Monitor your vitals regularly", "Stay hydrated", "Get adequate rest"])
    except Exception as e:
        logger.error(f"AI insights error: {e}")
        return ("Unable to generate AI insights", ["Consult your healthcare provider"])
