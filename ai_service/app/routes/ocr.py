"""
OCR document processing endpoints
"""

from datetime import datetime

from fastapi import APIRouter, HTTPException, File, UploadFile, Form
from app.models.response_models import OCRResponse
from app.services.ocr_service import get_ocr_service
from app.utils.logger import get_logger
from app.utils.validators import validate_token, raise_validation_error

logger = get_logger(__name__)
router = APIRouter()


@router.post("/ocr", response_model=OCRResponse)
async def extract_text_from_document(
    file: UploadFile = File(...),
    document_type: str = Form(default="general"),
    token: str = Form(...),
):
    """
    Extract text from medical document using OCR

    Args:
        file: Document file to process
        document_type: Type of document (prescription, lab_report, etc)
        token: Authentication token

    Returns:
        Extracted text and structured data
    """
    try:
        # Validate input
        if not validate_token(token):
            raise_validation_error("Invalid authentication token", 401)

        # Validate file
        if not file.filename:
            raise_validation_error("No file provided", 400)

        allowed_types = {"image/jpeg", "image/png", "image/jpg", "application/pdf"}
        if file.content_type not in allowed_types:
            raise_validation_error(
                f"File type not supported. Allowed: {', '.join(allowed_types)}", 400
            )

        logger.info(f"Processing OCR for document type: {document_type}")

        # Get OCR service
        ocr_service = await get_ocr_service()

        # Read file content
        content = await file.read()

        # Process document
        result = await ocr_service.extract_text_from_image(content, document_type)

        if result.get("status") == "error":
            raise HTTPException(
                status_code=400,
                detail={
                    "status": "error",
                    "message": result.get("message"),
                },
            )

        return OCRResponse(
            status="success",
            extracted_text=result.get("extracted_text", ""),
            structured_data=result.get("structured_data"),
            confidence=result.get("confidence", 0.0),
            document_type=result.get("document_type", document_type),
            timestamp=datetime.now().isoformat(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in OCR endpoint: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "OCR processing failed",
                "error": str(e),
            },
        )


@router.post("/extract-prescription")
async def extract_medicines_from_prescription(
    file: UploadFile = File(...),
    token: str = Form(...),
):
    """
    Extract medicines from prescription document

    Args:
        file: Prescription document
        token: Authentication token

    Returns:
        Extracted medicines with dosage information
    """
    try:
        if not validate_token(token):
            raise_validation_error("Invalid authentication token", 401)

        ocr_service = await get_ocr_service()
        content = await file.read()

        result = await ocr_service.extract_medicines_from_prescription(content)

        return {
            "status": "success",
            "extracted_text": result.get("extracted_text"),
            "medicines": result.get("medicines", []),
            "confidence": result.get("confidence"),
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error extracting medicines: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Medicine extraction failed",
            },
        )


@router.post("/extract-lab-report")
async def extract_lab_report_data(
    file: UploadFile = File(...),
    token: str = Form(...),
):
    """
    Extract structured data from lab report

    Args:
        file: Lab report document
        token: Authentication token

    Returns:
        Extracted lab data and results
    """
    try:
        if not validate_token(token):
            raise_validation_error("Invalid authentication token", 401)

        ocr_service = await get_ocr_service()
        content = await file.read()

        result = await ocr_service.extract_lab_report_data(content)

        return {
            "status": "success",
            "extracted_text": result.get("extracted_text"),
            "lab_data": result.get("lab_data"),
            "confidence": result.get("confidence"),
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error extracting lab report: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Lab report extraction failed",
            },
        )
