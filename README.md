# 🤖 AI Agent Team Platform Infrastructure

**Generic, Configurable AI Agent Platform for Multi-Repository Management**

This infrastructure repository provides a complete platform for deploying AI agents that can autonomously manage, monitor, and improve any software repository. The system is designed to be repository-agnostic and can scale to manage multiple projects simultaneously.

## 🏗️ Architecture Overview

```
┌─────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│   Coding AI Agent   │    │   DevOps AI Agent   │    │   Target Repo 1      │
│     (Port 8002)     │◄──►│     (Port 8001)      │◄──►│   (market-predictor) │
│                     │    │                      │    │                      │
│ • Code Generation   │    │ • Infrastructure     │    │ • FastAPI Service    │
│ • PR Creation       │    │ • Auto-Recovery      │    │ • Business Logic     │
│ • Testing           │    │ • Monitoring         │    │ • Target Service     │
│ • Git Operations    │    │ • Alert Processing   │    │                      │
└─────────────────────┘    └──────────────────────┘    └──────────────────────┘
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Universal Monitoring & Infrastructure                     │
│                                                                             │
│    Prometheus → Grafana → Alertmanager → Loki → Configuration Management    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- OpenAI API Key (for AI agents)
- GitHub Personal Access Token (for coding operations)

### Setup Workspace
```bash
# Option 1: Setup script (creates workspace structure)
./scripts/setup-workspace.sh

# Option 2: Manual setup
mkdir my-ai-agent-workspace
cd my-ai-agent-workspace

# Clone infrastructure
git clone https://github.com/satyarajmoily/infrastructure.git
cd infrastructure

# Clone your target repositories (example)
git clone https://github.com/satyarajmoily/market-predictor.git ../market-predictor
git clone https://github.com/satyarajmoily/devops-ai-agent.git ../devops-ai-agent
git clone https://github.com/satyarajmoily/coding-ai-agent.git ../coding-ai-agent

# Configure environment
cp .env.template .env
# Edit .env with your API keys
```

### Start AI Agent Platform
```bash
# Start complete platform
docker-compose up -d

# Verify services
curl http://localhost:8001/health  # DevOps AI Agent
curl http://localhost:8002/health  # Coding AI Agent
curl http://localhost:8000/health  # Target Service (if running)
```

### Access Monitoring
- **Grafana Dashboards**: http://localhost:3000 (admin/admin123)
- **Prometheus Metrics**: http://localhost:9090
- **Alertmanager**: http://localhost:9093

## 📋 Repository Management

### Add New Repository (Persistent)
```bash
# Add any repository by editing the configuration file
vim config/repositories.yml

# Add your repository configuration:
# target_repositories:
#   webapp:
#     github_url: "https://github.com/user/webapp.git"
#     type: "react"
#     port: 3000
#     health_endpoint: "/health"
#     coding_enabled: true
#     monitoring_enabled: true

# Commit the changes
git add config/repositories.yml
git commit -m "feat: Add webapp repository"
git push origin main

# Apply changes
docker-compose restart coding-ai-agent devops-ai-agent

# Repository is now permanently configured
# Agents will automatically manage it across all restarts
```

### List Configured Repositories
```bash
./scripts/list-repositories.sh
```

**Example Output:**
```
🤖 AI Agent Team Platform - Configured Repositories
==================================================

📋 CONFIGURED REPOSITORIES:

NAME                 TYPE            PORT   GITHUB URL                     STATUS      ADDED
----                 ----            ----   ----------                     ------      -----
market-predictor     fastapi         8000   https://github.com/satyarajm... CM         2024-01-15
webapp               react           3000   https://github.com/user/webap... CM         2024-01-16

📊 SUMMARY:
   Total Repositories: 2
   Status Codes: C=Coding Enabled, M=Monitoring Enabled

🤖 AGENT STATUS:
   Coding AI Agent: ✅ Running
   DevOps AI Agent: ✅ Running
