"""
Clinical notes endpoints - AI-assisted clinical note generation for doctors
"""

import json
from datetime import datetime
from typing import List, Optional, Dict, Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.gemini_service import get_gemini_service
from app.utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()


# ========== Models ==========

class PatientContext(BaseModel):
    patient_id: str
    patient_name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    chief_complaint: str
    history_of_present_illness: Optional[str] = None
    past_medical_history: Optional[List[str]] = None
    current_medications: Optional[List[str]] = None
    allergies: Optional[List[str]] = None
    vitals: Optional[Dict[str, Any]] = None


class PhysicalExam(BaseModel):
    general_appearance: Optional[str] = None
    vital_signs: Optional[str] = None
    cardiovascular: Optional[str] = None
    respiratory: Optional[str] = None
    abdomen: Optional[str] = None
    neurological: Optional[str] = None
    skin: Optional[str] = None
    other: Optional[str] = None


class GenerateNoteRequest(BaseModel):
    doctor_id: str
    patient_context: PatientContext
    physical_exam: Optional[PhysicalExam] = None
    assessment: Optional[str] = None
    plan: Optional[str] = None
    note_type: str = "SOAP"  # SOAP, Progress, Consultation, Discharge
    token: Optional[str] = None


class ClinicalNote(BaseModel):
    note_type: str
    subjective: str
    objective: str
    assessment: str
    plan: str
    generated_at: str
    icd_codes: List[str]
    cpt_codes: List[str]


class GenerateNoteResponse(BaseModel):
    status: str
    note: ClinicalNote
    ai_suggestions: List[str]
    differential_diagnoses: List[str]


class TranscribeRequest(BaseModel):
    doctor_id: str
    patient_id: str
    audio_transcript: str
    note_type: str = "SOAP"


class SummarizeRequest(BaseModel):
    patient_id: str
    notes: List[str]
    summary_type: str = "brief"  # brief, detailed, discharge


# ========== Endpoints ==========

@router.post("/notes/generate", response_model=GenerateNoteResponse)
async def generate_clinical_note(request: GenerateNoteRequest):
    """
    Generate a structured clinical note using AI based on patient information.
    Supports SOAP, Progress, Consultation, and Discharge note formats.
    """
    try:
        logger.info(f"Generating clinical note for patient: {request.patient_context.patient_id}")
        
        gemini_service = get_gemini_service()
        
        # Build context
        patient = request.patient_context
        exam = request.physical_exam or PhysicalExam()
        
        patient_info = f"""
Patient: {patient.patient_name or f'ID: {patient.patient_id}'}
Age: {patient.age or 'Not specified'}, Gender: {patient.gender or 'Not specified'}
Chief Complaint: {patient.chief_complaint}
HPI: {patient.history_of_present_illness or 'Not provided'}
PMH: {', '.join(patient.past_medical_history) if patient.past_medical_history else 'None reported'}
Medications: {', '.join(patient.current_medications) if patient.current_medications else 'None'}
Allergies: {', '.join(patient.allergies) if patient.allergies else 'NKDA'}
"""
        
        if patient.vitals:
            vitals_str = ", ".join([f"{k}: {v}" for k, v in patient.vitals.items()])
            patient_info += f"Vitals: {vitals_str}\n"
        
        exam_findings = ""
        if exam.general_appearance:
            exam_findings += f"General: {exam.general_appearance}\n"
        if exam.cardiovascular:
            exam_findings += f"CV: {exam.cardiovascular}\n"
        if exam.respiratory:
            exam_findings += f"Resp: {exam.respiratory}\n"
        if exam.abdomen:
            exam_findings += f"Abd: {exam.abdomen}\n"
        if exam.neurological:
            exam_findings += f"Neuro: {exam.neurological}\n"
        if exam.other:
            exam_findings += f"Other: {exam.other}\n"
        
        prompt = f"""You are a medical documentation assistant helping a doctor create a {request.note_type} note.

{patient_info}

Physical Examination:
{exam_findings if exam_findings else 'Pending or not performed'}

Doctor's Assessment: {request.assessment or 'To be determined'}
Doctor's Plan: {request.plan or 'To be determined'}

Generate a complete {request.note_type} note in this JSON format:
{{
    "subjective": "Patient's complaints and history in professional language",
    "objective": "Physical exam findings and vitals in professional format",
    "assessment": "Clinical assessment with differential diagnoses",
    "plan": "Treatment plan, medications, follow-up",
    "icd_codes": ["Relevant ICD-10 codes"],
    "cpt_codes": ["Relevant CPT codes"],
    "differential_diagnoses": ["DDx 1", "DDx 2"],
    "ai_suggestions": ["Clinical suggestion 1", "Consider ordering..."]
}}

Use professional medical terminology. Be thorough but concise."""

        response = await gemini_service.generate_response(prompt)
        
        text = response.get("response", "") if isinstance(response, dict) else str(response)
        
        if "{" in text:
            json_str = text[text.find("{"):text.rfind("}")+1]
            data = json.loads(json_str)
            
            note = ClinicalNote(
                note_type=request.note_type,
                subjective=data.get("subjective", patient.chief_complaint),
                objective=data.get("objective", exam_findings or "See exam findings"),
                assessment=data.get("assessment", request.assessment or "Assessment pending"),
                plan=data.get("plan", request.plan or "Plan pending"),
                generated_at=datetime.now().isoformat(),
                icd_codes=data.get("icd_codes", []),
                cpt_codes=data.get("cpt_codes", [])
            )
            
            return GenerateNoteResponse(
                status="success",
                note=note,
                ai_suggestions=data.get("ai_suggestions", []),
                differential_diagnoses=data.get("differential_diagnoses", [])
            )
        
        # Fallback
        return GenerateNoteResponse(
            status="success",
            note=ClinicalNote(
                note_type=request.note_type,
                subjective=patient.chief_complaint,
                objective=exam_findings or "Examination findings pending",
                assessment=request.assessment or "Assessment pending",
                plan=request.plan or "Plan to be determined",
                generated_at=datetime.now().isoformat(),
                icd_codes=[],
                cpt_codes=[]
            ),
            ai_suggestions=["Complete physical examination", "Consider lab workup"],
            differential_diagnoses=[]
        )
        
    except Exception as e:
        logger.error(f"Note generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/notes/transcribe")
