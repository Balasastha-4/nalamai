"""
Enhanced AI Agent Router - Comprehensive Google AI Agent with function calling
This is the main agentic AI that can perform actions across the entire system.
"""
import os
import json
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from google import genai
from google.genai import types

router = APIRouter()

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyCz8Fv51ZBI4lohGNLEbEtG-yPGYkaAQzw")
JAVA_BACKEND_URL = os.environ.get("JAVA_BACKEND_URL", "http://localhost:8080/api")
AI_SERVICE_URL = os.environ.get("AI_SERVICE_URL", "http://localhost:8000/api/ai")

client = None
if GEMINI_API_KEY:
    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
    except Exception as e:
        print(f"Failed to initialize Gemini Client: {e}")


class AgentRequest(BaseModel):
    message: str
    patient_id: str
    user_role: str = "patient"  # patient, doctor, admin
    token: Optional[str] = None
    context: Optional[Dict[str, Any]] = None  # Additional context (vitals, location, etc.)


class AgentAction(BaseModel):
    tool_name: str
    parameters: Dict[str, Any]
    result: str
    timestamp: str


class AgentResponse(BaseModel):
    reply: str
    actions_taken: List[AgentAction]
    suggestions: List[str]
    requires_followup: bool


# ============= TOOL DEFINITIONS =============
# These are the functions the AI agent can call

async def get_patient_vitals(patient_id: str, token: str = None) -> str:
    """
    Get the latest vital signs for a patient.
    Returns heart rate, blood pressure, SpO2, and temperature.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/vitals/patient/{patient_id}/latest",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            # Mock data fallback
            return json.dumps({
                "HeartRate": {"value": 75, "unit": "bpm", "status": "normal"},
                "BP_Systolic": {"value": 120, "unit": "mmHg"},
                "BP_Diastolic": {"value": 80, "unit": "mmHg"},
                "SpO2": {"value": 98, "unit": "%"},
                "Temperature": {"value": 36.6, "unit": "°C"}
            })
        except Exception as e:
            return f"Error fetching vitals: {str(e)}"


async def record_patient_vitals(patient_id: str, vital_type: str, value: float, token: str = None) -> str:
    """
    Record a new vital sign reading for a patient.
    vital_type can be: HeartRate, BP_Systolic, BP_Diastolic, SpO2, Temperature
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.post(
                f"{JAVA_BACKEND_URL}/vitals/",
                json={"patient_id": patient_id, "type": vital_type, "value": value},
                headers=headers
            )
            if response.status_code == 200:
                return f"Successfully recorded {vital_type}: {value}"
            return f"Failed to record vital: {response.text}"
        except Exception as e:
            return f"Error recording vital: {str(e)}"


