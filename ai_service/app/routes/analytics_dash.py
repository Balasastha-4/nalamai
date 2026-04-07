"""
Analytics endpoints - Health analytics with AI-powered insights
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

class AnalyticsRequest(BaseModel):
    patient_id: str
    metric_type: Optional[str] = None  # HeartRate, BP, SpO2, Temperature, All
    period: str = "week"  # day, week, month, year
    token: Optional[str] = None


class ChartDataPoint(BaseModel):
    label: str
    value: float
    timestamp: Optional[str] = None


class MetricAnalytics(BaseModel):
    metric: str
    data: List[ChartDataPoint]
    average: float
    min_val: float
    max_val: float
    trend_direction: str
    percent_change: float


class AnalyticsResponse(BaseModel):
    status: str
    period: str
    metrics: List[MetricAnalytics]
    health_score: int
    ai_summary: str
    alerts: List[str]


class HealthScoreRequest(BaseModel):
    patient_id: str
    include_history: bool = True
    token: Optional[str] = None


class HealthScoreResponse(BaseModel):
    status: str
    overall_score: int
    category_scores: Dict[str, int]
    ai_analysis: str
    improvement_tips: List[str]


# ========== Helper Functions ==========

def generate_demo_analytics(days: int) -> List[dict]:
    """Generate demo analytics data"""
    data = []
    base_date = datetime.now() - timedelta(days=days)
    
    for day in range(days):
        date = base_date + timedelta(days=day)
        data.extend([
            {"type": "HeartRate", "value": 70 + random.randint(-5, 15), "timestamp": date.isoformat()},
            {"type": "BP_Systolic", "value": 120 + random.randint(-10, 15), "timestamp": date.isoformat()},
            {"type": "BP_Diastolic", "value": 80 + random.randint(-5, 10), "timestamp": date.isoformat()},
            {"type": "SpO2", "value": 97 + random.randint(-2, 2), "timestamp": date.isoformat()},
            {"type": "Temperature", "value": round(36.5 + random.uniform(-0.3, 0.5), 1), "timestamp": date.isoformat()}
        ])
    
    return data


def format_label(timestamp: str, period: str) -> str:
    """Format timestamp for chart labels"""
    try:
        dt = datetime.fromisoformat(timestamp.replace("Z", ""))
        if period == "day":
            return dt.strftime("%H:%M")
        elif period == "week":
            return dt.strftime("%a")
        elif period == "month":
            return dt.strftime("%d")
        else:
            return dt.strftime("%b")
    except:
        return timestamp[:10]


def calculate_health_score(metrics: List[MetricAnalytics]) -> int:
    """Calculate overall health score from metrics"""
    score = 100
    
    for metric in metrics:
        if metric.metric == "HeartRate":
            if not (60 <= metric.average <= 100):
                score -= 10
        elif metric.metric == "BP_Systolic":
            if metric.average > 140:
                score -= 15
            elif metric.average > 130:
                score -= 5
        elif metric.metric == "SpO2":
            if metric.average < 95:
                score -= 20
            elif metric.average < 97:
                score -= 5
    
    return max(0, min(100, score))


def generate_alerts(metrics: List[MetricAnalytics]) -> List[str]:
    """Generate health alerts based on metrics"""
    alerts = []
    
    for metric in metrics:
        if metric.metric == "HeartRate" and (metric.average < 60 or metric.average > 100):
            alerts.append(f"Heart rate outside normal range (avg: {metric.average} bpm)")
        elif metric.metric == "BP_Systolic" and metric.average > 140:
            alerts.append(f"Elevated blood pressure detected (avg: {metric.average} mmHg)")
        elif metric.metric == "SpO2" and metric.average < 95:
            alerts.append(f"Low oxygen saturation (avg: {metric.average}%)")
        elif metric.metric == "Temperature" and metric.average > 37.5:
            alerts.append(f"Elevated temperature detected (avg: {metric.average}°C)")
    
    return alerts


# ========== Endpoints ==========

@router.post("/analytics/dashboard", response_model=AnalyticsResponse)
async def get_analytics_dashboard(request: AnalyticsRequest):
    """
    Get comprehensive analytics dashboard data for charts and visualizations.
    Returns time-series data suitable for line charts, bar charts, etc.
    """
    try:
        logger.info(f"Fetching analytics dashboard for patient: {request.patient_id}")
        
        # Determine date range
        period_days = {"day": 1, "week": 7, "month": 30, "year": 365}.get(request.period, 7)
        
        # Generate demo data (in production, fetch from backend)
        vitals_data = generate_demo_analytics(period_days)
        
        # Process metrics
        metrics = []
        metric_types = ["HeartRate", "BP_Systolic", "BP_Diastolic", "SpO2", "Temperature"]
        
        if request.metric_type and request.metric_type != "All":
            if request.metric_type == "BP":
                metric_types = ["BP_Systolic", "BP_Diastolic"]
            else:
                metric_types = [request.metric_type]
        
        for metric_type in metric_types:
            metric_data = [v for v in vitals_data if v.get("type") == metric_type]
            if metric_data:
                data_points = [
                    ChartDataPoint(
                        label=format_label(v.get("timestamp", ""), request.period),
                        value=v.get("value", 0),
                        timestamp=v.get("timestamp")
                    )
                    for v in metric_data
                ]
                
                values = [d.value for d in data_points]
                avg = sum(values) / len(values) if values else 0
                
                # Calculate trend
                first_half = values[:len(values)//2] if values else [0]
                second_half = values[len(values)//2:] if values else [0]
                first_avg = sum(first_half) / len(first_half) if first_half else 0
                second_avg = sum(second_half) / len(second_half) if second_half else 0
                percent_change = ((second_avg - first_avg) / max(first_avg, 1)) * 100
                
                metrics.append(MetricAnalytics(
                    metric=metric_type,
                    data=data_points,
                    average=round(avg, 1),
                    min_val=min(values) if values else 0,
                    max_val=max(values) if values else 0,
                    trend_direction="up" if percent_change > 2 else ("down" if percent_change < -2 else "stable"),
                    percent_change=round(percent_change, 1)
                ))
        
        # Calculate health score
        health_score = calculate_health_score(metrics)
        
        # Generate alerts
        alerts = generate_alerts(metrics)
        
        # AI summary
        ai_summary = await generate_ai_summary(metrics, request.period)
        
        return AnalyticsResponse(
            status="success",
            period=request.period,
            metrics=metrics,
            health_score=health_score,
            ai_summary=ai_summary,
            alerts=alerts
        )
    except Exception as e:
        logger.error(f"Error generating analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analytics/health-score", response_model=HealthScoreResponse)
async def calculate_comprehensive_health_score(request: HealthScoreRequest):
    """
    Calculate a comprehensive health score based on all available health data.
    Uses AI to provide personalized analysis and improvement tips.
    """
    try:
        logger.info(f"Calculating health score for patient: {request.patient_id}")
        
        # Fetch recent vitals (demo data)
        vitals = generate_demo_analytics(30)
        
        # Calculate category scores
        category_scores = {}
        
        # Cardiovascular (Heart Rate + BP)
        hr_data = [v["value"] for v in vitals if v.get("type") == "HeartRate"]
        bp_sys = [v["value"] for v in vitals if v.get("type") == "BP_Systolic"]
        
        cardio_score = 100
        if hr_data:
            avg_hr = sum(hr_data) / len(hr_data)
            if 60 <= avg_hr <= 100:
                cardio_score -= 0
            elif 50 <= avg_hr <= 110:
                cardio_score -= 15
            else:
                cardio_score -= 30
        
        if bp_sys:
            avg_bp_sys = sum(bp_sys) / len(bp_sys)
            if avg_bp_sys > 140:
                cardio_score -= 20
            elif avg_bp_sys > 130:
                cardio_score -= 10
        
        category_scores["Cardiovascular"] = max(0, cardio_score)
        
        # Respiratory (SpO2)
        spo2_data = [v["value"] for v in vitals if v.get("type") == "SpO2"]
        resp_score = 100
        if spo2_data:
            avg_spo2 = sum(spo2_data) / len(spo2_data)
            if avg_spo2 < 95:
                resp_score -= 25
            elif avg_spo2 < 97:
                resp_score -= 10
        category_scores["Respiratory"] = max(0, resp_score)
        
        # Metabolic (Temperature)
        temp_data = [v["value"] for v in vitals if v.get("type") == "Temperature"]
        metabolic_score = 100
        if temp_data:
            avg_temp = sum(temp_data) / len(temp_data)
            if avg_temp > 37.5 or avg_temp < 36.0:
                metabolic_score -= 20
            elif avg_temp > 37.2 or avg_temp < 36.3:
                metabolic_score -= 10
        category_scores["Metabolic"] = max(0, metabolic_score)
        
        # Overall score
        overall_score = sum(category_scores.values()) // len(category_scores)
        
        # AI analysis
        ai_analysis, tips = await get_ai_health_analysis(category_scores, overall_score)
        
        return HealthScoreResponse(
            status="success",
            overall_score=overall_score,
            category_scores=category_scores,
            ai_analysis=ai_analysis,
            improvement_tips=tips
        )
    except Exception as e:
        logger.error(f"Error calculating health score: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/analytics/trends/{patient_id}")
async def get_health_trends(patient_id: str, metric: str = "all", period: str = "week"):
    """
    Get health trends for specific metrics over time.
    Useful for tracking progress and identifying patterns.
    """
    try:
        logger.info(f"Fetching health trends for patient: {patient_id}")
        
        period_days = {"day": 1, "week": 7, "month": 30, "year": 365}.get(period, 7)
        
        # Generate trend data
        trends = {}
        metrics_to_fetch = ["HeartRate", "BP_Systolic", "BP_Diastolic", "SpO2", "Temperature"]
        
        if metric != "all":
            metrics_to_fetch = [metric]
        
        for m in metrics_to_fetch:
            base_values = {
                "HeartRate": 75,
                "BP_Systolic": 120,
                "BP_Diastolic": 80,
                "SpO2": 98,
                "Temperature": 36.6
            }
            base = base_values.get(m, 50)
            variance = base * 0.1
            
            data = [round(base + random.uniform(-variance, variance), 1) for _ in range(period_days)]
            trends[m] = {
                "data": data,
                "trend": "stable" if abs(data[-1] - data[0]) < data[0] * 0.05 else ("up" if data[-1] > data[0] else "down"),
                "average": round(sum(data) / len(data), 1)
            }
        
        return {
            "status": "success",
            "patient_id": patient_id,
            "period": period,
            "trends": trends
        }
    except Exception as e:
        logger.error(f"Error fetching trends: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def generate_ai_summary(metrics: List[MetricAnalytics], period: str) -> str:
    """Generate AI-powered summary of health metrics"""
    try:
        gemini_service = get_gemini_service()
        
        metrics_text = "\n".join([
            f"- {m.metric}: avg={m.average}, trend={m.trend_direction}, change={m.percent_change}%"
            for m in metrics
        ])
        
        prompt = f"""Summarize these health metrics in 2 sentences for a patient:

