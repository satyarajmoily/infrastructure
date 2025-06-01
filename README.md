# 🏗️ Infrastructure - Service Orchestration Hub

**Clean, Centralized Orchestration with Decentralized Configuration**

This infrastructure repository provides the **single orchestration point** for the entire Autonomous Trading Builder platform. Each service manages its own configuration through `.env` files, while infrastructure handles service coordination, networking, and monitoring.

## 🎯 **Architecture Principles**

### **Single Responsibility Architecture**
- **Infrastructure**: Handles service orchestration, networking, monitoring, and health checks
- **Individual Services**: Own their configuration, business logic, and dependencies
- **No Duplication**: Configuration exists in one place per service (their `.env` file)

### **Clean Configuration Model**
```
┌─────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│   devops-ai-agent   │    │   coding-ai-agent    │    │   market-predictor   │
│     .env file       │    │     .env file        │    │     .env file        │
│                     │    │                      │    │                      │
│ • LLM Settings      │    │ • LLM Settings       │    │ • Service Settings   │
│ • Agent Config      │    │ • Agent Config       │    │ • API Configuration  │
│ • API Keys          │    │ • API Keys           │    │ • Market Data Keys   │
└─────────────────────┘    └──────────────────────┘    └──────────────────────┘
          │                           │                           │
          └───────────────────────────┼───────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Infrastructure / docker-compose.yml                     │
│                         (Service Orchestration)                            │
│                                                                             │
│ • Service Dependencies  • Network Configuration  • Volume Mounts           │
│ • Health Checks        • Port Mappings           • Monitoring Stack        │
│ • Container Lifecycle  • Docker Networks         • Service Discovery       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**
- Docker and Docker Compose
- OpenAI API Key
- Each agent properly configured with its `.env` file

### **1. Verify Agent Configurations**
Ensure each service has its `.env` file configured:

```bash
# Check DevOps AI Agent configuration
cat ../devops-ai-agent/.env

# Check Coding AI Agent configuration  
cat ../coding-ai-agent/.env

# Check Market Predictor configuration
cat ../market-predictor/.env
```

### **2. Start Complete Platform**
```bash
# From infrastructure directory
docker-compose up -d
```

### **3. Verify All Services**
```bash
# Check service status
docker-compose ps

# Test health endpoints
curl http://localhost:8001/health  # DevOps AI Agent
curl http://localhost:8002/health  # Coding AI Agent
curl http://localhost:8000/health  # Market Predictor
```

### **4. Access Monitoring Stack**
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **Loki**: http://localhost:3100

## 🛠️ **Configuration Management**

### **Decentralized Configuration Principle**
Each service is **self-contained** and manages its own configuration:

#### **DevOps AI Agent** (`../devops-ai-agent/.env`):
```bash
# LLM Configuration
LLM_PROVIDER=openai
LLM_MODEL=gpt-4.1-nano-2025-04-14
LLM_TEMPERATURE=0.1
OPENAI_API_KEY=your_key_here

# Agent Settings
AGENT_NAME=devops-ai-agent
ENVIRONMENT=development
LOG_LEVEL=INFO

# Service URLs (overridden by docker-compose for container networking)
PROMETHEUS_URL=http://localhost:9090
ALERTMANAGER_URL=http://localhost:9093
```

#### **Coding AI Agent** (`../coding-ai-agent/.env`):
```bash
# LLM Configuration
LLM_PROVIDER=openai
LLM_MODEL=gpt-4.1-nano-2025-04-14
LLM_TEMPERATURE=0.2
OPENAI_API_KEY=your_key_here

# Agent Settings
AGENT_NAME=coding-ai-agent
ENVIRONMENT=development
LOG_LEVEL=INFO

# GitHub Integration
GITHUB_TOKEN=your_github_token_here
WORKSPACE_BASE_PATH=/tmp/coding-agent-workspaces
```

### **Infrastructure Responsibilities**
The `docker-compose.yml` handles:

1. **Service Orchestration**: Defines service dependencies and startup order
2. **Network Configuration**: Creates isolated Docker networks for services
3. **Volume Management**: Mounts each agent's `.env` file into their container
4. **Health Monitoring**: Configures health checks and monitoring endpoints
5. **Service Discovery**: Provides container-to-container networking

### **Volume Mounting Strategy**
```yaml
devops-ai-agent:
  volumes:
    - ../devops-ai-agent/.env:/app/.env:ro  # Mount agent's own config
    - /var/run/docker.sock:/var/run/docker.sock
    
