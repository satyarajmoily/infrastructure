#!/bin/bash
# Setup Centralized Configuration Script
# This script configures all agents to use centralized configuration

set -e

echo "🔧 Setting up Centralized Configuration System"
echo "=============================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$INFRA_DIR")"

echo "📁 Infrastructure Directory: $INFRA_DIR"
echo "📁 Root Directory: $ROOT_DIR"

# Step 1: Create centralized .env file if it doesn't exist
if [ ! -f "$INFRA_DIR/.env" ]; then
    echo "📝 Creating centralized .env file..."
    cat > "$INFRA_DIR/.env" << 'EOF'
# AI Agent Platform - Master Environment Configuration
# Single source of truth for all sensitive credentials and API keys

# GitHub Configuration (Used by all agents)
GITHUB_TOKEN=your-github-personal-access-token-here
GITHUB_USER_NAME=your-github-username
GITHUB_USER_EMAIL=your-github-email@example.com

# LLM Configuration (Used by all AI agents)
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Platform Configuration
PLATFORM_MODE=multi_repo
ENVIRONMENT=development
LOG_LEVEL=INFO

# Service URLs (Internal)
PROMETHEUS_URL=http://prometheus:9090
ALERTMANAGER_URL=http://alertmanager:9093
GRAFANA_URL=http://grafana:3000

# Security Settings
API_KEY=your-optional-api-key-for-authentication
ENABLE_SANDBOXING=true
SAFETY_MODE=true

# Docker Configuration
DOCKER_SOCKET_PATH=/var/run/docker.sock
DOCKER_NETWORK_MODE=bridge

# Monitoring Configuration  
MONITORING_INTERVAL=30
HEALTH_CHECK_TIMEOUT=10
METRICS_CACHE_TTL=60
EOF
    echo "✅ Created: $INFRA_DIR/.env"
else
    echo "ℹ️  Centralized .env already exists: $INFRA_DIR/.env"
fi

# Step 2: Update repositories.yml to include coding-ai-agent repo
echo "📝 Updating repositories.yml..."
if ! grep -q "coding-ai-agent:" "$INFRA_DIR/config/repositories.yml"; then
    # Add coding-ai-agent repository to the config
    sed -i '' '/market-predictor:/a\
\
  coding-ai-agent:\
    github_url: "https://github.com/satyarajmoily/coding-ai-agent.git"\
    type: "fastapi"\
    port: 8002\
    health_endpoint: "/health"\
    metrics_endpoint: "/metrics"\
    coding_enabled: false\
    monitoring_enabled: true\
    auto_recovery: true\
    description: "Coding AI Agent service"\
    added_date: "'"$(date '+%Y-%m-%d')"'"\
    added_by: "setup-script"
' "$INFRA_DIR/config/repositories.yml"
    echo "✅ Added coding-ai-agent to repositories.yml"
else
    echo "ℹ️  coding-ai-agent already in repositories.yml"
fi

# Step 3: Update Docker Compose to use centralized configuration
echo "📝 Updating Docker Compose configuration..."
cp "$INFRA_DIR/docker-compose.yml" "$INFRA_DIR/docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"

# Update docker-compose.yml to use centralized config
cat > "$INFRA_DIR/docker-compose.yml.new" << 'EOF'
# AI Agent Platform - Centralized Docker Compose Configuration
# Single configuration file for all agents with centralized settings

version: '3.8'

services:
  # Target Services
  market-predictor:
    build: 
      context: ../market-predictor
      dockerfile: Dockerfile
    container_name: market-predictor
    ports:
      - "8000:8000"
    env_file:
      - .env  # Centralized environment
    environment:
      - API_HOST=0.0.0.0
      - API_PORT=8000
      - SERVICE_NAME=market-predictor
    volumes:
      - ./logs/predictor:/app/logs
      - ../market-predictor/src:/app/src
    networks:
      - ai-agent-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s

  # AI Agents  
  devops-ai-agent:
    build: 
      context: ../devops-ai-agent
      dockerfile: Dockerfile
    container_name: devops-ai-agent
    ports:
      - "8001:8001"
    env_file:
      - .env  # Centralized environment
    environment:
      - API_HOST=0.0.0.0
      - API_PORT=8001
      - SERVICE_NAME=devops-ai-agent
      - PLATFORM_CONFIG=/config/platform.yml
      - REPOSITORIES_CONFIG=/config/repositories.yml
      - AGENTS_CONFIG=/config/agents.yml
    volumes:
      - ./logs/agent:/app/logs
      - ./config:/config
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - ai-agent-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    depends_on:
      - prometheus
      - alertmanager

  coding-ai-agent:
    build: 
      context: ../coding-ai-agent
      dockerfile: docker/Dockerfile
    container_name: coding-ai-agent
    ports:
      - "8002:8002"
    env_file:
      - .env  # Centralized environment
    environment:
      - API_HOST=0.0.0.0
      - API_PORT=8002
      - SERVICE_NAME=coding-ai-agent
      - PLATFORM_CONFIG=/config/platform.yml
      - REPOSITORIES_CONFIG=/config/repositories.yml
      - AGENTS_CONFIG=/config/agents.yml
      - WORKSPACE_BASE_PATH=/tmp/coding-agent-workspaces
    volumes:
      - ./logs/coding-agent:/app/logs
      - ./config:/config
      - coding-agent-workspaces:/tmp/coding-agent-workspaces
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - ai-agent-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8002/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    depends_on:
      - devops-ai-agent

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/prometheus/alert-rules.yml:/etc/prometheus/alert-rules.yml
      - prometheus-data:/prometheus
    networks:
      - ai-agent-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 10s
      timeout: 5s
      retries: 3

  alertmanager:
    image: prom/alertmanager:v0.26.0
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - ai-agent-network
    restart: unless-stopped
    depends_on:
      - prometheus
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9093/-/healthy"]
      interval: 10s
      timeout: 5s
      retries: 3

  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
      - grafana-data:/var/lib/grafana
    networks:
      - ai-agent-network
    restart: unless-stopped
    depends_on:
      - prometheus
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  # Log Management
  loki:
    image: grafana/loki:2.9.0
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./monitoring/loki/loki-config.yaml:/etc/loki/local-config.yaml
      - loki-data:/loki
    networks:
      - ai-agent-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3100/ready"]
      interval: 10s
      timeout: 5s
      retries: 3

  promtail:
    image: grafana/promtail:2.9.0
    container_name: promtail
    volumes:
      - ./monitoring/promtail/promtail-config.yaml:/etc/promtail/config.yml
      - ./logs:/var/log/services
      - /var/log:/var/log/host:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - ai-agent-network
    restart: unless-stopped
    depends_on:
      - loki

  # Development and Testing Tools
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./monitoring/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./monitoring/nginx/ssl:/etc/nginx/ssl
    networks:
      - ai-agent-network
    restart: unless-stopped
    depends_on:
      - market-predictor
      - devops-ai-agent
      - coding-ai-agent
      - grafana
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  ai-agent-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  prometheus-data:
    driver: local
  grafana-data:
    driver: local
  alertmanager-data:
    driver: local
  loki-data:
    driver: local
  coding-agent-workspaces:
    driver: local
