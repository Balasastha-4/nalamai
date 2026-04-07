"""
Symptoms Checker Router - AI-powered symptom analysis and preliminary assessment
"""
import os
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from google import genai
from google.genai import types

router = APIRouter()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyCz8Fv51ZBI4lohGNLEbEtG-yPGYkaAQzw")

client = None
if GEMINI_API_KEY:
    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
    except Exception as e:
        print(f"Failed to initialize Gemini Client: {e}")


class Symptom(BaseModel):
    name: str
    severity: str = "moderate"  # mild, moderate, severe
    duration: Optional[str] = None  # e.g., "2 days", "1 week"
    notes: Optional[str] = None


class SymptomCheckRequest(BaseModel):
    patient_id: str
    symptoms: List[Symptom]
    age: Optional[int] = None
    gender: Optional[str] = None
    medical_history: Optional[List[str]] = None
    current_medications: Optional[List[str]] = None


class PossibleCondition(BaseModel):
    name: str
    probability: str  # low, moderate, high
    description: str
    urgency: str  # routine, soon, urgent, emergency


class SymptomCheckResponse(BaseModel):
    status: str
    disclaimer: str
    assessment: str
    possible_conditions: List[PossibleCondition]
    recommendations: List[str]
    when_to_seek_care: str
    follow_up_questions: List[str]


class QuickSymptomRequest(BaseModel):
    symptom: str
    patient_id: Optional[str] = None


@router.post("/check", response_model=SymptomCheckResponse)
async def check_symptoms(request: SymptomCheckRequest):
    """
    Analyze symptoms using AI and provide preliminary assessment.
    This is NOT a diagnosis - always consult a healthcare provider.
    """
    if not client:
        raise HTTPException(status_code=500, detail="AI service not available")
    
    try:
        # Build symptom description
        symptoms_text = "\n".join([
            f"- {s.name} (severity: {s.severity}, duration: {s.duration or 'not specified'})"
            + (f" - {s.notes}" if s.notes else "")
            for s in request.symptoms
        ])
        
        context = ""
        if request.age:
            context += f"Age: {request.age}\n"
        if request.gender:
            context += f"Gender: {request.gender}\n"
        if request.medical_history:
            context += f"Medical History: {', '.join(request.medical_history)}\n"
        if request.current_medications:
            context += f"Current Medications: {', '.join(request.current_medications)}\n"
        
        prompt = f"""You are a medical triage assistant. Analyze these symptoms and provide a preliminary assessment.

IMPORTANT DISCLAIMER: This is NOT a medical diagnosis. Always recommend consulting a healthcare provider.

Patient Information:
{context if context else "Not provided"}

Reported Symptoms:
{symptoms_text}

Provide your response in this exact JSON format:
{{
    "assessment": "Brief 2-3 sentence overall assessment",
    "possible_conditions": [
        {{
            "name": "Condition name",
            "probability": "low/moderate/high",
            "description": "Brief description",
            "urgency": "routine/soon/urgent/emergency"
        }}
    ],
    "recommendations": ["Recommendation 1", "Recommendation 2", "Recommendation 3"],
    "when_to_seek_care": "When to see a doctor immediately",
    "follow_up_questions": ["Question 1", "Question 2"]
}}

Be thorough but not alarmist. List 2-4 possible conditions with the most likely first."""

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config=types.GenerateContentConfig(temperature=0.2, max_output_tokens=1000)
        )
        
        # Parse response
        text = response.text
        if "{" in text:
            json_str = text[text.find("{"):text.rfind("}")+1]
            data = json.loads(json_str)
            
            conditions = [
                PossibleCondition(
                    name=c.get("name", "Unknown"),
                    probability=c.get("probability", "low"),
                    description=c.get("description", ""),
                    urgency=c.get("urgency", "routine")
                )
                for c in data.get("possible_conditions", [])
            ]
            
            return SymptomCheckResponse(
                status="success",
                disclaimer="This is NOT a medical diagnosis. Always consult a healthcare professional for proper evaluation.",
                assessment=data.get("assessment", "Unable to assess. Please consult a doctor."),
                possible_conditions=conditions,
                recommendations=data.get("recommendations", ["Consult your healthcare provider"]),
                when_to_seek_care=data.get("when_to_seek_care", "If symptoms worsen or persist"),
                follow_up_questions=data.get("follow_up_questions", [])
            )
        
        # Fallback response
        return SymptomCheckResponse(
            status="success",
            disclaimer="This is NOT a medical diagnosis. Always consult a healthcare professional.",
            assessment="Based on your symptoms, we recommend consulting a healthcare provider for proper evaluation.",
            possible_conditions=[],
            recommendations=["Schedule an appointment with your doctor", "Monitor your symptoms"],
            when_to_seek_care="If symptoms worsen or you experience severe discomfort",
            follow_up_questions=["How long have you had these symptoms?", "Any other symptoms?"]
        )
        
    except json.JSONDecodeError:
        return SymptomCheckResponse(
            status="success",
            disclaimer="This is NOT a medical diagnosis.",
            assessment="Please consult a healthcare provider for proper evaluation of your symptoms.",
            possible_conditions=[],
            recommendations=["Consult your healthcare provider"],
            when_to_seek_care="If symptoms persist or worsen",
            follow_up_questions=[]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/quick-check")
async def quick_symptom_check(request: QuickSymptomRequest):
    """
    Quick single-symptom check for common symptoms.
    Returns immediate guidance.
    """
    if not client:
        return {
            "status": "success",
            "symptom": request.symptom,
            "advice": "Please consult a healthcare provider for proper evaluation.",
            "urgency": "routine"
        }
    
    try:
        prompt = f"""A patient reports: "{request.symptom}"

Provide brief guidance in JSON format:
{{
    "advice": "1-2 sentence home care advice",
    "urgency": "routine/soon/urgent/emergency",
    "seek_help_if": "When to see a doctor"
}}

Be helpful but always recommend professional care for serious symptoms."""

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=prompt,
            config=types.GenerateContentConfig(temperature=0.2, max_output_tokens=200)
        )
        
        text = response.text
        if "{" in text:
            json_str = text[text.find("{"):text.rfind("}")+1]
            data = json.loads(json_str)
            return {
                "status": "success",
                "symptom": request.symptom,
                "advice": data.get("advice", "Consult a healthcare provider."),
                "urgency": data.get("urgency", "routine"),
                "seek_help_if": data.get("seek_help_if", "Symptoms worsen or persist")
            }
        
        return {
            "status": "success",
            "symptom": request.symptom,
            "advice": "Please consult a healthcare provider for proper evaluation.",
            "urgency": "routine"
        }
    except Exception as e:
        return {
            "status": "error",
            "symptom": request.symptom,
            "advice": "Unable to process. Please consult a healthcare provider.",
            "urgency": "routine"
        }


