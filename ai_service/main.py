"""
NalaMAI AI Service - Main FastAPI Application
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

from config import config
from app.utils.logger import setup_logger
from app.routes import chat, prediction, ocr, analysis, vitals, analytics_dash, symptoms, clinical_notes, agent, preventive_care

# Setup logging
logger = setup_logger(__name__, config.LOG_LEVEL)


# Lifespan context manager for startup/shutdown events
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    # Startup
    logger.info("Starting NalaMAI AI Service")
    logger.info(f"API Version: {config.API_VERSION}")
    logger.info(f"Gemini Model: {config.GEMINI_MODEL}")

    yield

    # Shutdown
    logger.info("Shutting down NalaMAI AI Service")


# Create FastAPI app
app = FastAPI(
    title=config.API_TITLE,
    description=config.API_DESCRIPTION,
    version=config.API_VERSION,
    lifespan=lifespan,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=config.ALLOWED_CREDENTIALS,
    allow_methods=config.ALLOWED_METHODS,
    allow_headers=config.ALLOWED_HEADERS,
)


# Global exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors"""
    logger.warning(f"Validation error: {exc}")
    return JSONResponse(
        status_code=422,
        content={
            "status": "error",
            "message": "Validation failed",
            "details": exc.errors(),
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions"""
    logger.error(f"Unexpected error: {str(exc)}", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={
            "status": "error",
            "message": "Internal server error",
            "error": str(exc) if config.DEBUG else "An unexpected error occurred",
        },
    )


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "NalaMAI AI Service",
        "version": config.API_VERSION,
    }


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to NalaMAI AI Service",
        "version": config.API_VERSION,
        "docs": "/docs",
        "health": "/health",
    }


# Include routers
app.include_router(chat.router, prefix="/api/ai", tags=["Chat"])
app.include_router(prediction.router, prefix="/api/ai", tags=["Prediction"])
app.include_router(ocr.router, prefix="/api/ai", tags=["OCR"])
app.include_router(analysis.router, prefix="/api/ai", tags=["Analysis"])
app.include_router(vitals.router, prefix="/api/ai", tags=["Vitals"])
app.include_router(analytics_dash.router, prefix="/api/ai", tags=["Analytics"])
app.include_router(symptoms.router, prefix="/api/ai", tags=["Symptoms"])
app.include_router(clinical_notes.router, prefix="/api/ai", tags=["Clinical Notes"])
app.include_router(agent.router, prefix="/api/ai", tags=["AI Agent"])
app.include_router(preventive_care.router, prefix="/api/ai/preventive", tags=["Preventive Care"])


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        app,
        host=config.HOST,
        port=config.PORT,
        log_level=config.LOG_LEVEL.lower(),
    )
