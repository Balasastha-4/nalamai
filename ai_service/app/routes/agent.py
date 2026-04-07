"""
Enhanced AI Agent endpoints - Comprehensive Google AI Agent with function calling
This is the main agentic AI that can perform actions across the entire system.
Integrates with the multi-agent preventive healthcare framework.
"""

import json
import httpx
from datetime import datetime
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from config import config
from app.services.gemini_service import get_gemini_service
from app.services.agentic_ai import AgentRegistry, AgentRole
from app.utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()

BACKEND_API_URL = config.BACKEND_API_URL


# ========== Models ==========

class AgentRequest(BaseModel):
    message: str
    patient_id: str
    user_role: str = "patient"  # patient, doctor, admin
    token: Optional[str] = None
    context: Optional[Dict[str, Any]] = None  # Additional context


class AgentAction(BaseModel):
    tool_name: str
    parameters: Dict[str, Any]
    result: str
    timestamp: str


class AgentResponse(BaseModel):
    status: str
    reply: str
    actions_taken: List[AgentAction]
    suggestions: List[str]
    requires_followup: bool


# ========== Tool Functions - No Hardcoded Data ==========

async def get_patient_vitals(patient_id: str, token: str = None) -> dict:
    """Get the latest vital signs for a patient from the backend."""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    headers["Content-Type"] = "application/json"
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            response = await http_client.get(
                f"{BACKEND_API_URL}/api/vitals/patient/{patient_id}/latest",
                headers=headers
            )
            if response.status_code == 200:
                return response.json()
            
            # Try to get the most recent from history
            response = await http_client.get(
                f"{BACKEND_API_URL}/api/vitals/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                vitals = response.json()
                if vitals and len(vitals) > 0:
                    return vitals[0]
                    
        except Exception as e:
            logger.error(f"Error fetching vitals: {e}")
    
    return {"error": "No vitals data available", "message": "Please record your vitals first"}


async def get_appointments(patient_id: str, user_role: str = "patient", token: str = None) -> list:
    """Fetch upcoming appointments for a patient or doctor from the backend."""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    headers["Content-Type"] = "application/json"
    
    endpoint = "doctor" if user_role == "doctor" else "patient"
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            response = await http_client.get(
                f"{BACKEND_API_URL}/api/appointments/{endpoint}/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Error fetching appointments: {e}")
    
    return []


async def get_medical_history(patient_id: str, token: str = None) -> list:
    """Retrieve the patient's medical history and past records from the backend."""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    headers["Content-Type"] = "application/json"
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            response = await http_client.get(
                f"{BACKEND_API_URL}/api/records/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Error fetching history: {e}")
    
    return []


async def book_appointment(patient_id: str, doctor_id: str, appointment_time: str, reason: str = "", token: str = None) -> str:
    """Book a new appointment using the Scheduling Agent."""
    # Use the agentic scheduling system
    scheduling_agent = AgentRegistry.get_agent_by_role(AgentRole.SCHEDULING)
    
    if scheduling_agent:
        try:
            result = await scheduling_agent.smart_schedule({
                "patient_id": patient_id,
                "doctor_id": doctor_id,
                "preferred_date": appointment_time[:10] if appointment_time else None,
                "preferred_time": appointment_time[11:16] if appointment_time and len(appointment_time) > 10 else None,
                "reason": reason,
                "token": token
            })
            
            if result.get("success"):
                return f"Appointment booked successfully for {result.get('appointment', {}).get('appointmentTime', appointment_time)}"
            else:
                return f"Could not book appointment: {result.get('error', 'Unknown error')}"
        except Exception as e:
            logger.error(f"Scheduling agent error: {e}")
    
    # Fallback to direct API call
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    headers["Content-Type"] = "application/json"
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            response = await http_client.post(
                f"{BACKEND_API_URL}/api/appointments/",
                json={
                    "patientId": int(patient_id),
                    "doctorId": int(doctor_id) if doctor_id else 1,
                    "appointmentTime": appointment_time,
                    "notes": reason
                },
                headers=headers
            )
            if response.status_code == 200:
                return "Appointment booked successfully!"
            return f"Failed to book appointment: {response.text}"
        except Exception as e:
            return f"Booking error: {str(e)}"


async def get_medications(patient_id: str, token: str = None) -> list:
    """Get list of current medications for a patient from the backend."""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    headers["Content-Type"] = "application/json"
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            response = await http_client.get(
                f"{BACKEND_API_URL}/api/medications/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Error fetching medications: {e}")
    
    return []


async def get_available_doctors(specialty: str = None, token: str = None) -> list:
    """Get list of available doctors from the backend."""
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    headers["Content-Type"] = "application/json"
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            url = f"{BACKEND_API_URL}/api/doctors"
            if specialty:
                url += f"?specialty={specialty}"
            
            response = await http_client.get(url, headers=headers)
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Error fetching doctors: {e}")
    
    return []


async def analyze_symptoms(symptoms: list, patient_id: str, token: str = None) -> dict:
    """Analyze patient symptoms using the AI service."""
    headers = {"Content-Type": "application/json"}
    
    async with httpx.AsyncClient(timeout=30.0) as http_client:
        try:
            response = await http_client.post(
                f"http://localhost:8000/api/ai/symptoms/check",
                json={
                    "patient_id": patient_id,
                    "symptoms": [{"name": s, "severity": "moderate"} for s in symptoms]
                },
                headers=headers
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Error analyzing symptoms: {e}")
    
    # Use predictive agent for risk assessment
    predictive_agent = AgentRegistry.get_agent_by_role(AgentRole.PREDICTIVE)
    if predictive_agent:
        try:
            risk = await predictive_agent.assess_health_risk({
                "patient_id": patient_id,
                "token": token
            })
            return {
                "assessment": f"Based on symptoms: {', '.join(symptoms)}",
                "risk_level": risk.get("risk_level", "unknown"),
                "recommendations": risk.get("recommendations", ["Please consult a healthcare provider"])
            }
        except Exception as e:
            logger.error(f"Predictive agent error: {e}")
    
    return {
        "assessment": f"Symptoms reported: {', '.join(symptoms)}. Please consult a healthcare provider for proper diagnosis.",
        "urgency": "routine",
        "recommendation": "Schedule an appointment with your doctor"
    }


async def predict_no_show(patient_id: str, token: str = None) -> dict:
    """Predict no-show probability using the Predictive Agent."""
    predictive_agent = AgentRegistry.get_agent_by_role(AgentRole.PREDICTIVE)
    
    if predictive_agent:
        try:
            result = await predictive_agent.predict_no_show({
                "patient_id": patient_id,
                "token": token
            })
            return result
        except Exception as e:
            logger.error(f"Predictive agent error: {e}")
    
    return {"error": "Prediction service not available"}


async def get_health_risk(patient_id: str, token: str = None) -> dict:
    """Get health risk assessment using the Predictive Agent."""
    predictive_agent = AgentRegistry.get_agent_by_role(AgentRole.PREDICTIVE)
    
    if predictive_agent:
        try:
            result = await predictive_agent.assess_health_risk({
                "patient_id": patient_id,
                "token": token
            })
            return result
        except Exception as e:
            logger.error(f"Predictive agent error: {e}")
    
    return {"error": "Risk assessment service not available"}


# ========== Agent Logic ==========

def get_tool_definitions():
    """Get the tool definitions for Gemini function calling."""
    return [
        {
            "name": "get_patient_vitals",
            "description": "Get the latest vital signs for a patient including heart rate, blood pressure, SpO2, and temperature.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient's ID"}
                },
                "required": ["patient_id"]
            }
        },
        {
            "name": "get_appointments",
            "description": "Fetch upcoming appointments for a patient or doctor.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient or doctor ID"},
                    "user_role": {"type": "string", "enum": ["patient", "doctor"], "description": "User role"}
                },
                "required": ["patient_id"]
            }
        },
        {
            "name": "get_medical_history",
            "description": "Retrieve the patient's medical history and past records.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient's ID"}
                },
                "required": ["patient_id"]
            }
        },
        {
            "name": "book_appointment",
            "description": "Book a new appointment with a doctor. Uses smart scheduling to find the best available slot.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient's ID"},
                    "doctor_id": {"type": "string", "description": "The doctor's ID"},
                    "appointment_time": {"type": "string", "description": "Preferred appointment time in ISO format"},
                    "reason": {"type": "string", "description": "Reason for the appointment"}
                },
                "required": ["patient_id", "doctor_id", "appointment_time"]
            }
        },
        {
            "name": "get_medications",
            "description": "Get list of current medications for a patient.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient's ID"}
                },
                "required": ["patient_id"]
            }
        },
        {
            "name": "get_available_doctors",
            "description": "Get list of available doctors, optionally filtered by specialty.",
            "parameters": {
                "type": "object",
                "properties": {
                    "specialty": {"type": "string", "description": "Medical specialty to filter by"}
                }
            }
        },
        {
            "name": "analyze_symptoms",
            "description": "Analyze patient symptoms and provide preliminary assessment with risk evaluation.",
            "parameters": {
                "type": "object",
                "properties": {
                    "symptoms": {"type": "array", "items": {"type": "string"}, "description": "List of symptoms"},
                    "patient_id": {"type": "string", "description": "The patient's ID"}
                },
                "required": ["symptoms"]
            }
        },
        {
            "name": "get_health_risk",
            "description": "Get health risk assessment based on patient vitals and history.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient's ID"}
                },
                "required": ["patient_id"]
            }
        },
        {
            "name": "predict_no_show",
            "description": "Predict the probability of a patient not showing up for an appointment.",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "string", "description": "The patient's ID"}
                },
                "required": ["patient_id"]
            }
        }
    ]