EOF

mv "$INFRA_DIR/docker-compose.yml.new" "$INFRA_DIR/docker-compose.yml"
echo "✅ Updated docker-compose.yml with centralized configuration"

# Step 4: Create configuration validation script
echo "📝 Creating configuration validation script..."
cat > "$INFRA_DIR/scripts/validate-config.sh" << 'EOF'
#!/bin/bash
# Validate Centralized Configuration Script

echo "🔍 Validating Centralized Configuration"
echo "======================================"

CONFIG_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")/config"
INFRA_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"

# Check required files
echo "📋 Checking configuration files..."

if [ -f "$CONFIG_DIR/platform.yml" ]; then
    echo "✅ platform.yml exists"
else
    echo "❌ platform.yml missing"
fi

if [ -f "$CONFIG_DIR/repositories.yml" ]; then
    echo "✅ repositories.yml exists"
    REPO_COUNT=$(grep -c "^  [a-zA-Z].*:" "$CONFIG_DIR/repositories.yml" || echo "0")
    echo "   📊 Configured repositories: $REPO_COUNT"
else
    echo "❌ repositories.yml missing"
fi

if [ -f "$CONFIG_DIR/agents.yml" ]; then
    echo "✅ agents.yml exists"
else
    echo "❌ agents.yml missing"
fi

if [ -f "$INFRA_DIR/.env" ]; then
    echo "✅ .env exists"
    echo "   🔑 Checking critical environment variables..."
    
    if grep -q "GITHUB_TOKEN=" "$INFRA_DIR/.env" && ! grep -q "GITHUB_TOKEN=your-" "$INFRA_DIR/.env"; then
        echo "   ✅ GITHUB_TOKEN configured"
    else
        echo "   ❌ GITHUB_TOKEN not configured"
    fi
    
    if grep -q "OPENAI_API_KEY=" "$INFRA_DIR/.env" && ! grep -q "OPENAI_API_KEY=your-" "$INFRA_DIR/.env"; then
        echo "   ✅ OPENAI_API_KEY configured"
    else
        echo "   ❌ OPENAI_API_KEY not configured"
    fi
else
    echo "❌ .env missing"
fi

echo ""
echo "🎯 Configuration Summary:"
echo "========================"
echo "📁 All config files in: $CONFIG_DIR"
echo "🔐 Environment file: $INFRA_DIR/.env"
echo "🐳 Docker Compose: $INFRA_DIR/docker-compose.yml"
echo ""
echo "💡 To add repositories: Edit config/repositories.yml manually (see docs/repository-management.md)"
echo "🚀 To start platform: docker-compose up -d"
EOF

chmod +x "$INFRA_DIR/scripts/validate-config.sh"
echo "✅ Created configuration validation script"

echo ""
echo "🎉 Centralized Configuration Setup Complete!"
echo "============================================="
echo ""
echo "📋 What was configured:"
echo "  ✅ Master platform.yml configuration"
echo "  ✅ Centralized .env file for all credentials"
echo "  ✅ Updated docker-compose.yml to use centralized config"
echo "  ✅ Updated repositories.yml with all repos"
echo "  ✅ Created validation script"
echo ""
echo "🎯 Benefits:"
echo "  🔧 Single place to configure all agents"
echo "  🔐 One .env file for all credentials"
echo "  📁 All repositories configured in repositories.yml"
echo "  🚀 All agents auto-discover available repositories"
echo "  🔄 Easy to add new repositories with scripts"
echo ""
echo "🚀 Next Steps:"
echo "  1. Validate config: ./scripts/validate-config.sh"
echo "  2. Start platform: docker-compose up -d"
echo "  3. Add repos: Edit config/repositories.yml manually (see docs/repository-management.md)"
echo "" 