-- init-db.sql
-- This script runs automatically when the PostgreSQL container is first created

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================
-- USERS TABLE
-- ==============================================
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('patient', 'doctor', 'admin')),
    profile_picture_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- ==============================================
-- MEDICAL RESOURCES TABLE
-- ==============================================
CREATE TABLE IF NOT EXISTS medical_resources (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('AVAILABLE', 'IN_USE', 'MAINTENANCE')),
    location VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for medical resources
CREATE INDEX IF NOT EXISTS idx_medical_resources_status ON medical_resources(status);
CREATE INDEX IF NOT EXISTS idx_medical_resources_type ON medical_resources(type);

-- ==============================================
-- APPOINTMENTS TABLE
-- ==============================================
CREATE TABLE IF NOT EXISTS appointments (
    id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    resource_id BIGINT REFERENCES medical_resources(id) ON DELETE SET NULL,
    appointment_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for appointments
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_time ON appointments(appointment_time);

-- ==============================================
-- MEDICAL RECORDS TABLE
-- ==============================================
CREATE TABLE IF NOT EXISTS medical_records (
    id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    diagnosis VARCHAR(500) NOT NULL,
    prescription TEXT,
    notes TEXT,
    record_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for medical records
CREATE INDEX IF NOT EXISTS idx_medical_records_patient_id ON medical_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_medical_records_doctor_id ON medical_records(doctor_id);
CREATE INDEX IF NOT EXISTS idx_medical_records_record_date ON medical_records(record_date);

-- ==============================================
-- BILLINGS TABLE
-- ==============================================
CREATE TABLE IF NOT EXISTS billings (
    id BIGSERIAL PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('PENDING', 'PAID', 'INSURANCE_CLAIMED')),
    items_json TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for billings
CREATE INDEX IF NOT EXISTS idx_billings_patient_id ON billings(patient_id);
CREATE INDEX IF NOT EXISTS idx_billings_status ON billings(status);

-- ==============================================
-- TRIGGERS FOR UPDATED_AT
-- ==============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_records_updated_at BEFORE UPDATE ON medical_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_billings_updated_at BEFORE UPDATE ON billings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==============================================
-- SAMPLE DATA (for development)
-- ==============================================

-- Insert sample users (password is 'password123' hashed - you should use proper bcrypt in production)
INSERT INTO users (email, name, password, role) VALUES
    ('doctor@nalamai.com', 'Dr. Sarah Johnson', '$2a$10$xQkYfRJZE4vGxKPQMRwPJO8FxMxb0M0dLEPvJb4Kx4Kx4Kx4Kx4Kx', 'doctor'),
    ('patient@nalamai.com', 'John Doe', '$2a$10$xQkYfRJZE4vGxKPQMRwPJO8FxMxb0M0dLEPvJb4Kx4Kx4Kx4Kx4Kx', 'patient')
ON CONFLICT (email) DO NOTHING;

-- Insert sample medical resources
INSERT INTO medical_resources (name, type, status, location) VALUES
    ('X-Ray Machine 1', 'X-RAY', 'AVAILABLE', 'Radiology Wing - Room 101'),
    ('Consultation Room A', 'CONSULTATION_ROOM', 'AVAILABLE', 'Main Building - Floor 2'),
    ('Dental Chair 1', 'DENTAL_CHAIR', 'AVAILABLE', 'Dental Wing')
ON CONFLICT DO NOTHING;

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

-- Grant necessary permissions to the database user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nalamai;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nalamai;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO nalamai;
