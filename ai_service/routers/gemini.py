import os
import httpx
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from google import genai
from google.genai import types

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyCz8Fv51ZBI4lohGNLEbEtG-yPGYkaAQzw")
JAVA_BACKEND_URL = "http://localhost:8080/api"

# Initialize the new SDK Client
try:
    client = genai.Client(api_key=GEMINI_API_KEY)
except Exception as e:
    print(f"Failed to initialize Gemini Client: {e}")
    client = None

router = APIRouter()

class ChatRequest(BaseModel):
    message: str
    patient_id: str
    token: str = None
    vitals: dict = None

class ChatResponse(BaseModel):
    reply: str
    actions_taken: list = []

# --- 1. Define The "Tools" (Functions) the AI can call ---

async def fetch_my_appointments(patient_id: str, token: str = None) -> str:
    """
    Fetches all upcoming appointments for the current patient.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as httpx_client:
        try:
            response = await httpx_client.get(
                f"{JAVA_BACKEND_URL}/appointments/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return f"Error fetching appointments: {response.status_code}"
        except Exception as e:
            return f"Network error connecting to Java backend: {str(e)}"

async def book_appointment(patient_id: str, doctor_id: str, appointment_time: str, token: str = None, notes: str = "") -> str:
    """
    Books a new appointment for the patient. 
    'appointment_time' must be in ISO format (YYYY-MM-DDTHH:MM:SS) e.g., '2026-03-20T10:30:00'.
    'doctor_id' should be the ID of the doctor to book with.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as httpx_client:
        try:
            payload = {
                "patient_id": patient_id,
                "doctor_id": doctor_id,
                "appointment_time": appointment_time,
                "notes": notes
            }
            response = await httpx_client.post(
                f"{JAVA_BACKEND_URL}/appointments/", 
                json=payload,
                headers=headers
            )
            if response.status_code == 200:
                return "Appointment booked successfully!"
            return f"Failed to book appointment: {response.text}"
        except Exception as e:
            return f"Error booking appointment: {str(e)}"

async def fetch_my_medical_history(patient_id: str, token: str = None) -> str:
    """
    Retrieves the complete medical history and past records for the patient.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as httpx_client:
        try:
            response = await httpx_client.get(
                f"{JAVA_BACKEND_URL}/records/patient/{patient_id}",
                headers=headers
            )
            if response.status_code == 200:
                return json.dumps(response.json())
            return f"Error fetching records: {response.status_code}"
        except Exception as e:
            return f"Error fetching records: {str(e)}"

async def fetch_available_resources(token: str = None, resource_type: str = None) -> str:
    """
    Checks the status of medical equipment and resources (e.g., 'X-RAY', 'DENTAL_CHAIR').
    Returns a list of resources and their current status.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as httpx_client:
        try:
            url = f"{JAVA_BACKEND_URL}/resources"
            if resource_type:
                url += f"/type/{resource_type}"
            response = await httpx_client.get(url, headers=headers)
            if response.status_code == 200:
                return json.dumps(response.json())
            return f"Error fetching resources: {response.status_code}"
        except Exception as e:
            return f"Error connecting to Resource API: {str(e)}"

async def book_resource_appointment(patient_id: str, doctor_id: str, resource_id: int, appointment_time: str, token: str = None, notes: str = "") -> str:
    """
    Advanced booking that assigns a specific medical resource (like an X-ray room) to the appointment.
    'resource_id' must be the ID of the equipment to reserve.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as httpx_client:
        try:
            payload = {
                "patient_id": patient_id,
                "doctor_id": doctor_id,
                "resource_id": resource_id,
                "appointment_time": appointment_time,
                "notes": notes
            }
            response = await httpx_client.post(
                f"{JAVA_BACKEND_URL}/appointments/", 
                json=payload,
                headers=headers
            )
            if response.status_code == 200:
                return "Advanced appointment with resource booked successfully!"
            return f"Failed to book resource appointment: {response.text}"
        except Exception as e:
            return f"Error booking: {str(e)}"

# --- 2. The Main Agentic Loop Endpoint ---

@router.post("/", response_model=ChatResponse)
async def chat_with_agent(request: ChatRequest):
    if not client:
        raise HTTPException(status_code=500, detail="Gemini SDK not configured.")

    try:
        model = "gemini-2.0-flash" 
        
        system_instruction = (
            "You are the Nalamai Medical AI Assistant. You have DIRECT ACCESS to the hospital database. "
            "You MUST use your tools to answer patient questions. Do not say 'I cannot' if a tool exists. "
            f"The current user's Patient ID is: {request.patient_id}. "
            "1. If asked about appointments, call 'fetch_my_appointments'.\n"
            "2. If asked to book, call 'book_appointment' or 'book_resource_appointment'.\n"
            "3. If asked about history, call 'fetch_my_medical_history'.\n"
            "YOU ARE AUTHORIZED to perform these actions. Do not give generic medical advice instead of using tools."
        )
        if request.vitals:
             system_instruction += f"\nActive Vitals: {request.vitals}."
             
        tools = [
            fetch_my_appointments, 
            book_appointment, 
            fetch_my_medical_history,
            fetch_available_resources,
            book_resource_appointment
        ]
        
        chat = client.chats.create(
            model=model,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                tools=tools,
                temperature=0.1, # Lower for better tool consistency
            )
        )

        actions_taken = []
        response = chat.send_message(request.message)

        # Agentic Loop
        for _ in range(5): # Max iterations to prevent infinite loops
            if not response.function_calls:
                break
                
            tool_responses = []
            for function_call in response.function_calls:
                tool_name = function_call.name
                actions_taken.append(f"Used Tool: {tool_name}")
                args = function_call.args
                
                result = ""
                try:
                    if tool_name == "fetch_my_appointments":
                        result = await fetch_my_appointments(request.patient_id, token=request.token)
                    elif tool_name == "book_appointment":
                        result = await book_appointment(
                            patient_id=request.patient_id,
                            doctor_id=str(args.get("doctor_id", "1")),
                            appointment_time=args.get("appointment_time"),
                            token=request.token,
                            notes=args.get("notes", "User requested")
                        )
                    elif tool_name == "fetch_my_medical_history":
                        result = await fetch_my_medical_history(request.patient_id, token=request.token)
                    elif tool_name == "fetch_available_resources":
                        result = await fetch_available_resources(token=request.token, resource_type=args.get("resource_type"))
                    elif tool_name == "book_resource_appointment":
                        result = await book_resource_appointment(
                            patient_id=request.patient_id,
                            doctor_id=str(args.get("doctor_id", "1")),
                            resource_id=int(args.get("resource_id", 1)),
                            appointment_time=args.get("appointment_time"),
                            token=request.token,
                            notes=args.get("notes", "")
                        )
                except Exception as e:
                    result = f"Error: {str(e)}"
                
                tool_responses.append(
                    types.Part.from_function_response(
                        name=tool_name,
                        response={"result": result}
                    )
                )
            
            # Send all tool results back at once
            response = chat.send_message(tool_responses)

        return ChatResponse(
            reply=response.text,
            actions_taken=actions_taken
        )
        
    except Exception as e:
        print(f"Agentic Chat Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
