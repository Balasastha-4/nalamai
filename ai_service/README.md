# NalaMAI AI Service README

## Overview

NalaMAI AI Service is a production-ready FastAPI-based microservice providing AI-powered healthcare analytics and patient management capabilities. It integrates with Google Generative AI (Gemini) for intelligent chat and analysis, includes ML-based health risk prediction, and supports document OCR for medical documents.

## Features

### 1. **Intelligent Chat with Function Calling**
- Conversational AI powered by Google Gemini
- Function calling for automated appointment booking, vital signs retrieval, symptom checking
- Context-aware responses with patient medical history
- Medicine extraction from prescriptions
- Health tips generation

### 2. **Health Risk Prediction**
- ML-based risk assessment using Random Forest models
- Real-time vital signs analysis
- Confidence scoring
- Alert detection for critical conditions
- Personalized health recommendations

### 3. **Document OCR Processing**
- Text extraction from medical documents
- Support for prescriptions, lab reports, and other medical documents
- Structured data parsing
- Medicine extraction from prescriptions
- Lab report data extraction

### 4. **Patient Analysis**
- Comprehensive health summaries
- Vital sign trend analysis
- Medication tracking
- Appointment management
- Risk factor identification

## Directory Structure

```
ai_service/
├── main.py                          # FastAPI application entry point
├── config.py                        # Configuration management
├── requirements.txt                 # Python dependencies
├── Dockerfile                       # Docker container setup
├── .dockerignore                    # Docker build exclusions
├── .env.example                     # Environment variables template
├── README.md                        # This file
│
├── app/
│   ├── routes/
│   │   ├── chat.py                 # Chat endpoints with Gemini
│   │   ├── prediction.py           # Health risk prediction
│   │   ├── ocr.py                  # Document OCR processing
│   │   └── analysis.py             # Patient analysis endpoints
│   │
│   ├── services/
│   │   ├── gemini_service.py       # Google Gemini integration
│   │   ├── function_handler.py     # Function calling logic
│   │   ├── prediction_engine.py    # ML risk prediction models
│   │   └── ocr_service.py          # Document processing
│   │
│   ├── models/
│   │   ├── request_models.py       # Pydantic request models
│   │   └── response_models.py      # Pydantic response models
│   │
│   └── utils/
│       ├── logger.py               # Logging configuration
│       └── validators.py           # Input validation utilities
```

## Installation

### Prerequisites

- Python 3.11+
- pip (Python package manager)
- Google API Key (for Gemini integration)

### Local Setup

1. **Clone the repository**
```bash
cd /e/Flutter/nalamai/ai_service
```

2. **Create virtual environment**
```bash
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/macOS
source venv/bin/activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Configure environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. **Run the service**
```bash
python main.py
# Or with uvicorn directly
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`
API documentation: `http://localhost:8000/docs`

## Docker Setup

### Build Docker Image

```bash
docker build -t nalamai-ai-service:1.0 .
```

### Run Docker Container

```bash
docker run -d \
  --name nalamai-ai \
  -p 8000:8000 \
  -e GOOGLE_API_KEY=your_api_key \
  -e BACKEND_API_URL=http://host.docker.internal:8080 \
  nalamai-ai-service:1.0
```

### Docker Compose

```bash
docker-compose up -d
```

## API Endpoints

### Health Check
```
GET /health
```

### Chat Endpoints
```
POST /api/ai/chat
POST /api/ai/symptom-check
POST /api/ai/health-summary/{patient_id}
```

### Prediction Endpoints
```
POST /api/ai/predict
GET /api/ai/risk-assessment/{patient_id}
POST /api/ai/batch-predict
```

### OCR Endpoints
```
POST /api/ai/ocr
POST /api/ai/extract-prescription
POST /api/ai/extract-lab-report
```

### Analysis Endpoints
```
POST /api/ai/patient-analysis/{patient_id}
GET /api/ai/patient-summary/{patient_id}
POST /api/ai/compare-vitals
```

## API Usage Examples

### Chat with AI

```python
import requests

response = requests.post(
    "http://localhost:8000/api/ai/chat",
    json={
        "patient_id": "patient123",
        "message": "I have a headache and fever",
        "token": "jwt_token_here"
    }
)
print(response.json())
```

### Health Risk Prediction

```python
response = requests.post(
    "http://localhost:8000/api/ai/predict",
    json={
        "patient_id": "patient123",
        "vital_signs": {
            "heart_rate": 85,
            "blood_pressure_systolic": 130,
            "blood_pressure_diastolic": 85,
            "blood_oxygen": 96,
            "temperature": 37.5,
            "respiratory_rate": 18,
            "blood_glucose": 110
        },
        "token": "jwt_token_here"
    }
)
print(response.json())
```

