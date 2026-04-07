"""
Health risk prediction endpoints
"""

from datetime import datetime

from fastapi import APIRouter, HTTPException
from app.models.request_models import PredictionRequest
from app.models.response_models import PredictionResponse
from app.services.prediction_engine import get_predictor
from app.utils.logger import get_logger
from app.utils.validators import validate_token, raise_validation_error

logger = get_logger(__name__)
router = APIRouter()


@router.post("/predict", response_model=PredictionResponse)
async def predict_health_risk(request: PredictionRequest):
    """
    Predict health risk based on vital signs

    Args:
        request: Prediction request with vital signs and patient context

    Returns:
        Risk prediction with score and recommendations
    """
    try:
        # Validate input
        if not validate_token(request.token):
            raise_validation_error("Invalid authentication token", 401)

        logger.info(f"Predicting health risk for patient: {request.patient_id}")

        # Get predictor
        predictor = get_predictor()

        # Convert vital signs to dict
        vital_dict = request.vital_signs.dict(exclude_none=True)

        # Get prediction
        prediction = predictor.predict_risk(vital_dict)

        if prediction.get("status") == "error":
            raise HTTPException(
                status_code=400,
                detail={
                    "status": "error",
                    "message": prediction.get("message"),
                },
            )

        return PredictionResponse(
            status="success",
            risk_level=prediction.get("risk_level"),
            risk_score=prediction.get("risk_score"),
            confidence=prediction.get("confidence"),
            recommendations=prediction.get("recommendations", []),
            alert_conditions=prediction.get("alert_conditions"),
            timestamp=datetime.now().isoformat(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in prediction endpoint: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Prediction failed",
                "error": str(e),
            },
        )


@router.get("/risk-assessment/{patient_id}")
async def get_risk_assessment(patient_id: str, token: str):
    """
    Get risk assessment for patient

    Args:
        patient_id: Patient's ID
        token: Authentication token

    Returns:
        Risk assessment details
    """
    try:
        if not validate_token(token):
            raise_validation_error("Invalid authentication token", 401)

        predictor = get_predictor()

        # In production, fetch actual vital signs from backend
        sample_vitals = {
            "heart_rate": 78,
            "blood_pressure_systolic": 125,
            "blood_pressure_diastolic": 82,
            "blood_oxygen": 97,
            "temperature": 37.1,
            "respiratory_rate": 16,
            "blood_glucose": 105,
        }

        prediction = predictor.predict_risk(sample_vitals)

        return {
            "status": "success",
            "patient_id": patient_id,
            "prediction": prediction,
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error in risk assessment: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Risk assessment failed",
            },
        )


@router.post("/batch-predict")
async def batch_predict_risk(patients: list, token: str):
    """
    Predict health risk for multiple patients

    Args:
        patients: List of patient vital signs
        token: Authentication token

    Returns:
        List of predictions
    """
    try:
        if not validate_token(token):
            raise_validation_error("Invalid authentication token", 401)

        predictor = get_predictor()
        predictions = []

        for patient in patients:
            try:
                prediction = predictor.predict_risk(patient.get("vital_signs", {}))
                predictions.append({
                    "patient_id": patient.get("patient_id"),
                    "prediction": prediction,
                })
            except Exception as e:
                logger.warning(f"Failed to predict for patient: {str(e)}")
                predictions.append({
                    "patient_id": patient.get("patient_id"),
                    "error": str(e),
                })

        return {
            "status": "success",
            "predictions": predictions,
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as e:
        logger.error(f"Error in batch prediction: {str(e)}", exc_info=e)
        raise HTTPException(
            status_code=500,
            detail={
                "status": "error",
                "message": "Batch prediction failed",
            },
        )