async def execute_tool(tool_name: str, args: dict, patient_id: str, token: str = None, user_role: str = "patient") -> str:
    """Execute a tool and return the result."""
    try:
        if tool_name == "get_patient_vitals":
            result = await get_patient_vitals(args.get("patient_id", patient_id), token)
            return json.dumps(result)
        
        elif tool_name == "get_appointments":
            result = await get_appointments(args.get("patient_id", patient_id), args.get("user_role", user_role), token)
            if result:
                return json.dumps(result)
            return "No upcoming appointments found. Would you like to schedule one?"
        
        elif tool_name == "get_medical_history":
            result = await get_medical_history(args.get("patient_id", patient_id), token)
            if result:
                return json.dumps(result)
            return "No medical history records found."
        
        elif tool_name == "book_appointment":
            return await book_appointment(
                args.get("patient_id", patient_id),
                args.get("doctor_id", "1"),
                args.get("appointment_time", ""),
                args.get("reason", ""),
                token
            )
        
        elif tool_name == "get_medications":
            result = await get_medications(args.get("patient_id", patient_id), token)
            if result:
                return json.dumps(result)
            return "No active medications found."
        
        elif tool_name == "get_available_doctors":
            result = await get_available_doctors(args.get("specialty"), token)
            if result:
                return json.dumps(result)
            return "No doctors found matching your criteria."
        
        elif tool_name == "analyze_symptoms":
            symptoms = args.get("symptoms", [])
            result = await analyze_symptoms(symptoms, args.get("patient_id", patient_id), token)
            return json.dumps(result)
        
        elif tool_name == "get_health_risk":
            result = await get_health_risk(args.get("patient_id", patient_id), token)
            return json.dumps(result)
        
        elif tool_name == "predict_no_show":
            result = await predict_no_show(args.get("patient_id", patient_id), token)
            return json.dumps(result)
        
        else:
            return f"Unknown tool: {tool_name}"
            
    except Exception as e:
        logger.error(f"Tool execution error: {e}")
        return f"Error executing {tool_name}: {str(e)}"


