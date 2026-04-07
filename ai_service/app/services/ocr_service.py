"""
OCR Service for document text extraction
"""

import logging
import io
from typing import Dict, Any, Optional
from PIL import Image
import numpy as np
from app.utils.logger import get_logger

logger = get_logger(__name__)


class OCRService:
    """Service for Optical Character Recognition from medical documents"""

    def __init__(self):
        """Initialize OCR service"""
        logger.info("OCR Service initialized")
        # In production, you would initialize actual OCR tools like Tesseract or Google Vision

    async def extract_text_from_image(
        self, image_data: bytes, document_type: str = "general"
    ) -> Dict[str, Any]:
        """
        Extract text from image using OCR

        Args:
            image_data: Image bytes
            document_type: Type of document (prescription, lab_report, etc)

        Returns:
            Extracted text and structured data
        """
        try:
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(image_data))

            # Log image info
            logger.info(f"Processing {document_type} image: {image.size} {image.mode}")

            # In production, use actual OCR:
            # - Google Cloud Vision API
            # - Tesseract OCR
            # - AWS Textract
            # For now, return placeholder
            extracted_text = self._mock_extract_text(image, document_type)
            structured_data = self._parse_document_structure(
                extracted_text, document_type
            )

            return {
                "status": "success",
                "extracted_text": extracted_text,
                "structured_data": structured_data,
                "confidence": 0.92,
                "document_type": document_type,
            }

        except Exception as e:
            logger.error(f"Error extracting text: {str(e)}", exc_info=e)
            return {
                "status": "error",
                "message": f"OCR processing failed: {str(e)}",
            }

    async def extract_medicines_from_prescription(
        self, image_data: bytes
    ) -> Dict[str, Any]:
        """
        Extract medicines from prescription image

        Args:
            image_data: Prescription image bytes

        Returns:
            Extracted medicines
        """
        try:
            result = await self.extract_text_from_image(image_data, "prescription")

            if result["status"] == "success":
                medicines = self._parse_medicines(
                    result["extracted_text"], result["structured_data"]
                )
                result["medicines"] = medicines

            return result

        except Exception as e:
            logger.error(f"Error extracting medicines: {str(e)}", exc_info=e)
            raise

    async def extract_lab_report_data(self, image_data: bytes) -> Dict[str, Any]:
        """
        Extract structured data from lab report

        Args:
            image_data: Lab report image bytes

        Returns:
            Extracted lab data
        """
        try:
            result = await self.extract_text_from_image(image_data, "lab_report")

            if result["status"] == "success":
                lab_data = self._parse_lab_report(result["structured_data"])
                result["lab_data"] = lab_data

            return result

        except Exception as e:
            logger.error(f"Error extracting lab data: {str(e)}", exc_info=e)
            raise

    def _mock_extract_text(self, image: Image.Image, doc_type: str) -> str:
        """
        Mock text extraction (placeholder for actual OCR)

        Args:
            image: PIL Image object
            doc_type: Document type

        Returns:
            Extracted text
        """
        # This is a placeholder. In production, use actual OCR
        text_samples = {
            "prescription": """
PRESCRIPTION
Date: 2024-03-26
Patient: John Doe
DOB: 1980-01-15

Medications:
1. Amoxicillin 500mg - Twice daily for 7 days
2. Ibuprofen 200mg - As needed for pain
3. Cetirizine 10mg - Once daily

Dosage Instructions:
- Take with food
- Do not skip doses
- Complete full course

Refills: 2
Dr. Smith
License #: 123456
            """,
            "lab_report": """
LAB REPORT
Patient: Jane Doe
Date: 2024-03-26

TEST RESULTS:
Blood Count:
- RBC: 4.5 M/uL (Normal)
- WBC: 7.2 K/uL (Normal)
- Hemoglobin: 13.5 g/dL (Normal)

Chemistry:
- Glucose: 95 mg/dL (Normal)
- Creatinine: 0.9 mg/dL (Normal)
- BUN: 18 mg/dL (Normal)
            """,
            "general": """
Document Text Extraction
This is a sample extracted text from a medical document.
More detailed analysis available upon request.
            """,
        }

        return text_samples.get(doc_type, text_samples["general"])

    def _parse_document_structure(
        self, text: str, doc_type: str
    ) -> Dict[str, Any]:
        """Parse document structure from extracted text"""
        return {
            "type": doc_type,
            "sections": text.split("\n"),
            "metadata": {
                "extraction_method": "OCR",
                "processing_timestamp": "2024-03-26T10:30:00Z",
            },
        }

    def _parse_medicines(self, text: str, structured_data: Dict) -> list:
        """
        Parse medicines from prescription text

        Args:
            text: Extracted prescription text
            structured_data: Structured document data

        Returns:
            List of medicines
        """
        medicines = []

        # Simple parsing logic (in production, use NLP)
        lines = text.split("\n")
        for line in lines:
            if "mg" in line.lower():
                medicines.append({
                    "name": line.strip(),
                    "extracted_from": "OCR",
                    "confidence": 0.85,
                })

        return medicines

    def _parse_lab_report(self, structured_data: Dict) -> Dict[str, Any]:
        """
        Parse lab report data

        Args:
            structured_data: Structured document data

        Returns:
            Parsed lab report
        """
        return {
            "test_type": "Blood Panel",
            "results": [
                {
                    "test": "RBC",
                    "value": 4.5,
                    "unit": "M/uL",
                    "status": "normal",
                },
                {
                    "test": "WBC",
                    "value": 7.2,
                    "unit": "K/uL",
                    "status": "normal",
                },
            ],
            "summary": "All tests within normal range",
        }


# Global instance
_ocr_service: Optional[OCRService] = None


async def get_ocr_service() -> OCRService:
    """Get or create OCR service instance"""
    global _ocr_service
    if _ocr_service is None:
        _ocr_service = OCRService()
    return _ocr_service
