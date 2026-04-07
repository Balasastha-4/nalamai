# Docker PostgreSQL & Backend Setup

## Services Running

This project uses Docker Compose to run the following services:

### 1. PostgreSQL Database
- **Container Name**: `nalamai_postgres`
- **Image**: `postgres:16-alpine`
- **Port**: `5432` (mapped to localhost:5432)
- **Status**: Running and healthy ✓

### 2. Spring Boot Backend API
- **Container Name**: `nalamai_backend`
- **Image**: Custom built from `./backend`
- **Port**: `8080` (mapped to localhost:8080)
- **Framework**: Spring Boot 4.0.3 with JPA, Security, and JWT
- **Status**: Running and healthy ✓

### 3. pgAdmin (Database Management UI)
- **Container Name**: `nalamai_pgadmin`
- **Image**: `dpage/pgadmin4:latest`
- **Port**: `5050` (accessible at http://localhost:5050)
- **Status**: Running ✓

## Database Connection Details

### For Your Spring Boot Backend
The backend automatically connects to PostgreSQL using environment variables:
```
spring.datasource.url=jdbc:postgresql://postgres:5432/nalamai_db
spring.datasource.username=nalamai
spring.datasource.password=nalamai_dev_password
```

### For Your Flutter App
```
Host: localhost
Port: 5432
Database: nalamai_db
Username: nalamai
Password: nalamai_dev_password
```

**Connection URL:**
```
postgresql://nalamai:nalamai_dev_password@localhost:5432/nalamai_db
```

### Backend API Endpoints
The backend is accessible at: http://localhost:8080

**Health Check:**
```
GET http://localhost:8080/actuator/health
```

**API Base URL:**
```
http://localhost:8080/api
```

### Using pgAdmin
1. Open http://localhost:5050 in your browser
2. Login with:
   - Email: `admin@example.com`
   - Password: `admin`
3. Add a new server connection:
   - Name: `Nalamai DB`
   - Host: `postgres` (when connecting from pgAdmin container) or `localhost` (from your machine)
   - Port: `5432`
   - Database: `nalamai_db`
   - Username: `nalamai`
   - Password: `nalamai_dev_password`

## Docker Commands

### Start all services
```bash
docker-compose up -d
```

### Start with build (after code changes)
```bash
docker-compose up -d --build
```

### Stop containers
```bash
docker-compose down
```

### Stop and remove volumes (⚠️ This will delete all data!)
```bash
docker-compose down -v
```

### View logs
```bash
# All services
docker-compose logs -f

# PostgreSQL only
docker-compose logs -f postgres

# Backend only
docker-compose logs -f backend

# pgAdmin only
docker-compose logs -f pgadmin
```

### Check container status
```bash
docker-compose ps
```

### Rebuild backend only
```bash
docker-compose up -d --build backend
```

### Restart a specific service
```bash
docker-compose restart backend
```

## Database Schema

The database is automatically initialized with the following tables:

### Tables
1. **users** - Store user accounts (patients, doctors, admins)
2. **medical_resources** - Medical equipment and rooms
3. **appointments** - Patient-doctor appointments
4. **medical_records** - Patient medical history
5. **billings** - Billing and payment information

### Extensions
- UUID extension (`uuid-ossp`)
- Cryptographic functions (`pgcrypto`)

See `init-scripts/01-init-db.sql` for the complete schema.

## Database Initialization

You can add more initialization scripts to the `init-scripts/` directory. They will run automatically in alphabetical order when the container first starts.

## Environment Variables

Configuration is stored in `.env` file. **Do not commit this file to version control!**

See `.env.example` for the template.

### Key Environment Variables

**PostgreSQL:**
- `POSTGRES_USER` - Database username
- `POSTGRES_PASSWORD` - Database password
- `POSTGRES_DB` - Database name
- `POSTGRES_PORT` - Port mapping (default: 5432)

**Backend:**
- `SERVER_PORT` - Backend API port (default: 8080)
- `JWT_SECRET` - Secret key for JWT authentication
- `JWT_EXPIRATION` - JWT token expiration time in milliseconds
- `JPA_DDL_AUTO` - Hibernate DDL mode (update/create/validate)

**pgAdmin:**
- `PGADMIN_EMAIL` - pgAdmin login email
- `PGADMIN_PASSWORD` - pgAdmin login password
- `PGADMIN_PORT` - Port mapping (default: 5050)

## Data Persistence

Database data is persisted in Docker volumes:
- `postgres_data` - PostgreSQL data
- `pgadmin_data` - pgAdmin settings

These volumes persist even when containers are stopped, so your data is safe.

## Development Workflow

### Local Development (without Docker)

1. Start only PostgreSQL:
   ```bash
   docker-compose up -d postgres
   ```

2. Run the backend locally:
   ```bash
   cd backend
   ./mvnw spring-boot:run
   ```

3. The backend will connect to PostgreSQL running in Docker.

### Full Docker Development

1. Start all services:
   ```bash
   docker-compose up -d
   ```

2. After code changes, rebuild:
   ```bash
   docker-compose up -d --build backend
   ```

## Troubleshooting

### Backend can't connect to PostgreSQL
- Ensure PostgreSQL is healthy: `docker-compose ps`
- Check backend logs: `docker-compose logs backend`
- Verify network: All services should be on `nalamai_network`

### Port already in use
- Change the port in `.env` file
- Or stop the conflicting service on your machine

### Database connection refused
- Wait for PostgreSQL health check to pass
- Check if PostgreSQL is listening: `docker-compose logs postgres`

### Reset everything
```bash
docker-compose down -v
docker-compose up -d
```

## Security Notes

⚠️ **Important**: The default credentials are for development only.

For production, please:
1. Change all passwords in the `.env` file
2. Use strong, unique passwords
3. Never commit `.env` to version control
4. Set `SPRING_PROFILES_ACTIVE=prod` for production
5. Use proper SSL/TLS certificates
6. Implement rate limiting and security headers
7. Review and harden Spring Security configuration
