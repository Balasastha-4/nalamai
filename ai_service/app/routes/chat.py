"""
Chat endpoints with Gemini integration
"""

from datetime import datetime
from typing import Optional, List

from fastapi import APIRouter, HTTPException, Depends
from app.models.request_models import ChatRequest, ChatMessage
from app.models.response_models import ChatResponse
from app.services.gemini_service import get_gemini_service
from app.utils.logger import get_logger
from app.utils.validators import validate_token, raise_validation_error

logger = get_logger(__name__)
router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
async def chat_with_ai(request: ChatRequest):
    """
    Chat with AI assistant using Gemini

    Args:
        request: Chat request with patient context and message

    Returns:
        Chat response with AI message and suggested actions
    """
    try:
        # Validate input
        if not validate_token(request.token):
            raise_validation_error("Invalid authentication token", 401)

        # Get Gemini service
        gemini_service = get_gemini_service()

        logger.info(
            f"Processing chat request for patient: {request.patient_id}"
        )

        # Process chat with function calling
        result = await gemini_service.chat_with_function_calling(
            message=request.message,
            patient_id=request.patient_id,
            conversation_history=[
                {"role": msg.role, "content": msg.content}
                for msg in (request.conversation_history or [])
            ],
        )

        if result["status"] != "success":
            raise HTTPException(
                status_code=500,
                detail={
                    "status": "error",
                    "message": "Failed to process chat request",
                },
            )

        # Parse function calls if any
        function_calls = result.get("function_calls", [])
        suggested_actions = []

        for func_call in function_calls:
            try:
                action_result = await gemini_service.process_function_call(
                    func_call.get("name"), func_call.get("arguments", {})
                )
                suggested_actions.append(action_result)
            except Exception as e:
                logger.error(f"Error processing function call: {str(e)}")

        return ChatResponse(
            status="success",
            message=result.get("response", ""),
            suggested_actions=suggested_actions if suggested_actions else None,
            function_calls=function_calls if function_calls else None,
            timestamp=datetime.now().isoformat(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Internal server error",
                "error": str(e),
            },
        )


@router.post("/symptom-check")
async def check_symptoms(request: ChatRequest):
    """
    Check symptoms using AI analysis

    Args:
        request: Chat request with symptoms

    Returns:
        Symptom analysis
    """
    try:
        if not validate_token(request.token):
            raise_validation_error("Invalid authentication token", 401)

        # Extract symptoms from message
        # In production, parse structured symptom data
        symptoms = request.message.split(",")

        gemini_service = get_gemini_service()
        analysis = await gemini_service.analyze_symptoms(symptoms)

        return {
            "status": "success",
            "analysis": analysis,
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error in symptom check: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to analyze symptoms",
            },
        )


@router.post("/health-summary/{patient_id}")
async def generate_health_summary(patient_id: str, token: str):
    """
    Generate health summary for patient

    Args:
        patient_id: Patient's ID
        token: Authentication token

    Returns:
        Generated health summary
    """
    try:
        if not validate_token(token):
            raise_validation_error("Invalid authentication token", 401)

        gemini_service = get_gemini_service()

        # In production, fetch actual vital signs from backend
        vital_signs = {
            "heart_rate": 75,
            "blood_pressure": "120/80",
            "blood_oxygen": 98,
            "temperature": 37.0,
        }

        summary = await gemini_service.generate_health_summary(
            patient_id, vital_signs
        )

        return {
            "status": "success",
            "patient_id": patient_id,
            "summary": summary,
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error generating health summary: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Failed to generate health summary",
            },
        )
