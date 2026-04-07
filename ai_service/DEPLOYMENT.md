"""
Production Deployment Guide for NalaMAI AI Service
"""

# Production Deployment Guide

## Pre-deployment Checklist

- [ ] All environment variables configured in .env (especially GOOGLE_API_KEY)
- [ ] Database connection verified
- [ ] Backend API URL configured correctly
- [ ] CORS origins restricted to production domains
- [ ] Logging configured for production
- [ ] ML models updated/trained
- [ ] Security: JWT secret configured
- [ ] Rate limiting configured (if needed)
- [ ] All tests passing
- [ ] Code reviewed and merged to main branch

## Environment Configuration

### Production .env Setup

```bash
# Copy production config
cp .env.example .env.production

# Edit .env.production with production values
ENVIRONMENT=production
DEBUG=False
GOOGLE_API_KEY=your_production_key
BACKEND_API_URL=https://api.nalamai.com
ALLOWED_ORIGINS=https://nalamai.com,https://app.nalamai.com
LOG_LEVEL=WARNING
CONFIDENCE_THRESHOLD=0.7
```

## Docker Deployment

### 1. Build Production Image

```bash
# Build image with production tag
docker build -t nalamai-ai-service:1.0-prod .

# Tag for registry
docker tag nalamai-ai-service:1.0-prod your-registry/nalamai-ai-service:1.0-prod
```

### 2. Push to Registry

```bash
# Login to registry
docker login your-registry

# Push image
docker push your-registry/nalamai-ai-service:1.0-prod
```

### 3. Deploy with Docker Compose

```bash
# Production docker-compose
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View logs
docker-compose logs -f ai_service

# Check health
curl https://api.nalamai.com/api/ai/health
```

## Kubernetes Deployment

### 1. Create ConfigMap for Configuration

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nalamai-ai-config
  namespace: nalamai
data:
  LOG_LEVEL: INFO
  ENVIRONMENT: production
  BACKEND_API_URL: http://backend-service:8080
```

### 2. Create Secret for Sensitive Data

```bash
kubectl create secret generic nalamai-ai-secrets \
  --from-literal=GOOGLE_API_KEY=your_key \
  --from-literal=BACKEND_API_KEY=your_key \
  -n nalamai
```

### 3. Deploy Service

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nalamai-ai-service
  namespace: nalamai
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nalamai-ai-service
  template:
    metadata:
      labels:
        app: nalamai-ai-service
    spec:
      containers:
      - name: ai-service
        image: your-registry/nalamai-ai-service:1.0-prod
        ports:
        - containerPort: 8000
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: nalamai-ai-config
              key: LOG_LEVEL
        - name: GOOGLE_API_KEY
          valueFrom:
            secretKeyRef:
              name: nalamai-ai-secrets
              key: GOOGLE_API_KEY
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### 4. Create Service

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nalamai-ai-service
  namespace: nalamai
spec:
  selector:
    app: nalamai-ai-service
  ports:
  - port: 8000
    targetPort: 8000
  type: ClusterIP
```

### 5. Deploy

```bash
# Apply configurations
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl get deployment -n nalamai
kubectl logs -f deployment/nalamai-ai-service -n nalamai
```

## Cloud Deployment (AWS ECS)

### 1. Create ECS Task Definition

```json
{
  "family": "nalamai-ai-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "nalamai-ai-service",
      "image": "your-account.dkr.ecr.us-east-1.amazonaws.com/nalamai-ai-service:1.0-prod",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "production"
        },
        {
          "name": "LOG_LEVEL",
          "value": "INFO"
        }
      ],
      "secrets": [
        {
          "name": "GOOGLE_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:nalamai/google-api-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/nalamai-ai-service",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### 2. Create ECS Service

```bash
# Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/nalamai-ai-service

# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create ECS service
aws ecs create-service \
  --cluster nalamai-cluster \
  --service-name nalamai-ai-service \
  --task-definition nalamai-ai-service \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-1,subnet-2],securityGroups=[sg-xxxxx]}"
```

## Monitoring and Logging

### 1. CloudWatch Logs

```bash
# View logs
aws logs tail /ecs/nalamai-ai-service --follow

# Filter logs
aws logs filter-log-events \
  --log-group-name /ecs/nalamai-ai-service \
  --filter-pattern "ERROR"
```

### 2. Health Checks

```bash
# Check service health
curl -f https://api.nalamai.com/api/ai/health

# Monitor from shell
while true; do
  curl -f https://api.nalamai.com/api/ai/health || echo "Service down!"
  sleep 30
done
```

### 3. Performance Monitoring

- Set up CloudWatch alarms for error rates
- Monitor CPU and memory usage
- Track API response times
- Set up alerts for critical errors

## Scaling Configuration

### Horizontal Scaling

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nalamai-ai-service
  namespace: nalamai
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nalamai-ai-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Database Backup

```bash
# Backup PostgreSQL (if used)
docker exec nalamai_postgres pg_dump -U nalamai nalamai_db > backup.sql

# Restore backup
docker exec -i nalamai_postgres psql -U nalamai nalamai_db < backup.sql
```

## SSL/TLS Configuration

### NGINX Reverse Proxy

```nginx
server {
    listen 443 ssl http2;
    server_name api.nalamai.com;

    ssl_certificate /etc/letsencrypt/live/api.nalamai.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.nalamai.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location /api/ai/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name api.nalamai.com;
    return 301 https://$server_name$request_uri;
}
```

## Rolling Updates

### Docker Swarm Update

```bash
# Update service with new image
docker service update --image nalamai-ai-service:1.1-prod nalamai-ai-service
```

### Kubernetes Rolling Update

```bash
# Update image
kubectl set image deployment/nalamai-ai-service \
  nalamai-ai-service=your-registry/nalamai-ai-service:1.1-prod \
  -n nalamai

# Check rollout status
kubectl rollout status deployment/nalamai-ai-service -n nalamai

# Rollback if needed
kubectl rollout undo deployment/nalamai-ai-service -n nalamai
```

## Post-Deployment Verification

1. **Health Checks**
   ```bash
   curl https://api.nalamai.com/api/ai/health
   ```

2. **API Documentation**
   Visit https://api.nalamai.com/api/ai/docs

3. **Test Endpoints**
   - Chat endpoint
   - Prediction endpoint
   - OCR endpoint
   - Analysis endpoint

4. **Monitor Logs**
   ```bash
   docker-compose logs -f ai_service
   ```

5. **Performance Baseline**
   - Response times
   - Error rates
   - Resource utilization

## Troubleshooting Production Issues

### High CPU Usage
- Check for infinite loops in processing
- Review ML model performance
- Consider load balancing adjustments

### Memory Leaks
- Monitor memory over time
- Check for accumulated data structures
- Restart periodically if needed

### API Timeouts
- Increase timeout values
- Optimize database queries
- Add caching layer

### Authentication Issues
- Verify JWT secret configuration
- Check token expiration settings
- Review CORS configuration

## Maintenance Schedule

- **Daily**: Monitor logs and error rates
- **Weekly**: Performance review, backup verification
- **Monthly**: Security updates, dependency upgrades
- **Quarterly**: ML model retraining, capacity planning

## Support and Escalation

- Alert on-call engineer for critical errors
- Page SRE team for infrastructure issues
- Follow runbooks for common problems
- Document all incidents and resolutions