```

## 🤖 AI Agent Capabilities

### Coding AI Agent
- **Code Generation**: Transform natural language requirements into production code
- **Pull Request Creation**: Automatic PR creation with comprehensive descriptions
- **Local Testing**: Isolated environment testing before submission
- **Multi-Language Support**: Python, JavaScript, React, and more
- **Quality Assurance**: Automated code quality checks and formatting

**Example Usage:**
```bash
curl -X POST http://localhost:8002/api/v1/code \
  -H "Content-Type: application/json" \
  -d '{
    "requirements": "Add a status endpoint that returns server uptime",
    "target_repository": "market-predictor"
  }'
```

### DevOps AI Agent
- **Universal Monitoring**: Monitor any service type (FastAPI, React, Node.js)
- **Automatic Recovery**: Intelligent service restart and health management
- **Performance Analysis**: Resource usage monitoring and optimization
- **Alert Management**: Smart alert routing and incident response
- **Infrastructure Automation**: Docker container management

## 📁 Configuration

### Persistent Repository Configuration
All repository configuration is stored in `config/repositories.yml`:

```yaml
target_repositories:
  market-predictor:
    github_url: "https://github.com/satyarajmoily/market-predictor.git"
    type: "fastapi"
    port: 8000
    health_endpoint: "/health"
    coding_enabled: true
    monitoring_enabled: true
    
  webapp:
    github_url: "https://github.com/user/webapp.git"
    type: "react"
    port: 3000
    health_endpoint: "/health"
    coding_enabled: true
    monitoring_enabled: false
```

### Agent Configuration
Agent capabilities are defined in `config/agents.yml`:

```yaml
platform_agents:
  coding-ai-agent:
    enabled: true
    target_repositories: "all"
    capabilities:
      - "code_generation"
      - "pr_creation"
      - "testing"
      
  devops-ai-agent:
    enabled: true
    target_repositories: "all"
    capabilities:
      - "monitoring"
      - "auto_recovery"
      - "performance_analysis"
```

## 🔧 Development Workflow

### Working with Target Repositories
```bash
# 1. Add repository to platform by editing config/repositories.yml
# Add your repository configuration manually, then:
git add config/repositories.yml
git commit -m "feat: Add new-service repository"
docker-compose restart coding-ai-agent devops-ai-agent

# 2. Agents automatically discover and start managing the repository

# 3. Submit coding requirements
curl -X POST http://localhost:8002/api/v1/code \
  -H "Content-Type: application/json" \
  -d '{
    "requirements": "Add Redis caching to improve performance",
    "target_repository": "new-service"
  }'

# 4. Monitor progress
curl http://localhost:8002/api/v1/code/task_abc123/status

# 5. Review generated PR
# Agent creates PR at: https://github.com/user/service/pull/123
```

### Repository Types Supported
- **FastAPI**: Python web services with health/metrics endpoints
- **React**: Frontend applications with standard build processes
- **Node.js**: JavaScript services with npm-based workflows
- **Python**: General Python applications with pytest testing
- **Custom**: Define your own repository types

## 📊 Monitoring & Observability

### Universal Metrics
- **Service Health**: Real-time health across all repositories
- **Performance Metrics**: Response times, resource usage, error rates
- **AI Agent Performance**: Task completion rates, success metrics
- **Development Metrics**: PR creation rates, code quality scores

### Dashboards Available
- **Platform Overview**: High-level system status
- **Repository Health**: Per-repository monitoring
- **Agent Performance**: AI agent effectiveness metrics
- **Infrastructure Status**: Docker, networking, storage

### Alerting
- **Service Down**: Automatic detection and recovery
- **Performance Degradation**: Resource usage and response time alerts
- **Agent Failures**: AI agent health monitoring
- **Repository Issues**: Git access, build failures

## 🧪 Testing

### Infrastructure Testing
```bash
# Test complete platform
./scripts/test-infrastructure.sh

