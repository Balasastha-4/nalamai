# Nalamai Backend API

Spring Boot REST API for the Nalamai health management system.

## Tech Stack

- **Framework**: Spring Boot 4.0.3
- **Java Version**: 17
- **Build Tool**: Maven 3.9+
- **Database**: PostgreSQL 16
- **Security**: Spring Security + JWT
- **ORM**: Hibernate/JPA

## Prerequisites

- Java 17 or higher
- Maven 3.9+ (or use the included Maven wrapper)
- PostgreSQL 16 (or use Docker)
- Docker & Docker Compose (optional, for containerized deployment)

## Getting Started

### 1. Setup Database

#### Option A: Using Docker (Recommended)
```bash
# From project root
docker-compose up -d postgres
```

#### Option B: Local PostgreSQL
Create a database named `nalamai_db` and configure credentials in `.env` file.

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update values:
```bash
cp ../.env.example ../.env
```

Key variables:
- `POSTGRES_USER` - Database username
- `POSTGRES_PASSWORD` - Database password
- `POSTGRES_DB` - Database name
- `JWT_SECRET` - Secret for JWT token generation

### 3. Run the Application

#### Using Maven
```bash
./mvnw spring-boot:run
```

#### Using Docker
```bash
# From project root
docker-compose up -d backend
```

The API will be available at: http://localhost:8080

## API Endpoints

### Health Check
```
GET /actuator/health
```

### Authentication
```
POST /api/auth/register
POST /api/auth/login
```

### Users
```
GET    /api/users
GET    /api/users/{id}
POST   /api/users
PUT    /api/users/{id}
DELETE /api/users/{id}
```

### Appointments
```
GET    /api/appointments/patient/{patientId}
GET    /api/appointments/doctor/{doctorId}
POST   /api/appointments
PUT    /api/appointments/{id}
DELETE /api/appointments/{id}
```

### Medical Records
```
GET    /api/records/patient/{patientId}
POST   /api/records
PUT    /api/records/{id}
```

### Medical Resources
```
GET    /api/resources
POST   /api/resources
PUT    /api/resources/{id}
```

### Billing
```
GET    /api/billing/patient/{patientId}
POST   /api/billing
PUT    /api/billing/{id}
```

## Project Structure

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/nalamai/backend/
│   │   │   ├── config/          # Configuration classes
│   │   │   ├── controllers/     # REST controllers
│   │   │   ├── models/          # JPA entities
│   │   │   ├── repositories/    # Data access layer
│   │   │   ├── security/        # Security & JWT
│   │   │   └── DemoApplication.java
│   │   └── resources/
│   │       ├── application.properties       # Main config
│   │       └── application-docker.properties # Docker config
│   └── test/                    # Unit tests
├── Dockerfile                   # Docker image definition
├── .dockerignore               # Docker build exclusions
└── pom.xml                     # Maven dependencies
```

## Database Schema

### Tables
- `users` - User accounts (patients, doctors, admins)
- `medical_resources` - Medical equipment and facilities
- `appointments` - Appointment scheduling
- `medical_records` - Patient medical history
- `billings` - Billing and payments

See `../init-scripts/01-init-db.sql` for the complete schema.

## Development

### Running Tests
```bash
./mvnw test
```

### Building JAR
```bash
./mvnw clean package
```

### Building Docker Image
```bash
docker build -t nalamai-backend .
```

### Code Style
- Follow Java naming conventions
- Use Spring Boot best practices
- Write tests for new features
- Document public APIs

## Configuration Profiles

### Development (default)
```bash
./mvnw spring-boot:run
```

If PostgreSQL runs in Docker on your machine, start DB first and set host explicitly:

```bash
docker compose up -d postgres
POSTGRES_HOST=localhost POSTGRES_PORT=5432 ./mvnw spring-boot:run
```

### Docker
```bash
SPRING_PROFILES_ACTIVE=docker ./mvnw spring-boot:run
```

## Security

### JWT Authentication
- Tokens expire after 24 hours (configurable via `JWT_EXPIRATION`)
- Secret key must be at least 256 bits for production
- Change `JWT_SECRET` in production environment

### Password Hashing
- Uses BCrypt for password hashing
- Minimum recommended work factor: 10

### CORS
Configure allowed origins in `SecurityConfig.java`

## Troubleshooting

### Database Connection Refused
- Ensure PostgreSQL is running
- Check credentials in `.env`
- Verify `DATABASE_URL` format

### Port Already in Use
- Change `SERVER_PORT` in `.env`
- Or kill the process using port 8080

### Build Failures
```bash
# Clean and rebuild
./mvnw clean install -U
```

### Cannot find Maven wrapper
```bash
# Re-initialize Maven wrapper
mvn wrapper:wrapper
```

## Production Deployment

1. Set `SPRING_PROFILES_ACTIVE=prod`
2. Use strong passwords and JWT secrets
3. Enable HTTPS/SSL
4. Configure proper CORS origins
5. Set `JPA_DDL_AUTO=validate` (never use `update` in production)
6. Use a reverse proxy (Nginx/Traefik)
7. Enable rate limiting
8. Monitor with Spring Boot Actuator
9. Set up logging aggregation
10. Regular database backups

## Contributing

1. Create a feature branch
2. Make your changes
3. Write/update tests
4. Ensure all tests pass
5. Submit a pull request

## License

[Your License Here]

## Support

For issues and questions:
- Check existing GitHub issues
- Create a new issue with reproduction steps
- Contact: [Your Contact Info]
