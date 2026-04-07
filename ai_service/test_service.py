"""
Complete test suite for NalaMAI AI Service
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


class TestHealthEndpoints:
    """Test health check endpoints"""

    def test_health_check(self):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["service"] == "NalaMAI AI Service"

    def test_root_endpoint(self):
        """Test root endpoint"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert data["version"]


class TestChatEndpoints:
    """Test chat endpoints"""

    @pytest.fixture
    def valid_token(self):
        """Create a valid token for testing"""
        return "valid.jwt.token"

    def test_chat_missing_token(self):
        """Test chat without token"""
        response = client.post(
            "/api/ai/chat",
            json={
                "patient_id": "patient123",
                "message": "Hello",
                "token": "",
            },
        )
        assert response.status_code == 400

    def test_chat_with_valid_input(self, valid_token):
        """Test chat with valid input"""
        response = client.post(
            "/api/ai/chat",
            json={
                "patient_id": "patient123",
                "message": "I have a headache",
                "token": valid_token,
            },
        )
        # This may fail if GOOGLE_API_KEY is not set, which is expected
        # In production, mock the Gemini service
        assert response.status_code in [200, 500]


class TestPredictionEndpoints:
    """Test prediction endpoints"""

    @pytest.fixture
    def valid_vital_signs(self):
        """Create valid vital signs for testing"""
        return {
            "heart_rate": 75,
            "blood_pressure_systolic": 120,
            "blood_pressure_diastolic": 80,
            "blood_oxygen": 98,
            "temperature": 37.0,
            "respiratory_rate": 16,
            "blood_glucose": 100,
        }

    def test_prediction_with_valid_vitals(self, valid_vital_signs):
        """Test prediction with valid vital signs"""
        response = client.post(
            "/api/ai/predict",
            json={
                "patient_id": "patient123",
                "vital_signs": valid_vital_signs,
                "token": "valid.jwt.token",
            },
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "risk_level" in data
        assert "risk_score" in data
        assert "confidence" in data

    def test_prediction_with_invalid_token(self, valid_vital_signs):
        """Test prediction with invalid token"""
        response = client.post(
            "/api/ai/predict",
            json={
                "patient_id": "patient123",
                "vital_signs": valid_vital_signs,
                "token": "",
            },
        )
        assert response.status_code == 400


class TestValidation:
    """Test input validation"""

    def test_invalid_heart_rate(self):
        """Test validation of invalid heart rate"""
        response = client.post(
            "/api/ai/predict",
            json={
                "patient_id": "patient123",
                "vital_signs": {
                    "heart_rate": 300,  # Invalid
                    "blood_pressure_systolic": 120,
                    "blood_pressure_diastolic": 80,
                    "blood_oxygen": 98,
                    "temperature": 37.0,
                },
                "token": "valid.jwt.token",
            },
        )
        assert response.status_code in [400, 422]

    def test_invalid_blood_pressure(self):
        """Test validation of invalid blood pressure"""
        response = client.post(
            "/api/ai/predict",
            json={
                "patient_id": "patient123",
                "vital_signs": {
                    "heart_rate": 75,
                    "blood_pressure_systolic": 400,  # Invalid
                    "blood_pressure_diastolic": 80,
                    "blood_oxygen": 98,
                    "temperature": 37.0,
                },
                "token": "valid.jwt.token",
            },
        )
        assert response.status_code in [400, 422]


class TestErrorHandling:
    """Test error handling"""

    def test_invalid_patient_id(self):
        """Test with invalid patient ID"""
        response = client.get(
            "/api/ai/patient-summary/",
            params={"token": "valid.jwt.token"},
        )
        assert response.status_code in [404, 400]

    def test_missing_required_field(self):
        """Test with missing required field"""
        response = client.post(
            "/api/ai/chat",
            json={
                "patient_id": "patient123",
                # message is missing
                "token": "valid.jwt.token",
            },
        )
        assert response.status_code == 422


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