# Test repository management
# Edit config/repositories.yml to add test-repo manually
# git add config/repositories.yml && git commit -m "Add test repo"
# docker-compose restart coding-ai-agent devops-ai-agent
./scripts/list-repositories.sh
```

### Service Integration Testing
```bash
# Test agent communication
curl http://localhost:8001/api/v1/repositories  # DevOps agent
curl http://localhost:8002/api/v1/repositories  # Coding agent

# Test monitoring integration
curl http://localhost:9090/api/v1/targets       # Prometheus targets
```

## 🔒 Security & Safety

### AI Agent Safety
- **Sandboxed Execution**: All code changes in isolated environments
- **Human Review Required**: PRs require manual approval
- **Quality Gates**: Multiple validation steps before submission
- **Rollback Capability**: Easy rollback of problematic changes

### Infrastructure Security
- **Container Isolation**: Proper containerization and network security
- **Secrets Management**: Environment-based configuration
- **Access Control**: Limited permissions and controlled access
- **Audit Trail**: Complete logging of all agent actions

## 📈 Scaling & Extensions

### Adding New Repository Types
1. Update `config/repositories.yml` with new type definition
2. Configure health check endpoints and test commands
3. Restart agents to load new configuration

### Adding New AI Agents
1. Define agent in `config/agents.yml`
2. Set capabilities and target repositories
3. Deploy agent container with platform integration

### Multi-Environment Deployment
- **Development**: Local docker-compose setup
- **Staging**: Production-like environment for testing
- **Production**: Scaled deployment with redundancy

## 🎯 Use Cases

### Software Teams
- **Feature Development**: AI-driven feature implementation
- **Bug Fixes**: Automated issue resolution
- **Code Quality**: Continuous improvement and refactoring
- **Testing**: Automated test generation and execution

### DevOps Teams
- **Monitoring**: Universal service monitoring
- **Incident Response**: Automated recovery and alerting
- **Performance**: Continuous optimization
- **Infrastructure**: Automated infrastructure management

### Product Teams
- **Rapid Prototyping**: Quick feature implementation
- **A/B Testing**: Automated variant creation
- **Documentation**: Automatic documentation generation
- **Quality Assurance**: Consistent quality across repositories

## 📚 Documentation

- [`docs/PLATFORM_OVERVIEW.md`](docs/PLATFORM_OVERVIEW.md) - Detailed system overview
- [`docs/AI_AGENT_MANUAL_TESTING_GUIDE.md`](docs/AI_AGENT_MANUAL_TESTING_GUIDE.md) - Testing procedures
- [`docs/ADDING_REPOSITORIES.md`](docs/ADDING_REPOSITORIES.md) - Repository management guide
- [`docs/CONFIGURATION.md`](docs/CONFIGURATION.md) - Configuration reference

## 🛠️ Troubleshooting

### Common Issues
```bash
# Agents not starting
docker-compose logs coding-ai-agent
docker-compose logs devops-ai-agent

# Repository not detected
./scripts/list-repositories.sh
docker-compose restart coding-ai-agent devops-ai-agent

# Monitoring not working
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

### Support
- **Issues**: Create issues in this infrastructure repository
- **Documentation**: Check the docs/ directory
- **Logs**: Review container logs for detailed information

---

**The AI Agent Team Platform** - Autonomous software development and operations for any repository, anywhere.

## 🔄 Getting Started

Ready to deploy your AI agent team? Start with:

```bash
# Clone and setup
git clone https://github.com/satyarajmoily/infrastructure.git
cd infrastructure
cp .env.template .env
# Edit .env with your API keys

# Add your first repository - edit config/repositories.yml manually
# git add config/repositories.yml && git commit -m "Add my-project"
# docker-compose restart coding-ai-agent devops-ai-agent

# Start the platform
docker-compose up -d

# Watch the AI agents work! 🤖✨
``` 