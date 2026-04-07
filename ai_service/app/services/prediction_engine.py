"""
Machine Learning prediction engine for health risk assessment
"""

import logging
import numpy as np
from typing import Dict, Any, Optional, Tuple
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from app.utils.logger import get_logger

logger = get_logger(__name__)


class HealthRiskPredictor:
    """ML-based health risk prediction engine"""

    def __init__(self):
        """Initialize the predictor with pre-trained models"""
        self.risk_classifier = self._initialize_risk_model()
        self.scaler = StandardScaler()
        self.feature_names = [
            "heart_rate",
            "systolic_bp",
            "diastolic_bp",
            "blood_oxygen",
            "temperature",
            "respiratory_rate",
            "blood_glucose",
        ]

    def _initialize_risk_model(self):
        """
        Initialize risk prediction model

        Returns:
            Trained RandomForest classifier
        """
        try:
            # In production, you would load a pre-trained model
            # For now, create a dummy model for demonstration
            model = RandomForestClassifier(
                n_estimators=100,
                max_depth=10,
                random_state=42,
            )

            # Generate dummy training data for demonstration
            X_train = np.random.randn(100, 7)
            y_train = np.random.randint(0, 4, 100)  # 0: low, 1: medium, 2: high, 3: critical
            model.fit(X_train, y_train)

            return model
        except Exception as e:
            logger.error(f"Error initializing risk model: {str(e)}", exc_info=e)
            raise

    def predict_risk(self, vital_signs: Dict[str, Any]) -> Dict[str, Any]:
        """
        Predict health risk from vital signs

        Args:
            vital_signs: Dictionary of vital signs

        Returns:
            Risk prediction results
        """
        try:
            # Extract and validate vital signs
            features = self._extract_features(vital_signs)

            if not features:
                return {
                    "status": "error",
                    "message": "Insufficient vital signs data for prediction",
                }

            # Normalize features
            features_normalized = self.scaler.fit_transform([features])[0]

            # Make prediction
            risk_level_idx = self.risk_classifier.predict([features_normalized])[0]
            probabilities = self.risk_classifier.predict_proba([features_normalized])[0]

            risk_levels = ["low", "medium", "high", "critical"]
            risk_level = risk_levels[risk_level_idx]

            # Calculate risk score (0-100)
            confidence = float(probabilities[risk_level_idx])
            risk_score = (risk_level_idx / len(risk_levels)) * 100

            # Generate recommendations based on vital signs
            recommendations = self._generate_recommendations(vital_signs, risk_level)

            # Check for alert conditions
            alert_conditions = self._check_alert_conditions(vital_signs)

            return {
                "status": "success",
                "risk_level": risk_level,
                "risk_score": round(risk_score, 2),
                "confidence": round(confidence, 3),
                "recommendations": recommendations,
                "alert_conditions": alert_conditions,
                "probability_distribution": {
                    "low": round(float(probabilities[0]), 3),
                    "medium": round(float(probabilities[1]), 3),
                    "high": round(float(probabilities[2]), 3),
                    "critical": round(float(probabilities[3]), 3),
                },
            }

        except Exception as e:
            logger.error(f"Error predicting risk: {str(e)}", exc_info=e)
            return {
                "status": "error",
                "message": f"Prediction error: {str(e)}",
            }

    def _extract_features(self, vital_signs: Dict[str, Any]) -> Optional[list]:
        """Extract and validate features from vital signs"""
        features = []

        for feature_name in self.feature_names:
            # Map to actual vital sign keys
            key_mapping = {
                "heart_rate": "heart_rate",
                "systolic_bp": "blood_pressure_systolic",
                "diastolic_bp": "blood_pressure_diastolic",
                "blood_oxygen": "blood_oxygen",
                "temperature": "temperature",
                "respiratory_rate": "respiratory_rate",
                "blood_glucose": "blood_glucose",
            }

            key = key_mapping[feature_name]
            value = vital_signs.get(key)

            if value is None:
                return None  # Missing critical data

            features.append(float(value))

        return features

    def _check_alert_conditions(self, vital_signs: Dict[str, Any]) -> list:
        """
        Check for alert conditions in vital signs

        Args:
            vital_signs: Dictionary of vital signs

        Returns:
            List of alert conditions
        """
        alerts = []

        # Heart rate alerts
        hr = vital_signs.get("heart_rate")
        if hr is not None:
            if hr < 40:
                alerts.append("Critically low heart rate (bradycardia)")
            elif hr > 150:
                alerts.append("Elevated heart rate (tachycardia)")

        # Blood pressure alerts
        sys_bp = vital_signs.get("blood_pressure_systolic")
        if sys_bp is not None:
            if sys_bp > 180:
                alerts.append("Hypertensive crisis (systolic BP > 180)")
            elif sys_bp < 90:
                alerts.append("Low blood pressure (hypotension)")

        # Blood oxygen alerts
        o2 = vital_signs.get("blood_oxygen")
        if o2 is not None and o2 < 92:
            alerts.append("Low blood oxygen saturation")

        # Temperature alerts
        temp = vital_signs.get("temperature")
        if temp is not None:
            if temp > 39.5:
                alerts.append("High fever")
            elif temp < 36.0:
                alerts.append("Hypothermia")

        # Blood glucose alerts
        glucose = vital_signs.get("blood_glucose")
        if glucose is not None:
            if glucose > 300:
                alerts.append("Hyperglycemia (critical)")
            elif glucose < 70:
                alerts.append("Hypoglycemia")

        return alerts

    def _generate_recommendations(
        self, vital_signs: Dict[str, Any], risk_level: str
    ) -> list:
        """
        Generate health recommendations based on vital signs and risk level

        Args:
            vital_signs: Dictionary of vital signs
            risk_level: Predicted risk level

        Returns:
            List of recommendations
        """
        recommendations = []

        # Base recommendations based on risk level
        if risk_level == "critical":
            recommendations.append("URGENT: Seek immediate medical attention")
            recommendations.append("Call emergency services if experiencing severe symptoms")
        elif risk_level == "high":
            recommendations.append("Schedule an urgent appointment with your doctor")
            recommendations.append("Monitor vital signs closely")
        elif risk_level == "medium":
            recommendations.append("Schedule a regular appointment with your doctor")
            recommendations.append("Maintain healthy lifestyle habits")
        else:
            recommendations.append("Continue regular health monitoring")

        # Specific recommendations based on vital signs
        if vital_signs.get("blood_pressure_systolic", 0) > 140:
            recommendations.append("Monitor blood pressure daily")
            recommendations.append("Reduce sodium intake")
            recommendations.append("Increase physical activity")

        if vital_signs.get("blood_oxygen", 100) < 95:
            recommendations.append("Avoid strenuous activities")
            recommendations.append("Practice deep breathing exercises")

        if vital_signs.get("blood_glucose", 0) > 200:
            recommendations.append("Review dietary habits")
            recommendations.append("Consult with an endocrinologist")

        return recommendations

    def get_feature_importance(self) -> Dict[str, float]:
        """
        Get feature importance from the model

        Returns:
            Feature importance scores
        """
        importances = self.risk_classifier.feature_importances_
        feature_importance = dict(zip(self.feature_names, importances))
        return {k: round(v, 4) for k, v in feature_importance.items()}


# Global instance
_predictor: Optional[HealthRiskPredictor] = None


def get_predictor() -> HealthRiskPredictor:
    """Get or create predictor instance"""
    global _predictor
    if _predictor is None:
        _predictor = HealthRiskPredictor()
    return _predictor