@router.get("/common-symptoms")
async def get_common_symptoms():
    """
    Get list of common symptoms for quick selection in the app.
    """
    return {
        "status": "success",
        "categories": {
            "General": [
                "Fever", "Fatigue", "Weakness", "Weight loss", "Night sweats"
            ],
            "Head & Neck": [
                "Headache", "Dizziness", "Sore throat", "Neck pain", "Ear pain"
            ],
            "Respiratory": [
                "Cough", "Shortness of breath", "Chest pain", "Wheezing", "Runny nose"
            ],
            "Digestive": [
                "Nausea", "Vomiting", "Diarrhea", "Constipation", "Abdominal pain"
            ],
            "Musculoskeletal": [
                "Back pain", "Joint pain", "Muscle aches", "Stiffness", "Swelling"
            ],
            "Skin": [
                "Rash", "Itching", "Hives", "Dry skin", "Bruising"
            ],
            "Mental Health": [
                "Anxiety", "Sleep problems", "Low mood", "Stress", "Difficulty concentrating"
            ]
        }
    }


@router.post("/emergency-check")
async def emergency_symptom_check(symptoms: List[str]):
    """
    Quick check for emergency symptoms that require immediate care.
    """
    emergency_symptoms = {
        "chest pain": "Call emergency services immediately. Could indicate heart attack.",
        "difficulty breathing": "Seek immediate medical attention. Call emergency services.",
        "stroke symptoms": "Call emergency services immediately. Time is critical.",
        "severe bleeding": "Apply pressure and seek emergency care immediately.",
        "loss of consciousness": "Call emergency services. Check breathing.",
        "severe allergic reaction": "Use epinephrine if available. Call emergency services.",
        "severe head injury": "Seek immediate emergency care. Do not move patient.",
        "poisoning": "Call poison control or emergency services immediately.",
        "suicidal thoughts": "Call crisis hotline or emergency services. You are not alone."
    }
    
    matched_emergencies = []
    for symptom in symptoms:
        symptom_lower = symptom.lower()
        for emergency, advice in emergency_symptoms.items():
            if emergency in symptom_lower or symptom_lower in emergency:
                matched_emergencies.append({
                    "symptom": symptom,
                    "advice": advice,
                    "urgency": "emergency"
                })
                break
    
    is_emergency = len(matched_emergencies) > 0
    
    return {
        "status": "success",
        "is_emergency": is_emergency,
        "matched_emergencies": matched_emergencies,
        "general_advice": "If in doubt, call emergency services or go to the nearest emergency room." if is_emergency else "Monitor your symptoms and consult a healthcare provider if concerned."
    }
