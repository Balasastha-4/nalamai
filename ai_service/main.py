from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from routers import ocr, prediction, gemini

app = FastAPI(
    title="Nalamai AI Microservice",
    description="Python API for Medical OCR, Health Prediction, and Gemini Agentic API",
    version="1.0.0"
)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    print(f"DEBUG: Validation Error for {request.method} {request.url}")
    print(f"DEBUG: Errors: {exc.errors()}")
    print(f"DEBUG: Body: {await request.body()}")
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "body": str(await request.body())},
    )

# Configure CORS so Flutter and Spring Boot can communicate with this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, restrict this to specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include endpoint routers
app.include_router(ocr.router, prefix="/api/ai/ocr", tags=["OCR"])
app.include_router(prediction.router, prefix="/api/ai/predict", tags=["Prediction"])
app.include_router(gemini.router, prefix="/api/ai/chat", tags=["Agentic AI"])

@app.get("/api/ai/health")
async def health_check():
    return {"status": "success", "message": "Nalamai Python AI Microservice is running!"}

if __name__ == "__main__":
    import uvicorn
    # Runs the AI server on port 8000 (Spring Boot is on 8080)
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
