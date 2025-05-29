#!/bin/bash
# AI Agent Team Platform - Smart Restart Script
# Usage: ./scripts/restart-platform.sh [service-name|all]

set -e

echo "🔄 AI Agent Team Platform - Smart Restart"
echo "=========================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRASTRUCTURE_DIR"

# Define service groups
MONITORING_SERVICES=("prometheus" "grafana" "loki" "alertmanager" "promtail" "nginx")
AI_SERVICES=("market-predictor" "devops-ai-agent" "coding-ai-agent")
ALL_SERVICES=("${MONITORING_SERVICES[@]}" "${AI_SERVICES[@]}")

# Function to restart specific service
restart_service() {
    local service="$1"
    echo "🔄 Restarting $service..."
    
    # Force recreate to pick up config changes
    docker-compose up -d --force-recreate --no-deps "$service"
    sleep 3
    
    # Check health if service has health endpoint
    case "$service" in
        "market-predictor")
            check_health "$service" "8000" "/health"
            ;;
        "devops-ai-agent")
            check_health "$service" "8001" "/health"
            ;;
        "coding-ai-agent")
            check_health "$service" "8002" "/health"
            ;;
        "prometheus")
            check_health "$service" "9090" "/-/healthy"
            ;;
        "grafana")
            check_health "$service" "3000" "/api/health"
            ;;
        "loki")
            check_health_extended "$service" "3100" "/ready" 30
            ;;
        "alertmanager")
            check_health "$service" "9093" "/-/healthy"
            ;;
        *)
            echo "   ✅ Restarted (no health check available)"
            ;;
    esac
}

# Function to check service health
check_health() {
    local service="$1"
    local port="$2"
    local endpoint="$3"
    
    echo -n "   Checking health... "
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$port$endpoint" > /dev/null 2>&1; then
            echo "✅ Healthy"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    echo "⚠️ Health check timeout (but service may still be starting)"
}

# Function to check service health with extended timeout
check_health_extended() {
    local service="$1"
    local port="$2"
    local endpoint="$3"
    local timeout="${4:-30}"
    
    echo -n "   Checking health (extended timeout)... "
    local max_attempts=$((timeout / 2))
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$port$endpoint" > /dev/null 2>&1; then
            echo "✅ Healthy"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    echo "⚠️ Health check timeout (but service may still be starting)"
}

# Function to restart service group
restart_group() {
    local group_name="$1"
    shift
    local services=("$@")
    
    echo "🔄 Restarting $group_name..."
    
    for service in "${services[@]}"; do
        restart_service "$service"
    done
}

# Main logic
SERVICE_NAME="${1:-help}"

case "$SERVICE_NAME" in
    "all")
        echo "🔄 Performing complete platform restart with config reload..."
        echo ""
        
        # Stop all services first
        echo "🛑 Stopping all services..."
        docker-compose down
        
        # Remove any orphaned containers and networks
        echo "🧹 Cleaning up..."
        docker system prune -f > /dev/null 2>&1
        
        # Start everything fresh
        echo "🚀 Starting platform with fresh containers..."
        ./scripts/start-platform.sh
        ;;
        
    "monitoring")
        echo "📊 Restarting monitoring services..."
        restart_group "Monitoring Services" "${MONITORING_SERVICES[@]}"
        ;;
        
    "ai"|"agents")
        echo "🤖 Restarting AI agent services..."
        restart_group "AI Services" "${AI_SERVICES[@]}"
        ;;
        
    "market-predictor"|"devops-ai-agent"|"coding-ai-agent"|"prometheus"|"grafana"|"loki"|"alertmanager"|"promtail"|"nginx")
        echo "🔄 Restarting individual service: $SERVICE_NAME"
        restart_service "$SERVICE_NAME"
        ;;
        
    "help"|*)
        echo "📋 USAGE:"
        echo "   ./scripts/restart-platform.sh [option]"
        echo ""
        echo "🎯 OPTIONS:"
        echo "   all                    - Complete platform restart (recommended for config changes)"
        echo "   monitoring             - Restart monitoring services only"
        echo "   ai|agents              - Restart AI agent services only"
        echo ""
        echo "🔧 INDIVIDUAL SERVICES:"
        echo "   market-predictor       - Restart market predictor"
        echo "   devops-ai-agent        - Restart DevOps AI agent"
        echo "   coding-ai-agent        - Restart coding AI agent"
        echo "   prometheus             - Restart Prometheus"
        echo "   grafana                - Restart Grafana"
        echo "   loki                   - Restart Loki"
        echo "   alertmanager           - Restart Alertmanager"
        echo "   nginx                  - Restart NGINX proxy"
        echo ""
        echo "💡 WHEN TO USE:"
        echo "   - After changing configuration files"
        echo "   - After updating environment variables"
        echo "   - When a service becomes unresponsive"
        echo "   - After code changes in AI agents"
        echo ""
        echo "🔥 FORCE CONFIG RELOAD:"
        echo "   Use 'all' option - this stops everything and recreates containers"
        echo "   Individual service restarts use --force-recreate flag"
        ;;
esac

echo "" 