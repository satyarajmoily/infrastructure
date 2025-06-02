#!/bin/bash
# AI Agent Team Platform - Complete Startup Script
# Usage: ./scripts/start-platform.sh

set -e

echo "🚀 AI Agent Team Platform - Complete Startup"
echo "============================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRASTRUCTURE_DIR"

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p logs/predictor logs/agent logs/coding-agent
echo "✅ Directories created"

# Stop any existing services
echo "🛑 Stopping any existing services..."
docker-compose down 2>/dev/null || true
echo "✅ Existing services stopped"

# Start services in phases
echo ""
echo "🚀 Starting AI Agent Team Platform..."
echo ""

# Phase 1: Infrastructure services
echo "📊 Phase 1: Starting Monitoring Infrastructure..."
docker-compose up -d prometheus grafana loki alertmanager promtail nginx
sleep 5

# Phase 2: Main AI services
echo "🤖 Phase 2: Starting AI Agent Services..."
docker-compose up -d market-predictor devops-ai-agent coding-ai-agent ai-command-gateway
sleep 10

# Verify all services
echo ""
echo "🩺 Verifying service health..."
echo ""

FAILED_SERVICES=()

# Check each service
check_service() {
    local service_name="$1"
    local port="$2"
    local endpoint="$3"
    
    echo -n "   $service_name... "
    if curl -s -f "http://localhost:$port$endpoint" > /dev/null; then
        echo "✅ Healthy"
    else
        echo "❌ Failed"
        FAILED_SERVICES+=("$service_name")
    fi
}

check_service "Market Predictor" "8000" "/health"
check_service "DevOps AI Agent" "8001" "/health"
check_service "Coding AI Agent" "8002" "/health"
check_service "AI Command Gateway" "8003" "/health"
check_service "Prometheus" "9090" "/-/healthy"
check_service "Grafana" "3000" "/api/health"
check_service "Loki" "3100" "/ready"
check_service "Alertmanager" "9093" "/-/healthy"

# Show results
echo ""
if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    echo "🎉 SUCCESS! All services are healthy and running."
else
    echo "⚠️  Some services failed to start properly:"
    for service in "${FAILED_SERVICES[@]}"; do
        echo "   - $service"
    done
    echo ""
    echo "💡 Check logs with: docker-compose logs [service-name]"
fi

echo ""
echo "📋 SERVICE STATUS:"
docker-compose ps

echo ""
echo "🌐 ACCESS URLS:"
echo "   Market Predictor:    http://localhost:8000"
echo "   DevOps AI Agent:     http://localhost:8001"
echo "   Coding AI Agent:     http://localhost:8002"
echo "   AI Command Gateway:  http://localhost:8003"
echo "   Grafana Dashboard:   http://localhost:3000 (admin/admin123)"
echo "   Prometheus:          http://localhost:9090"
echo "   Alertmanager:        http://localhost:9093"

echo ""
echo "💡 USEFUL COMMANDS:"
echo "   Stop Platform:       ./scripts/stop-platform.sh"
echo "   Restart Platform:    ./scripts/restart-platform.sh [all|service-name]"
echo "   View Logs:           docker-compose logs -f [service-name]"
echo "   Restart Service:     docker-compose restart [service-name]"

echo ""
if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    echo "✨ Your AI Agent Team Platform is ready! Start adding repositories and let the agents work! 🤖"
    exit 0
else
    echo "⚠️  Platform started with some issues. Check the failed services above."
    exit 1
fi 