coding-ai-agent:
  volumes:
    - ../coding-ai-agent/.env:/app/.env:ro  # Mount agent's own config
    - /var/run/docker.sock:/var/run/docker.sock
    
market-predictor:
  volumes:
    - ../market-predictor/.env:/app/.env:ro  # Mount service's own config
```

## 📊 **Monitoring Stack**

### **Prometheus Configuration**
- **Target Discovery**: Auto-discovers services via Docker networking
- **Metric Collection**: Scrapes health and performance metrics
- **Alert Rules**: Monitors service health and performance thresholds

### **Grafana Dashboards**
- **Service Overview**: Health status of all services
- **Agent Performance**: LLM response times and success rates
- **Infrastructure Metrics**: Container resource usage and networking

### **Loki Log Aggregation**
- **Centralized Logging**: Collects logs from all services
- **Service-Specific Volumes**: Each service logs to its own volume
- **Structured Logging**: JSON-formatted logs for better parsing

## 🔧 **Operations**

### **Adding New Services**
1. Create the new service with its own `.env` file
2. Add service definition to `docker-compose.yml`
3. Mount the service's `.env` file as a volume
4. Configure health checks and networking
5. Update monitoring configuration if needed

### **Configuration Changes**
1. **Service-Level Changes**: Update the service's `.env` file
2. **Infrastructure Changes**: Update `docker-compose.yml`
3. **Restart Service**: `docker-compose restart <service-name>`

### **Scaling Services**
```bash
# Scale specific services
docker-compose up -d --scale devops-ai-agent=2

# View scaled services
docker-compose ps
```

### **Service Management**
```bash
# View logs for specific service
docker-compose logs -f devops-ai-agent

# Restart specific service
docker-compose restart coding-ai-agent

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose down && docker-compose up --build -d
```

## 🚨 **Troubleshooting**

### **Configuration Issues**
```bash
# Verify service can read its .env file
docker exec devops-ai-agent cat /app/.env

# Test configuration loading
docker exec devops-ai-agent python -c "from src.agent.config.simple_config import get_config; print('✅ Config loaded')"
```

### **Service Connectivity**
```bash
# Test service-to-service networking
docker exec devops-ai-agent curl http://prometheus:9090/api/v1/status/config

# Check container networking
docker network inspect infrastructure_ai-agent-network
```

### **Health Check Failures**
```bash
# Manual health check
curl -f http://localhost:8001/health

# Check container health status
docker-compose ps | grep unhealthy
```

## 🏛️ **Architecture Benefits**

### **Clean Separation of Concerns**
- ✅ **Infrastructure**: Handles orchestration and networking only
- ✅ **Services**: Own their configuration and business logic
- ✅ **No Overlap**: Clear boundaries between infrastructure and application concerns

### **Maintainability**
- ✅ **Single Truth Source**: Each configuration setting exists in exactly one place
- ✅ **Independent Changes**: Service configuration changes don't affect infrastructure
- ✅ **Clear Dependencies**: Service dependencies explicit in docker-compose

### **Scalability**
- ✅ **Easy Service Addition**: New services follow the same pattern
- ✅ **Independent Scaling**: Services can be scaled independently
- ✅ **Minimal Configuration**: New services only need their own `.env` file

## 📁 **Directory Structure**
```
infrastructure/
├── docker-compose.yml          # Master orchestration
├── monitoring/                 # Monitoring stack configs
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   └── alertmanager/
├── logs/                       # Service log volumes
│   ├── agent/
│   ├── coding-agent/
│   └── predictor/
└── scripts/                    # Infrastructure management scripts
```

## 🤝 **Contributing**
1. Follow the clean configuration principles
2. Infrastructure changes go in `docker-compose.yml`
3. Service changes go in the service's own `.env` file
4. Update this README when adding new architectural patterns
5. Test configuration changes in development first

---

**Clean Architecture • Single Responsibility • Zero Duplication** 

# AI Agent Team Platform - Infrastructure

This repository contains the centralized infrastructure configuration for the AI Agent Team Platform, including Docker orchestration, monitoring stack, and deployment scripts.

## 🚀 Instant Code Deployment Solution

### **PERMANENT FIX: Zero Cache Issues**

The platform now uses a **revolutionary architecture** that eliminates Docker cache issues permanently:

#### **Architecture Overview**
- **Base Images**: Contain only dependencies (Python packages, system libs)
- **Source Code**: Mounted as read-only volumes (never copied into images)
- **Result**: Code changes deploy instantly, dependencies rebuild only when needed

#### **Deployment Commands**

```bash
# For CODE CHANGES (INSTANT - 2-3 seconds) ⚡
./scripts/deploy-code-changes.sh [service|all]

