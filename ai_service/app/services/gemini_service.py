"""
Google Gemini AI Service Integration
"""

import logging
from typing import Optional, List, Dict, Any
from config import config
from app.utils.logger import get_logger

logger = get_logger(__name__)


class GeminiService:
    """Service for interacting with Google Generative AI (Gemini)"""

    def __init__(self):
        """Initialize Gemini service"""
        if not config.GOOGLE_API_KEY:
            raise ValueError("GOOGLE_API_KEY environment variable is not set")

        try:
            import google.generativeai as genai
        except ImportError as e:
            raise ImportError(
                "google-generativeai package is not installed. "
                "Install it with: pip install google-generativeai"
            ) from e

        genai.configure(api_key=config.GOOGLE_API_KEY)
        self.model = genai.GenerativeModel(config.GEMINI_MODEL)
        self.tools = self._initialize_tools()
        logger.info(f"Initialized Gemini service with model: {config.GEMINI_MODEL}")

    def _initialize_tools(self) -> List[Dict[str, Any]]:
        """
        Initialize tool definitions for Gemini function calling

        Returns:
            List of tool definitions
        """
        return [
            {
                "name": "book_appointment",
                "description": "Book a medical appointment for the patient",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "doctor_id": {
                            "type": "string",
                            "description": "ID of the doctor",
                        },
                        "date": {
                            "type": "string",
                            "description": "Appointment date (YYYY-MM-DD)",
                        },
                        "time": {
                            "type": "string",
                            "description": "Appointment time (HH:MM)",
                        },
                        "reason": {
                            "type": "string",
                            "description": "Reason for appointment",
                        },
                    },
                    "required": ["doctor_id", "date", "time", "reason"],
                },
            },
            {
                "name": "get_patient_vitals",
                "description": "Get the latest vital signs for the patient",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "patient_id": {
                            "type": "string",
                            "description": "Patient ID",
                        },
                        "limit": {
                            "type": "integer",
                            "description": "Number of records to fetch",
                            "default": 10,
                        },
                    },
                    "required": ["patient_id"],
                },
            },
            {
                "name": "check_symptoms",
                "description": "Check symptoms and provide preliminary assessment",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "symptoms": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "List of symptoms",
                        },
                        "duration": {
                            "type": "string",
                            "description": "Duration of symptoms",
                        },
                    },
                    "required": ["symptoms"],
                },
            },
            {
                "name": "extract_medicines_from_prescription",
                "description": "Extract medicines from a prescription document",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "document_id": {
                            "type": "string",
                            "description": "Document ID of the prescription",
                        },
                    },
                    "required": ["document_id"],
                },
            },
            {
                "name": "predict_health_risk",
                "description": "Predict health risk based on vital signs and medical history",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "patient_id": {
                            "type": "string",
                            "description": "Patient ID",
                        },
                    },
                    "required": ["patient_id"],
                },
            },
            {
                "name": "get_health_tips",
                "description": "Get personalized health tips for the patient",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "category": {
                            "type": "string",
                            "description": "Category of health tips (diet, exercise, sleep, etc)",
                        },
                        "limit": {
                            "type": "integer",
                            "description": "Number of tips to fetch",
                            "default": 3,
                        },
                    },
                    "required": ["category"],
                },
            },
        ]

    async def chat_with_function_calling(
        self,
        message: str,
        patient_id: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        system_instruction: Optional[str] = None,
        tools: Optional[List[Dict[str, Any]]] = None,
    ) -> Dict[str, Any]:
        """
        Chat with Gemini using function calling

        Args:
            message: User message
            patient_id: Patient ID for context
            conversation_history: Previous messages
            system_instruction: Custom system instruction
            tools: Tool definitions for function calling

        Returns:
            Response with function calls
        """
        try:
            # Use provided tools or default tools
            tool_definitions = tools or self.tools
            
            # Create system prompt with patient context
            system_prompt = system_instruction or f"""You are a healthcare AI assistant for the NalaMAI platform.
You are helping patient {patient_id} with health-related queries and recommendations.
Be empathetic, professional, and accurate in your responses.
When appropriate, use the available tools to help the patient.
Always prioritize patient safety and recommend professional medical consultation when needed."""

            # Build full prompt
            full_prompt = f"{system_prompt}\n\nUser: {message}"
            
            # Convert tool definitions to Gemini format
            gemini_tools = []
            if tool_definitions:
                function_declarations = []
                for tool in tool_definitions:
                    func_decl = {
                        "name": tool.get("name", ""),
                        "description": tool.get("description", ""),
                        "parameters": tool.get("parameters", tool.get("input_schema", {}))
                    }
                    function_declarations.append(func_decl)
                
                if function_declarations:
                    gemini_tools = [{"function_declarations": function_declarations}]

            # Call Gemini with function calling
            if gemini_tools:
                response = self.model.generate_content(
                    full_prompt,
                    tools=gemini_tools,
                )
            else:
                response = self.model.generate_content(full_prompt)

            # Parse response for function calls
            function_calls = []
            response_text = ""
            
            if response and response.candidates:
                for candidate in response.candidates:
                    if candidate.content and candidate.content.parts:
                        for part in candidate.content.parts:
                            # Check for function call
                            if hasattr(part, 'function_call') and part.function_call:
                                func_call = part.function_call
                                function_calls.append({
                                    "name": func_call.name,
                                    "arguments": dict(func_call.args) if func_call.args else {}
                                })
                            # Check for text response
                            elif hasattr(part, 'text') and part.text:
                                response_text += part.text

            return {
                "status": "success",
                "response": response_text or (response.text if hasattr(response, 'text') else ""),
                "function_calls": function_calls,
            }

        except Exception as e:
            logger.error(f"Error in chat_with_function_calling: {str(e)}", exc_info=e)
            raise

    async def process_function_call(
        self, function_name: str, arguments: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Process function calls from Gemini

        Args:
            function_name: Name of the function to call
            arguments: Function arguments

        Returns:
            Function result
        """
        logger.info(f"Processing function call: {function_name}")

        # Function call processing is handled in function_handler.py
        from app.services.function_handler import FunctionHandler

        handler = FunctionHandler()
        return await handler.handle_function_call(function_name, arguments)

    async def generate_health_summary(
        self, patient_id: str, vital_signs: Dict[str, Any]
    ) -> str:
        """
        Generate health summary using Gemini

        Args:
            patient_id: Patient ID
            vital_signs: Patient's vital signs

        Returns:
            Generated health summary
        """
        try:
            prompt = f"""Based on the following vital signs for patient {patient_id},
generate a brief health summary with key observations and recommendations:

Vital Signs: {vital_signs}

Please provide:
1. Overall health assessment
2. Key observations
3. Recommendations
4. When to seek immediate medical attention"""

            response = self.model.generate_content(prompt)
            return response.text if response else ""

        except Exception as e:
            logger.error(f"Error generating health summary: {str(e)}", exc_info=e)
            raise

    async def generate_response(self, prompt: str) -> Dict[str, Any]:
        """
        Generate a simple response from Gemini

        Args:
            prompt: The prompt to send to Gemini

        Returns:
            Response dict with 'response' key
        """
        try:
            response = self.model.generate_content(prompt)
            return {
                "status": "success",
                "response": response.text if response else "",
            }
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}", exc_info=e)
            raise

    async def analyze_symptoms(self, symptoms: List[str]) -> Dict[str, Any]:
        """
        Analyze symptoms using Gemini

        Args:
            symptoms: List of symptoms

        Returns:
            Analysis results
        """
        try:
            prompt = f"""Analyze the following symptoms and provide:
1. Possible conditions (with confidence levels)
2. Recommended actions
3. When to seek immediate medical attention
4. Questions to ask a healthcare provider

Symptoms: {', '.join(symptoms)}

Note: This is an AI assistant's analysis, not a medical diagnosis. Always consult with a qualified healthcare professional."""

            response = self.model.generate_content(prompt)

            return {
                "status": "success",
                "analysis": response.text if response else "",
                "disclaimer": "This is an AI-based preliminary assessment, not a medical diagnosis",
            }

        except Exception as e:
            logger.error(f"Error analyzing symptoms: {str(e)}", exc_info=e)
            raise


# Global instance
_gemini_service: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Get or create Gemini service instance"""
    global _gemini_service
    if _gemini_service is None:
        _gemini_service = GeminiService()
    return _gemini_service