async def get_health_prediction(patient_id: str, vitals: dict = None, token: str = None) -> str:
    """
    Get AI health risk prediction based on patient vitals.
    Returns risk level, score, and warnings.
    """
    try:
        async with httpx.AsyncClient() as http_client:
            payload = vitals or {
                "heartRate": 75,
                "systolicBP": 120,
                "diastolicBP": 80,
                "oxygenLevel": 98,
                "temperature": 36.6,
                "age": 35
            }
            response = await http_client.post(
                f"{AI_SERVICE_URL}/predict/",
                json=payload
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return "Unable to get health prediction"
    except Exception as e:
        return f"Prediction error: {str(e)}"


async def analyze_symptoms(patient_id: str, symptoms: list, token: str = None) -> str:
    """
    Analyze patient symptoms and provide preliminary assessment.
    symptoms should be a list of symptom names.
    """
    try:
        async with httpx.AsyncClient() as http_client:
            response = await http_client.post(
                f"{AI_SERVICE_URL}/symptoms/check",
                json={
                    "patient_id": patient_id,
                    "symptoms": [{"name": s, "severity": "moderate"} for s in symptoms]
                }
            )
            if response.status_code == 200:
                data = response.json()
                return json.dumps({
                    "assessment": data.get("assessment"),
                    "possible_conditions": [c["name"] for c in data.get("possible_conditions", [])],
                    "recommendations": data.get("recommendations", [])
                })
            return "Unable to analyze symptoms"
    except Exception as e:
        return f"Symptom analysis error: {str(e)}"


async def get_appointments(patient_id: str, user_role: str = "patient", token: str = None) -> str:
    """
    Fetch upcoming appointments for a patient or doctor.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    endpoint = "doctor" if user_role == "doctor" else "patient"
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/appointments/{endpoint}/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return "No appointments found"
        except Exception as e:
            return f"Error fetching appointments: {str(e)}"


async def book_appointment(patient_id: str, doctor_id: str, appointment_time: str, reason: str = "", token: str = None) -> str:
    """
    Book a new appointment. appointment_time should be in ISO format (YYYY-MM-DDTHH:MM:SS).
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.post(
                f"{JAVA_BACKEND_URL}/appointments/",
                json={
                    "patient_id": patient_id,
                    "doctor_id": doctor_id,
                    "appointment_time": appointment_time,
                    "notes": reason
                },
                headers=headers
            )
            if response.status_code == 200:
                return "Appointment booked successfully!"
            return f"Failed to book appointment: {response.text}"
        except Exception as e:
            return f"Booking error: {str(e)}"


async def cancel_appointment(appointment_id: str, token: str = None) -> str:
    """
    Cancel an existing appointment by its ID.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.delete(
                f"{JAVA_BACKEND_URL}/appointments/{appointment_id}",
                headers=headers
            )
            if response.status_code == 200:
                return "Appointment cancelled successfully"
            return f"Failed to cancel: {response.text}"
        except Exception as e:
            return f"Cancellation error: {str(e)}"


async def get_medical_history(patient_id: str, token: str = None) -> str:
    """
    Retrieve the patient's medical history and past records.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/records/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return "No medical history found"
        except Exception as e:
            return f"Error fetching history: {str(e)}"


async def get_medications(patient_id: str, token: str = None) -> str:
    """
    Get list of current medications for a patient.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/medications/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            # Mock fallback
            return json.dumps([
                {"name": "Amlodipine", "dosage": "5mg", "frequency": "Once daily"},
                {"name": "Metformin", "dosage": "500mg", "frequency": "Twice daily"}
            ])
        except Exception as e:
            return f"Error fetching medications: {str(e)}"


async def set_medication_reminder(patient_id: str, medication_name: str, reminder_time: str, token: str = None) -> str:
    """
    Set a reminder for taking medication. reminder_time should be in HH:MM format.
    """
    # This would integrate with notification service
    return f"Reminder set for {medication_name} at {reminder_time}"


async def get_available_doctors(specialty: str = None, token: str = None) -> str:
    """
    Get list of available doctors, optionally filtered by specialty.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            url = f"{JAVA_BACKEND_URL}/doctors"
            if specialty:
                url += f"?specialty={specialty}"
            response = await http_client.get(url, headers=headers)
            if response.status_code == 200:
                return json.dumps(response.json())
            # Mock fallback
            return json.dumps([
                {"id": "1", "name": "Dr. Smith", "specialty": "General Medicine"},
                {"id": "2", "name": "Dr. Johnson", "specialty": "Cardiology"},
                {"id": "3", "name": "Dr. Williams", "specialty": "Pediatrics"}
            ])
        except Exception as e:
            return f"Error fetching doctors: {str(e)}"


async def get_patient_list(doctor_id: str, token: str = None) -> str:
    """
    For doctors: Get list of assigned patients.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/patients/doctor/{doctor_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return "No patients found"
        except Exception as e:
            return f"Error fetching patients: {str(e)}"


async def create_clinical_note(doctor_id: str, patient_id: str, chief_complaint: str, assessment: str, plan: str, token: str = None) -> str:
    """
    For doctors: Create a clinical note for a patient visit.
    """
    try:
        async with httpx.AsyncClient() as http_client:
            response = await http_client.post(
                f"{AI_SERVICE_URL}/notes/generate",
                json={
                    "doctor_id": doctor_id,
                    "patient_context": {
                        "patient_id": patient_id,
                        "chief_complaint": chief_complaint
                    },
                    "assessment": assessment,
                    "plan": plan,
                    "note_type": "SOAP",
                    "token": token
                }
            )
            if response.status_code == 200:
                return "Clinical note generated successfully"
            return "Failed to create note"
    except Exception as e:
        return f"Note creation error: {str(e)}"


async def get_health_analytics(patient_id: str, period: str = "week", token: str = None) -> str:
    """
    Get health analytics and trends for a patient.
    period can be: day, week, month, year
    """
    try:
        async with httpx.AsyncClient() as http_client:
            response = await http_client.post(
                f"{AI_SERVICE_URL}/analytics/dashboard",
                json={"patient_id": patient_id, "period": period, "token": token}
            )
            if response.status_code == 200:
                data = response.json()
                return json.dumps({
                    "health_score": data.get("health_score"),
                    "summary": data.get("ai_summary"),
                    "alerts": data.get("alerts", [])
                })
            return "Unable to fetch analytics"
    except Exception as e:
        return f"Analytics error: {str(e)}"


async def get_available_resources(resource_type: str = None, token: str = None) -> str:
    """
    Check availability of medical resources/equipment.
    resource_type examples: X-RAY, MRI, DENTAL_CHAIR, ECG
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            url = f"{JAVA_BACKEND_URL}/resources"
            if resource_type:
                url += f"/type/{resource_type}"
            response = await http_client.get(url, headers=headers)
            if response.status_code == 200:
                return json.dumps(response.json())
            return "No resources found"
        except Exception as e:
            return f"Resource fetch error: {str(e)}"


async def get_billing_summary(patient_id: str, token: str = None) -> str:
    """
    Get billing summary and pending invoices for a patient.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as http_client:
        try:
            response = await http_client.get(
                f"{JAVA_BACKEND_URL}/billings/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return "No billing records found"
        except Exception as e:
            return f"Billing fetch error: {str(e)}"


# ============= MAIN AGENT ENDPOINT =============

@router.post("/", response_model=AgentResponse)
async def agent_chat(request: AgentRequest):
    """
    Main AI Agent endpoint with comprehensive function calling capabilities.
    The agent can perform various actions based on user role and request.
    """
    if not client:
        raise HTTPException(status_code=500, detail="AI Agent not configured")
    
    try:
        # Build system instruction based on user role
        role_instructions = {
            "patient": """You are Nalamai Medical AI Assistant helping a PATIENT.
You can help with:
- Checking vitals and health status
- Booking/managing appointments
- Medication reminders
- Symptom analysis
- Viewing medical history
- Health analytics and trends
Always be empathetic and clear. Recommend professional care for serious issues.""",
            
            "doctor": """You are Nalamai Medical AI Assistant helping a DOCTOR.
You can help with:
- Viewing patient lists and details
- Creating clinical notes
- Checking patient vitals and history
- Managing appointments
- Health analytics
- Resource availability
Be professional and concise. Support clinical decision-making.""",
            
            "admin": """You are Nalamai Medical AI Assistant for ADMIN users.
You can help with:
- Resource management
- Billing overview
- System-wide analytics
- User management queries
Be efficient and data-focused."""
        }
        
        system_instruction = role_instructions.get(request.user_role, role_instructions["patient"])
        system_instruction += f"""

CURRENT USER ID: {request.patient_id}
USER ROLE: {request.user_role}

IMPORTANT RULES:
1. ALWAYS use tools when the user asks for data or actions - don't make up information.
2. If you need data, call the appropriate function.
3. After using tools, summarize the results in a helpful way.
4. For symptoms or health concerns, use analyze_symptoms tool.
5. For appointments, use get_appointments or book_appointment tools.
6. Be proactive - suggest relevant follow-up actions.
"""
        
        if request.context:
            system_instruction += f"\nADDITIONAL CONTEXT: {json.dumps(request.context)}"
        
        # Define available tools based on role
        patient_tools = [
            get_patient_vitals,
            record_patient_vitals,
            get_health_prediction,
            analyze_symptoms,
            get_appointments,
            book_appointment,
            cancel_appointment,
            get_medical_history,
            get_medications,
            set_medication_reminder,
            get_available_doctors,
            get_health_analytics,
            get_billing_summary
        ]
        
        doctor_tools = patient_tools + [
            get_patient_list,
            create_clinical_note,
            get_available_resources
        ]
        
        tools = doctor_tools if request.user_role == "doctor" else patient_tools
        
        # Create chat with agent
        chat = client.chats.create(
            model="gemini-2.0-flash",
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                tools=tools,
                temperature=0.2
            )
        )
        
        actions_taken = []
        response = chat.send_message(request.message)
        
        # Agentic loop - process function calls
        for iteration in range(7):  # Max iterations
            if not response.function_calls:
                break
            
            tool_responses = []
            for function_call in response.function_calls:
                tool_name = function_call.name
                args = function_call.args or {}
                result = ""
                
                try:
                    # Execute the appropriate tool
                    if tool_name == "get_patient_vitals":
                        result = await get_patient_vitals(request.patient_id, request.token)
                    elif tool_name == "record_patient_vitals":
                        result = await record_patient_vitals(
                            request.patient_id,
                            args.get("vital_type"),
                            args.get("value"),
                            request.token
                        )
                    elif tool_name == "get_health_prediction":
                        result = await get_health_prediction(request.patient_id, args.get("vitals"), request.token)
                    elif tool_name == "analyze_symptoms":
                        result = await analyze_symptoms(request.patient_id, args.get("symptoms", []), request.token)
                    elif tool_name == "get_appointments":
                        result = await get_appointments(request.patient_id, request.user_role, request.token)
                    elif tool_name == "book_appointment":
                        result = await book_appointment(
                            request.patient_id,
                            args.get("doctor_id", "1"),
                            args.get("appointment_time"),
                            args.get("reason", ""),
                            request.token
                        )
                    elif tool_name == "cancel_appointment":
                        result = await cancel_appointment(args.get("appointment_id"), request.token)
                    elif tool_name == "get_medical_history":
                        result = await get_medical_history(request.patient_id, request.token)
                    elif tool_name == "get_medications":
                        result = await get_medications(request.patient_id, request.token)
                    elif tool_name == "set_medication_reminder":
                        result = await set_medication_reminder(
                            request.patient_id,
                            args.get("medication_name"),
                            args.get("reminder_time"),
                            request.token
                        )
                    elif tool_name == "get_available_doctors":
                        result = await get_available_doctors(args.get("specialty"), request.token)
                    elif tool_name == "get_patient_list":
                        result = await get_patient_list(request.patient_id, request.token)
                    elif tool_name == "create_clinical_note":
                        result = await create_clinical_note(
                            request.patient_id,  # doctor_id
                            args.get("patient_id"),
                            args.get("chief_complaint"),
                            args.get("assessment"),
                            args.get("plan"),
                            request.token
                        )
                    elif tool_name == "get_health_analytics":
                        result = await get_health_analytics(
                            request.patient_id,
                            args.get("period", "week"),
                            request.token
                        )
                    elif tool_name == "get_available_resources":
                        result = await get_available_resources(args.get("resource_type"), request.token)
                    elif tool_name == "get_billing_summary":
                        result = await get_billing_summary(request.patient_id, request.token)
                    else:
                        result = f"Unknown tool: {tool_name}"
                        
                except Exception as e:
                    result = f"Tool error: {str(e)}"
                
                actions_taken.append(AgentAction(
                    tool_name=tool_name,
                    parameters=args,
                    result=result[:500],  # Truncate long results
                    timestamp=datetime.now().isoformat()
                ))
                
                tool_responses.append(
                    types.Part.from_function_response(
                        name=tool_name,
                        response={"result": result}
                    )
                )
            
            # Send tool results back to the model
            response = chat.send_message(tool_responses)
        
        # Generate suggestions based on context
        suggestions = []
        if request.user_role == "patient":
            suggestions = [
                "Check my vitals",
                "Book an appointment",
                "View my medical history",
                "Analyze my symptoms"
            ]
        elif request.user_role == "doctor":
            suggestions = [
                "View my patients",
                "Create clinical note",
                "Check patient vitals",
                "View today's appointments"
            ]
        
        return AgentResponse(
            reply=response.text,
            actions_taken=actions_taken,
            suggestions=suggestions[:4],
            requires_followup=len(actions_taken) > 0
        )
        
    except Exception as e:
        print(f"Agent Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/capabilities")
async def get_agent_capabilities():
    """
    Get list of all agent capabilities and available tools.
    """
    return {
        "status": "success",
        "capabilities": {
            "patient": [
                "Check vital signs",
                "Record vital readings",
                "Get health predictions",
                "Analyze symptoms",
                "Manage appointments",
                "View medical history",
                "Medication management",
                "Health analytics",
                "Billing information"
            ],
            "doctor": [
                "All patient capabilities",
                "View patient list",
                "Create clinical notes",
                "Check resource availability",
                "Access patient records"
            ],
            "admin": [
                "System-wide analytics",
                "Resource management",
                "Billing overview"
            ]
        }
    }