# ========== Endpoints ==========

@router.post("/agent", response_model=AgentResponse)
async def agent_chat(request: AgentRequest):
    """
    Main AI Agent endpoint with comprehensive function calling capabilities.
    The agent can perform various actions based on user role and request.
    Integrates with the multi-agent preventive healthcare system.
    """
    try:
        logger.info(f"Agent request from {request.user_role}: {request.patient_id}")
        
        gemini_service = get_gemini_service()
        
        # Build system instruction
        role_instructions = {
            "patient": """You are Nalamai Medical AI Assistant helping a PATIENT with preventive healthcare.
You can help with: checking vitals, booking appointments (with smart scheduling), medication reminders, symptom analysis, viewing medical history, health risk assessment, and preventive care planning.
Always be empathetic and accurate. Use real data from the backend - never make up information. Recommend professional care for serious issues.""",
            
            "doctor": """You are Nalamai Medical AI Assistant helping a DOCTOR with preventive healthcare.
You can help with: viewing patient lists, creating clinical notes, checking patient vitals, managing appointments, health risk assessment, and no-show predictions.
Be professional and concise. Support clinical decision-making with real data.""",
        }
        
        system_instruction = role_instructions.get(request.user_role, role_instructions["patient"])
        system_instruction += f"""

Current User ID: {request.patient_id}
User Role: {request.user_role}

IMPORTANT RULES:
1. ALWAYS use tools when the user asks for data - never make up information.
2. If data is not available, inform the user clearly.
3. For appointments, use the smart scheduling feature.
4. For health concerns, recommend professional consultation.
5. Provide actionable next steps in your responses."""
        
        if request.context:
            system_instruction += f"\nContext: {json.dumps(request.context)}"
        
        # Get AI response with function calling
        result = await gemini_service.chat_with_function_calling(
            message=request.message,
            patient_id=request.patient_id,
            system_instruction=system_instruction,
            tools=get_tool_definitions()
        )
        
        actions_taken = []
        
        # Process function calls if any
        if result.get("function_calls"):
            for func_call in result["function_calls"]:
                tool_name = func_call.get("name", "")
                args = func_call.get("arguments", {})
                
                # Execute the tool
                tool_result = await execute_tool(
                    tool_name, args, request.patient_id, request.token, request.user_role
                )
                
                actions_taken.append(AgentAction(
                    tool_name=tool_name,
                    parameters=args,
                    result=tool_result[:500],  # Truncate long results
                    timestamp=datetime.now().isoformat()
                ))
        
        # Generate contextual suggestions
        suggestions = []
        if request.user_role == "patient":
            suggestions = [
                "Check my vitals",
                "Book a preventive care appointment",
                "View medical history",
                "Get health risk assessment"
            ]
        elif request.user_role == "doctor":
            suggestions = [
                "View my patients",
                "Check no-show predictions",
                "Create clinical note",
                "View today's appointments"
            ]
        
        return AgentResponse(
            status="success",
            reply=result.get("response", "I'm here to help with your healthcare needs. How can I assist you?"),
            actions_taken=actions_taken,
            suggestions=suggestions[:4],
            requires_followup=len(actions_taken) > 0
        )
        
    except Exception as e:
        logger.error(f"Agent error: {e}", exc_info=e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/agent/capabilities")
async def get_agent_capabilities():
    """
    Get list of all agent capabilities and available tools.
    """
    # Get agent states
    agent_states = AgentRegistry.get_all_states()
    
    return {
        "status": "success",
        "capabilities": {
            "patient": [
                "Check vital signs (real-time data)",
                "Record vital readings",
                "Get health risk assessment",
                "Analyze symptoms",
                "Smart appointment scheduling",
                "View medical history",
                "Medication management",
                "Health analytics",
                "Preventive care planning"
            ],
            "doctor": [
                "All patient capabilities",
                "View patient list",
                "Create clinical notes",
                "Access patient records",
                "No-show predictions",
                "Workflow optimization"
            ]
        },
        "agentic_system": {
            "active_agents": len(agent_states),
            "agents": list(agent_states.keys()) if agent_states else []
        },
        "tools": get_tool_definitions()
    }


@router.post("/agent/quick-action")
async def quick_action(action: str, patient_id: str, params: Optional[Dict[str, Any]] = None, token: Optional[str] = None):
    """
    Execute a quick action without full conversation context.
    """
    try:
        params = params or {}
        result = await execute_tool(action, params, patient_id, token)
        
        # Try to parse as JSON, otherwise return as string
        try:
            parsed_result = json.loads(result)
        except (json.JSONDecodeError, TypeError):
            parsed_result = result
        
        return {
            "status": "success",
            "action": action,
            "result": parsed_result
        }
    except Exception as e:
        logger.error(f"Quick action error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