Period: {period}
{metrics_text}

Be encouraging but honest. Mention any concerns briefly."""

        response = await gemini_service.generate_response(prompt)
        
        if isinstance(response, dict) and "response" in response:
            return response["response"].strip()
        
        return "Your health metrics are being monitored. Consult your healthcare provider for personalized advice."
    except Exception as e:
        logger.error(f"AI summary error: {e}")
        return "Your health metrics are being monitored. Consult your healthcare provider for personalized advice."


async def get_ai_health_analysis(scores: Dict[str, int], overall: int) -> tuple:
    """Get AI analysis of health scores"""
    try:
        gemini_service = get_gemini_service()
        
        scores_text = "\n".join([f"- {k}: {v}/100" for k, v in scores.items()])
        
        prompt = f"""Analyze this health score breakdown and provide advice:

Overall Score: {overall}/100
{scores_text}

Provide:
1. A 2-sentence analysis
2. 3 specific improvement tips

Format as JSON: {{"analysis": "...", "tips": ["...", "...", "..."]}}"""

        response = await gemini_service.generate_response(prompt)
        
        if isinstance(response, dict) and "response" in response:
            text = response["response"]
            if "{" in text and "}" in text:
                json_str = text[text.find("{"):text.rfind("}")+1]
                data = json.loads(json_str)
                return (data.get("analysis", text), data.get("tips", []))
        
        return ("Your overall health is being tracked.", ["Exercise regularly", "Maintain healthy diet", "Monitor vitals daily"])
    except Exception as e:
        logger.error(f"AI analysis error: {e}")
        return ("Unable to generate analysis", ["Stay healthy", "Exercise regularly", "Eat well"])
