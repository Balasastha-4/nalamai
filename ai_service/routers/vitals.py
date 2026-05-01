"""
Vitals Analysis Router - AI-powered vitals analysis with trending and insights
"""
import os
import json
import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
from google import genai
from google.genai import types

router = APIRouter()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyCz8Fv51ZBI4lohGNLEbEtG-yPGYkaAQzw")
JAVA_BACKEND_URL = os.environ.get("JAVA_BACKEND_URL", "http://localhost:8080/api")

client = None
if GEMINI_API_KEY:
    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
    except Exception as e:
        print(f"Failed to initialize Gemini Client: {e}")


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


# Helper functions
async def fetch_vitals_history(patient_id: str, token: str = None, days: int = 7) -> dict:
    """Fetch vitals history from Java backend"""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/vitals/patient/{patient_id}",
                headers=headers,
                params={"days": days}
            )
            if response.status_code == 200:
                return response.json()
            return []
        except Exception as e:
            print(f"Error fetching vitals: {e}")
            return []


async def save_vitals(patient_id: str, vitals: List[dict], token: str = None) -> dict:
    """Save vitals to Java backend"""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.post(
                f"{JAVA_BACKEND_URL}/vitals/batch",
                json={"patient_id": patient_id, "vitals": vitals},
                headers=headers
            )
            if response.status_code == 200:
                return {"status": "success", "saved": len(vitals)}
            return {"status": "error", "message": response.text}
        except Exception as e:
            return {"status": "error", "message": str(e)}


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
        "HeartRate": {"normal": (60, 100), "warning": (50, 120), "critical": (0, 150)},
        "BP_Systolic": {"normal": (90, 120), "warning": (80, 140), "critical": (0, 180)},
        "BP_Diastolic": {"normal": (60, 80), "warning": (50, 90), "critical": (0, 120)},
        "SpO2": {"normal": (95, 100), "warning": (90, 100), "critical": (0, 100)},
        "Temperature": {"normal": (36.1, 37.2), "warning": (35.5, 38.0), "critical": (0, 42)}
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


@router.post("/record", response_model=dict)
async def record_vitals(data: VitalsInput):
    """
    Record new vital readings for a patient.
    Optionally saves to backend and provides instant AI analysis.
    """
    try:
        vitals_list = [
            {
                "type": v.type,
                "value": v.value,
                "unit": v.unit or get_default_unit(v.type),
                "timestamp": v.timestamp or datetime.now().isoformat()
            }
            for v in data.vitals
        ]
        
        # Save to backend
        save_result = await save_vitals(data.patient_id, vitals_list, data.token)
        
        # Quick analysis
        analysis = []
        for vital in data.vitals:
            status = get_vital_status(vital.type, vital.value)
            analysis.append({
                "type": vital.type,
                "value": vital.value,
                "status": status,
                "message": get_status_message(vital.type, vital.value, status)
            })
        
        return {
            "status": "success",
            "saved": save_result,
            "instant_analysis": analysis
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze", response_model=VitalsAnalysisResponse)
async def analyze_vitals(request: VitalsAnalysisRequest):
    """
    Analyze patient vitals with AI-powered insights and recommendations.
    Uses Gemini AI for comprehensive health analysis.
    """
    try:
        # Fetch historical data
        history = await fetch_vitals_history(request.patient_id, request.token, request.days)
        
        # If no backend data, use mock data for demo
        if not history:
            history = generate_mock_history(request.days)
        
        # Calculate trends
        trends = []
        grouped = {}
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
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/latest/{patient_id}")
async def get_latest_vitals(patient_id: str, token: str = None):
    """Get the most recent vital readings for a patient"""
    try:
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        async with httpx.AsyncClient() as http_client:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/vitals/patient/{patient_id}/latest",
                headers=headers
            )
            if response.status_code == 200:
                return {"status": "success", "vitals": response.json()}
            
            # Return mock data if backend unavailable
            return {
                "status": "success",
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
        return {"status": "error", "error": str(e), "type": str(type(e))}


async def get_ai_vitals_insights(trends: List[VitalTrend], risk_level: str) -> tuple:
    """Use Gemini AI to generate insights and recommendations"""
    if not client:
        return ("AI analysis unavailable", ["Consult your healthcare provider for personalized advice"])
    
    try:
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

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config=types.GenerateContentConfig(temperature=0.3)
        )
        
        # Parse response
        text = response.text
        # Try to extract JSON
        if "{" in text and "}" in text:
            json_str = text[text.find("{"):text.rfind("}")+1]
            data = json.loads(json_str)
            return (data.get("insight", text), data.get("recommendations", []))
        
        return (text, ["Monitor your vitals regularly", "Stay hydrated", "Get adequate rest"])
    except Exception as e:
        print(f"AI insights error: {e}")
        return ("Unable to generate AI insights", ["Consult your healthcare provider"])


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
    import random
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