### Document OCR

```python
with open("prescription.jpg", "rb") as f:
    response = requests.post(
        "http://localhost:8000/api/ai/ocr",
        files={"file": f},
        data={
            "document_type": "prescription",
            "token": "jwt_token_here"
        }
    )
print(response.json())
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ENVIRONMENT | development | Environment mode (development/production) |
| DEBUG | False | Enable debug mode |
| HOST | 0.0.0.0 | Server host |
| PORT | 8000 | Server port |
| GOOGLE_API_KEY | "" | Google Generative AI API key (REQUIRED) |
| GEMINI_MODEL | gemini-pro | Gemini model to use |
| ALLOWED_ORIGINS | localhost | CORS allowed origins |
| BACKEND_API_URL | localhost:8080 | Backend API URL |
| LOG_LEVEL | INFO | Logging level |
| CONFIDENCE_THRESHOLD | 0.6 | ML model confidence threshold |

## Models and Functions

### Available AI Functions

The Gemini AI can call the following functions:

1. **book_appointment** - Schedule medical appointments
2. **get_patient_vitals** - Retrieve patient vital signs
3. **check_symptoms** - Analyze patient symptoms
4. **extract_medicines_from_prescription** - Extract medicines from prescription images
5. **predict_health_risk** - Get ML-based health risk predictions
6. **get_health_tips** - Retrieve personalized health tips

### ML Models

**Health Risk Prediction** uses Random Forest Classifier trained on:
- Heart rate
- Blood pressure (systolic/diastolic)
- Blood oxygen saturation
- Temperature
- Respiratory rate
- Blood glucose

## Logging

The service uses structured JSON logging. All logs include:
- Timestamp (ISO 8601 format)
- Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Logger name
- Message
- Module and function information
- Line number
- Exception details (if applicable)

## Error Handling

The API uses standard HTTP status codes:
- `200 OK` - Successful request
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Invalid token
- `422 Unprocessable Entity` - Validation error
- `500 Internal Server Error` - Server error

Error responses follow this format:
```json
{
  "status": "error",
  "message": "Error description",
  "details": {}
}
```

## Security

### Authentication
- Token-based authentication using JWT
- All endpoints except `/health` and `/` require valid token

### CORS
- Configurable CORS origins
- In production, restrict to specific domains

### Data Validation
- Pydantic models for request validation
- Input sanitization
- Type checking

### Environment Variables
- Sensitive data stored in `.env` (never commit)
- API keys and secrets required for external services

## Performance Optimization

1. **Caching** - Singleton instances for ML models and services
2. **Async Operations** - FastAPI async support for non-blocking I/O
3. **Batch Processing** - Support for batch predictions
4. **Efficient ML Models** - scikit-learn for lightweight predictions

## Monitoring and Maintenance

### Health Checks
```bash
curl http://localhost:8000/health
```

### Logs
Check application logs for debugging:
```bash
# Docker
docker logs nalamai-ai

# Local
# Check console output
```

### Model Updates
To update ML models:
1. Train new models
2. Save model files
3. Update `prediction_engine.py` to load new models
4. Restart service

## Integration with NalaMAI Platform

### Backend (Spring Boot)
- Base URL: `http://localhost:8080`
- Authentication: API Key via header

### Frontend (Flutter)
- Base URL: `http://localhost:8000`
- Authentication: JWT token in request body or header

## Troubleshooting

### Issue: "GOOGLE_API_KEY not set"
**Solution**: Set the environment variable
```bash
export GOOGLE_API_KEY=your_api_key
```

### Issue: CORS errors
**Solution**: Update ALLOWED_ORIGINS in .env to include your frontend URL

### Issue: OCR not working
**Solution**: Ensure image file format is supported (JPEG, PNG, PDF)

### Issue: ML model predictions seem off
**Solution**: Check if vital signs are within expected ranges (see validators.py)

## Development

### Adding New Endpoints

1. Create route function in appropriate file in `app/routes/`
2. Define request/response models in `app/models/`
3. Add business logic in `app/services/`
4. Add validation in `app/utils/validators.py`
5. Test with FastAPI interactive docs at `/docs`

### Testing

```bash
# Run with pytest
pytest

# Create test file
# tests/test_chat.py
def test_chat_endpoint():
    # Test implementation
    pass
```

## License

NalaMAI AI Service is part of the NalaMAI project.

## Support

For issues or questions, refer to the main NalaMAI project documentation.

## Changelog

### Version 1.0.0
- Initial release
- Gemini integration with function calling
- ML-based health risk prediction
- OCR document processing
- Patient analysis endpoints
- Comprehensive error handling
- Production-ready Docker support
