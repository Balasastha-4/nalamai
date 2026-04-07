"""
Configuration management for NalaMAI AI Service
"""

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class Config:
    """Base configuration"""

    # FastAPI settings
    API_TITLE = "NalaMAI AI Service"
    API_VERSION = "1.0.0"
    API_DESCRIPTION = "Healthcare AI service with Gemini integration"

    # Server settings
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 8000))
    DEBUG = os.getenv("DEBUG", "False").lower() == "true"

    # CORS settings
    ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080").split(",")
    ALLOWED_CREDENTIALS = True
    ALLOWED_METHODS = ["*"]
    ALLOWED_HEADERS = ["*"]

    # Google Generative AI settings
    GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")
    GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-pro")

    # Backend API settings
    BACKEND_API_URL = os.getenv("BACKEND_API_URL", "http://localhost:8080")
    BACKEND_API_KEY = os.getenv("BACKEND_API_KEY", "")

    # ML Model settings
    RISK_PREDICTION_MODEL = os.getenv("RISK_PREDICTION_MODEL", "random_forest")
    CONFIDENCE_THRESHOLD = float(os.getenv("CONFIDENCE_THRESHOLD", 0.6))

    # Logging settings
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT = os.getenv("LOG_FORMAT", "json")

    # Database settings (if needed)
    DATABASE_URL = os.getenv("DATABASE_URL", "")


class DevelopmentConfig(Config):
    """Development configuration"""

    DEBUG = True
    LOG_LEVEL = "DEBUG"


class ProductionConfig(Config):
    """Production configuration"""

    DEBUG = False
    LOG_LEVEL = "INFO"


class TestingConfig(Config):
    """Testing configuration"""

    TESTING = True
    DEBUG = True
    DATABASE_URL = "sqlite:///test.db"


def get_config():
    """Get configuration based on environment"""
    env = os.getenv("ENVIRONMENT", "development")
    if env == "production":
        return ProductionConfig()
    elif env == "testing":
        return TestingConfig()
    else:
        return DevelopmentConfig()


config = get_config()
