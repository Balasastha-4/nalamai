# Nalamai App Architecture

## Overview
Nalamai is built using Flutter with a clean, scalable architecture to support future enhancements like AI, Cloud Storage, and Telemedicine.

## Folder Structure
- **`lib/main.dart`**: Entry point, initializes app and services.
- **`lib/screens/`**: UI implementations (Views).
- **`lib/widgets/`**: Reusable UI components.
- **`lib/models/`**: Data Models (POJOs/DTOs).
- **`lib/services/`**: Concrete service implementations (e.g., `AuthService`).
- **`lib/services/interfaces/`**: Abstract definitions for external services.
- **`lib/repositories/`**: Data abstraction layer (to be populated).
- **`lib/theme/`**: Design system and theme configurations.

## Future Enhancements Strategy
To maintain scalability, future features are defined via interfaces in `lib/services/interfaces/`.

### 1. Backend Integration
- **Context**: Syncing user data and medical records.
- **Plan**: Implement `BackendService` (e.g., `FirebaseBackendService` or `RESTBackendService`).
- **Interface**: `backend_service_interface.dart`

### 2. Cloud Storage
- **Context**: Storing scanned documents and medical reports.
- **Plan**: Implement `StorageService` (e.g., AWS S3, Firebase Storage).
- **Interface**: `storage_service_interface.dart`

### 3. OCR & Machine Learning
- **Context**: Extracting text from documents and predicting health risks.
- **Plan**: Implement `OCRService` and `MLHealthService` utilizing on-device ML (TFLite) or Cloud APIs.
- **Interfaces**: `ocr_service_interface.dart`, `ml_service_interface.dart`

### 4. Telemedicine
- **Context**: Video consultations.
- **Plan**: Implement `VideoCallService` (e.g., WebRTC, Agora).
- **Interface**: `video_call_service_interface.dart`

## Key Implementation Guidelines
- **Dependency Injection**: Use `GetIt` or `Provider` to inject concrete service implementations into screens/repositories.
- **Separation of Concerns**: UI should only interact with Services/Repositories, not raw APIs or Database implementations directly.