# For DEPENDENCY CHANGES (rebuilds base images) 🔧
./scripts/deploy-dependencies.sh [service|all]
```

#### **How It Works**

```yaml
# Docker Compose Volume Mounts
volumes:
  - ../service/src:/app/src:ro    # Live source mounting
  - ../service/.env:/app/.env:ro  # Config mounting
```

**Benefits:**
- ✅ **Instant Deployment**: Code changes effective immediately
- ✅ **Zero Cache Issues**: Impossible due to volume mounting
- ✅ **Efficient Builds**: Only rebuild when dependencies change
- ✅ **Production Ready**: Same architecture everywhere

## 📋 Quick Start

### 1. Start Platform
```bash
./scripts/start-platform.sh
```

### 2. Deploy Code Changes (Instant)
```bash
# Deploy all services instantly
./scripts/deploy-code-changes.sh all

# Deploy specific service instantly
./scripts/deploy-code-changes.sh devops-ai-agent
```

### 3. Deploy Dependency Changes
```bash
# When you change requirements.txt
./scripts/deploy-dependencies.sh market-predictor
```

## 🏗️ Services

### AI Agents
- **Market Predictor** (Port 8000): Trading market prediction service
- **DevOps AI Agent** (Port 8001): Infrastructure automation and monitoring
- **Coding AI Agent** (Port 8002): Code generation and development assistance

### Monitoring Stack
- **Prometheus** (Port 9090): Metrics collection and alerting
- **Grafana** (Port 3000): Dashboards and visualization
- **Loki** (Port 3100): Log aggregation
- **AlertManager** (Port 9093): Alert routing and management

## 🔧 Deployment Scripts

### Code Deployment (Instant)
```bash
./scripts/deploy-code-changes.sh [service|all]
```
- **Use For**: Python source code changes
- **Speed**: 2-3 seconds per service
- **Method**: Container restart with volume-mounted source

### Dependency Deployment  
```bash
./scripts/deploy-dependencies.sh [service|all]
```
- **Use For**: requirements.txt or Dockerfile changes
- **Speed**: 30-60 seconds per service
- **Method**: Rebuild base image with no cache

### Platform Management
```bash
./scripts/start-platform.sh     # Start all services
./scripts/stop-platform.sh      # Stop all services
./scripts/restart-platform.sh   # Restart with config reload
```

## 🐳 Docker Architecture

### Multi-Stage Dockerfile Pattern
```dockerfile
# Stage 1: Dependencies only
FROM python:3.13-slim as dependencies
# Install system and Python dependencies
# NO source code copying

# Stage 2: Runtime
FROM dependencies as runtime
# Runtime setup only
# Source mounted as volume
```

### Volume Mount Configuration
```yaml
services:
  service-name:
    build:
      target: runtime  # Use runtime stage
    volumes:
      - ../service/src:/app/src:ro    # Live source
      - ../service/.env:/app/.env:ro  # Config
```

## 🔍 Troubleshooting

### Code Changes Not Reflected?
```bash
# This is now impossible with the new architecture!
# Source code is mounted as volumes, changes are instant
./scripts/deploy-code-changes.sh service-name
```

### Dependency Changes Not Working?
```bash
# Use dependency deployment script
./scripts/deploy-dependencies.sh service-name
```

### Service Health Issues?
```bash
# Check logs
docker logs service-name

# Check health endpoints
curl http://localhost:8000/health  # market-predictor
curl http://localhost:8001/health  # devops-ai-agent
curl http://localhost:8002/health  # coding-ai-agent
```

## 📊 Monitoring

- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

## 🎯 Development Workflow

1. **Make code changes** in any `/src` directory
2. **Deploy instantly**: `./scripts/deploy-code-changes.sh service-name`
3. **Test changes**: Service restarts in 2-3 seconds with new code
4. **No cache issues**: Changes always reflected immediately

## 🏭 Production Considerations

- **Same Architecture**: Development and production use identical patterns
- **Rollback**: Git-based rollbacks work instantly (just restart containers)
- **Scalability**: Base images cached, only source code differs per deployment
- **Resource Efficiency**: Minimal image sizes, no duplicate source storage

---

**The cache problem is solved permanently at the architectural level.** 🎉 