async def transcribe_to_note(request: TranscribeRequest):
    """
    Convert voice/audio transcript to structured clinical note.
    Useful for doctors dictating notes.
    """
    try:
        logger.info(f"Transcribing note for patient: {request.patient_id}")
        
        gemini_service = get_gemini_service()
        
        prompt = f"""Convert this doctor's dictation into a structured {request.note_type} clinical note:

Transcript:
"{request.audio_transcript}"

Extract and organize into JSON format:
{{
    "chief_complaint": "Main reason for visit",
    "subjective": "Patient's history and symptoms",
    "objective": "Physical findings mentioned",
    "assessment": "Doctor's assessment/diagnosis",
    "plan": "Treatment plan",
    "medications": ["Any medications mentioned"],
    "follow_up": "Follow-up instructions"
}}

Maintain medical accuracy. Use professional terminology."""

        response = await gemini_service.generate_response(prompt)
        
        text = response.get("response", "") if isinstance(response, dict) else str(response)
        
        if "{" in text:
            json_str = text[text.find("{"):text.rfind("}")+1]
            data = json.loads(json_str)
            return {"status": "success", "structured_note": data}
        
        return {"status": "success", "structured_note": {"raw": text}}
        
    except Exception as e:
        logger.error(f"Transcription error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/notes/summarize")
async def summarize_notes(request: SummarizeRequest):
    """
    Summarize multiple clinical notes into a concise summary.
    Useful for patient handoffs, referrals, or discharge summaries.
    """
    try:
        logger.info(f"Summarizing notes for patient: {request.patient_id}")
        
        gemini_service = get_gemini_service()
        
        notes_text = "\n\n---\n\n".join(request.notes)
        
        summary_instructions = {
            "brief": "Provide a 3-4 sentence summary highlighting key diagnoses and current treatment.",
            "detailed": "Provide a comprehensive summary including history, diagnoses, treatments, and outcomes.",
            "discharge": "Create a discharge summary suitable for patient handoff including diagnoses, hospital course, medications, and follow-up instructions."
        }
        
        prompt = f"""Summarize these clinical notes for patient {request.patient_id}:

{notes_text}

Instructions: {summary_instructions.get(request.summary_type, summary_instructions['brief'])}

Format as JSON:
{{
    "summary": "The summary text",
    "key_diagnoses": ["Diagnosis 1", "Diagnosis 2"],
    "active_medications": ["Med 1", "Med 2"],
    "pending_items": ["Any pending tests or follow-ups"],
    "recommendations": ["Next steps"]
}}"""

        response = await gemini_service.generate_response(prompt)
        
        text = response.get("response", "") if isinstance(response, dict) else str(response)
        
        if "{" in text:
            json_str = text[text.find("{"):text.rfind("}")+1]
            data = json.loads(json_str)
            return {"status": "success", **data}
        
        return {"status": "success", "summary": text}
        
    except Exception as e:
        logger.error(f"Summarization error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/notes/templates")
async def get_note_templates():
    """
    Get available clinical note templates.
    """
    return {
        "status": "success",
        "templates": {
            "SOAP": {
                "name": "SOAP Note",
                "description": "Standard Subjective, Objective, Assessment, Plan format",
                "sections": ["Subjective", "Objective", "Assessment", "Plan"]
            },
            "Progress": {
                "name": "Progress Note",
                "description": "Follow-up visit documentation",
                "sections": ["Interval History", "Current Status", "Assessment", "Plan"]
            },
            "Consultation": {
                "name": "Consultation Note",
                "description": "Specialist consultation documentation",
                "sections": ["Reason for Consultation", "History", "Examination", "Impression", "Recommendations"]
            },
            "Discharge": {
                "name": "Discharge Summary",
                "description": "Hospital discharge documentation",
                "sections": ["Admission Diagnosis", "Hospital Course", "Discharge Diagnosis", "Discharge Medications", "Follow-up"]
            },
            "Procedure": {
                "name": "Procedure Note",
                "description": "Documentation of performed procedures",
                "sections": ["Procedure", "Indication", "Technique", "Findings", "Complications", "Disposition"]
            }
        }
    }
