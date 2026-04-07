"""
Quick Start Guide for NalaMAI AI Service
"""

# Quick Start Guide

## 5-Minute Setup

### 1. Prerequisites
```bash
# Check Python version (requires 3.11+)
python --version
```

### 2. Clone and Setup
```bash
cd /e/Flutter/nalamai/ai_service

# Create virtual environment
python -m venv venv

# Activate virtual environment (Windows)
venv\Scripts\activate
# Or (Linux/macOS)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your Google API key
# Set GOOGLE_API_KEY=your_actual_key_here
```

### 4. Run Service
```bash
# Start the service
python main.py

# Or with uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 5. Access API
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **API Base**: http://localhost:8000/api/ai

## Docker Quick Start

### Build and Run
```bash
# Build image
docker build -t nalamai-ai-service:1.0 .

# Run container
docker run -d \
  --name nalamai-ai \
  -p 8000:8000 \
  -e GOOGLE_API_KEY=your_api_key \
  nalamai-ai-service:1.0

# Check logs
docker logs nalamai-ai

# Stop container
docker stop nalamai-ai
docker rm nalamai-ai
```

### Using Docker Compose
```bash
# From project root
docker-compose up -d ai_service

# View logs
docker-compose logs -f ai_service

# Stop service
docker-compose down
```

## First API Call

### Test Health Endpoint
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "NalaMAI AI Service",
  "version": "1.0.0"
}
```

### Test Chat Endpoint
```bash
curl -X POST http://localhost:8000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "test123",
    "message": "What should I do about my headache?",
    "token": "test.jwt.token"
  }'
```

### Test Prediction Endpoint
```bash
curl -X POST http://localhost:8000/api/ai/predict \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "test123",
    "vital_signs": {
      "heart_rate": 75,
      "blood_pressure_systolic": 120,
      "blood_pressure_diastolic": 80,
      "blood_oxygen": 98,
      "temperature": 37.0
    },
    "token": "test.jwt.token"
  }'
```

## Common Issues and Solutions

### Issue: "ModuleNotFoundError: No module named 'fastapi'"
**Solution**: Install dependencies
```bash
pip install -r requirements.txt
```

### Issue: "GOOGLE_API_KEY environment variable is not set"
**Solution**: Set your Google API key
```bash
# Windows (Command Prompt)
set GOOGLE_API_KEY=your_key_here

# Windows (PowerShell)
$env:GOOGLE_API_KEY='your_key_here'

# Linux/macOS
export GOOGLE_API_KEY=your_key_here
```

### Issue: Port 8000 already in use
**Solution**: Use different port
```bash
uvicorn main:app --port 8001
```

### Issue: CORS errors from frontend
**Solution**: Update ALLOWED_ORIGINS in .env
```
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,your_frontend_url
```

## Development Tips

### Auto-reload on Changes
```bash
# Development mode with auto-reload
uvicorn main:app --reload
```

### Interactive API Docs
Visit http://localhost:8000/docs to see and test all endpoints interactively.

### View Logs
```bash
# Tail logs (Linux/macOS)
tail -f logs/app.log

# Tail logs (Windows PowerShell)
Get-Content -Path logs/app.log -Tail 10 -Wait
```

### Reset Database/Cache
The service uses in-memory models. Restart to reset:
```bash
# Kill process
Ctrl+C

# Start again
python main.py
```

## Next Steps

1. **Integrate with Frontend**: Update Flutter app to call http://localhost:8000/api/ai
2. **Connect Backend**: Ensure Backend API (port 8080) is running
3. **Configure ML Models**: Update prediction_engine.py with trained models
4. **Production Deployment**: Follow DEPLOYMENT.md guide

## Support

- Check README.md for detailed documentation
- Review test_service.py for usage examples
- Visit FastAPI docs at http://localhost:8000/docs
