#!/bin/bash
# AI Agent Team Platform - Instant Code Deployment Script
# Usage: ./scripts/deploy-code-changes.sh [service-name|all]
# 
# NOTE: This script is now INSTANT because source code is mounted as volumes!
# No building required for code changes - just restart containers.

set -e

echo "⚡ AI Agent Team Platform - Instant Code Deployment"
echo "=================================================="
echo "🎯 Source code mounted as volumes - instant deployment!"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRASTRUCTURE_DIR"

# Define services that have code
CODE_SERVICES=("market-predictor" "devops-ai-agent" "coding-ai-agent")

# Function to instantly deploy service code changes
deploy_service() {
    local service="$1"
    echo "⚡ Instantly deploying $service code changes..."
    
    # Just restart - source code mounted as volume!
    echo "   🔄 Restarting container with new code..."
    docker-compose restart "$service"
    sleep 2
    
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
        *)
            echo "   ✅ Deployed (no health check available)"
            ;;
    esac
}

# Function to check service health
check_health() {
    local service="$1"
    local port="$2"
    local endpoint="$3"
    
    echo -n "   🔍 Checking health... "
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$port$endpoint" > /dev/null 2>&1; then
            echo "✅ Healthy"
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    
    echo "⚠️ Health check timeout (check logs: docker logs $service)"
}

# Main logic
SERVICE_NAME="${1:-help}"

case "$SERVICE_NAME" in
    "all")
        echo "⚡ Instantly deploying code changes for all AI services..."
        echo ""
        
        for service in "${CODE_SERVICES[@]}"; do
            deploy_service "$service"
            echo ""
        done
        
        echo "🎉 All services deployed instantly!"
        ;;
        
    "market-predictor"|"devops-ai-agent"|"coding-ai-agent")
        echo "⚡ Instantly deploying code changes for: $SERVICE_NAME"
        deploy_service "$SERVICE_NAME"
        echo ""
        echo "🎉 $SERVICE_NAME deployed instantly!"
        ;;
        
    "help"|*)
        echo "📋 USAGE:"
        echo "   ./scripts/deploy-code-changes.sh [service]"
        echo ""
        echo "🎯 OPTIONS:"
        echo "   all                    - Deploy code changes for all AI services"
        echo "   market-predictor       - Deploy market predictor code changes"
        echo "   devops-ai-agent        - Deploy DevOps AI agent code changes"
        echo "   coding-ai-agent        - Deploy coding AI agent code changes"
        echo ""
        echo "⚡ INSTANT DEPLOYMENT:"
        echo "   - Source code is mounted as volumes"
        echo "   - No building required for code changes"
        echo "   - Just restarts containers (~2-3 seconds)"
        echo "   - Zero cache issues possible!"
        echo ""
        echo "🔧 FOR DEPENDENCY CHANGES:"
        echo "   Use ./scripts/deploy-dependencies.sh instead (rebuilds base images)"
        ;;
esac

echo "" 