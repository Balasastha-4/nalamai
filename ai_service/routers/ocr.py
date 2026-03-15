from fastapi import APIRouter, UploadFile, File, HTTPException, Form
import io
import json
import httpx
import os
from google import genai
from google.genai import types

router = APIRouter()

# Configuration
JAVA_BACKEND_URL = "http://localhost:8080/api"
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyCz8Fv51ZBI4lohGNLEbEtG-yPGYkaAQzw")

client = None
if GEMINI_API_KEY:
    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
    except Exception as e:
        print(f"Failed to initialize Gemini Client in OCR: {e}")

# --- 1. Agentic Tools for Billing Agent ---

async def verify_insurance_coverage(medicine_name: str) -> str:
    """
    Mocks an insurance API to check if a medicine is covered.
    Returns coverage percentage.
    """
    # Simple mock logic: 80% coverage for common names, 0% for others
    common_medicines = ["metformin", "aspirin", "insulin", "paracetamol", "amoxicillin"]
    if medicine_name.lower() in common_medicines:
        return json.dumps({"medicine": medicine_name, "covered": True, "coverage_percent": 80})
    return json.dumps({"medicine": medicine_name, "covered": False, "coverage_percent": 0})

async def create_hospital_bill(patient_id: int, items_list: list, total_amount: float, token: str = None) -> str:
    """
    Sends the parsed prescription items to the Spring Boot backend to generate a real invoice.
    'items_list' should be a list of dicts with 'name' and 'price'.
    """
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    async with httpx.AsyncClient() as httpx_client:
        try:
            payload = {
                "patientId": patient_id,
                "totalAmount": total_amount,
                "status": "PENDING",
                "itemsJson": json.dumps(items_list)
            }
            response = await httpx_client.post(
                f"{JAVA_BACKEND_URL}/billings/", 
                json=payload,
                headers=headers
            )
            if response.status_code == 200:
                return f"Invoice #{response.json().get('id')} generated successfully in the database."
            return f"Failed to generate bill: {response.text}"
        except Exception as e:
            return f"Database error: {str(e)}"

# --- 2. The OCR + Agentic Logic ---

@router.post("/")
async def process_prescription_and_bill(patient_id: str = Form(...), token: str = Form(None), file: UploadFile = File(...)):
    """
    Directly sends the prescription image to Gemini Vision.
    Gemini will perform OCR, parse the medical data, and execute billing tools.
    """
    print(f"DEBUG: Receiving OCR request for Patient ID: {patient_id}")
    print(f"DEBUG: File name: {file.filename}, Content Type: {file.content_type}")

    # Step 0: Ensure patient_id is valid integer (if required by DB tools)
    try:
        pid_int = int(patient_id)
    except ValueError:
        print(f"DEBUG: Non-integer Patient ID received ({patient_id}). Falling back to ID 1 for tools.")
        pid_int = 1

    # Soft check for image type
    if not file.content_type.startswith("image/"):
        print(f"Warning: Received file with content type {file.content_type}. Attempting to process as image anyway.")

    try:
        # Step 1: Read image bytes
        image_bytes = await file.read()
        
        if not client:
             return {"status": "error", "message": "API Key missing"}

        # Step 2: Agentic Parsing with Vision
        system_instruction = (
            "You are the Nalamai Billing Agent. You have DIRECT ACCESS to the medical database. "
            "You will be provided with an image of a medical prescription or bill. "
            "Your task is to: \n"
            "1. Look at the image and extract the medicine names, prices, and dosages.\n"
            "2. For each medicine, use 'verify_insurance_coverage' to check if it's covered.\n"
            "3. Calculate the final total after insurance.\n"
            "4. Use 'create_hospital_bill' to save this invoice in the system.\n"
            f"The Patient ID is: {patient_id}.\n"
            "Return a concise summary of what you found and the billing action taken."
        )

        tools = [verify_insurance_coverage, create_hospital_bill]
        
        chat = client.chats.create(
            model="gemini-2.0-flash",
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                tools=tools,
                temperature=0.1
            )
        )

        # Send both the text prompt and the image bytes
        # Inline data for small images; for larger images, consider a different approach
        response = chat.send_message([
            "Please analyze this prescription and generate a bill.",
            types.Part.from_bytes(data=image_bytes, mime_type=file.content_type)
        ])
        
        # Agentic Loop: Handle function calls
        for _ in range(5):
            if not response.function_calls:
                break
                
            tool_responses = []
            for function_call in response.function_calls:
                tool_name = function_call.name
                args = function_call.args
                result = ""
                
                if tool_name == "verify_insurance_coverage":
                    result = await verify_insurance_coverage(args.get("medicine_name"))
                elif tool_name == "create_hospital_bill":
                    result = await create_hospital_bill(
                        patient_id=pid_int,
                        items_list=args.get("items_list", []),
                        total_amount=float(args.get("total_amount", 0.0)),
                        token=token
                    )
                
                tool_responses.append(
                    types.Part.from_function_response(
                        name=tool_name,
                        response={"result": result}
                    )
                )
            
            response = chat.send_message(tool_responses)
        
        print(f"DEBUG: OCR successfully processed. Agent response: {response.text[:100]}...")
        return {
            "status": "success",
            "extracted_text": "Image analyzed by Gemini Vision.",
            "agent_response": response.text,
        }

    except Exception as e:
        print(f"Vision Billing Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Vision Agent Failed: {str(e)}")
