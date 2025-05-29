#!/bin/bash
# AI Agent Team Platform - Code Deployment Script
# Usage: ./scripts/deploy-code-changes.sh [service-name|all]

set -e

echo "🚀 AI Agent Team Platform - Code Deployment"
echo "==========================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRASTRUCTURE_DIR"

# Define services that have code
CODE_SERVICES=("market-predictor" "devops-ai-agent" "coding-ai-agent")

# Function to deploy service with code changes
deploy_service() {
    local service="$1"
    echo "🔨 Building and deploying $service..."
    
    # Build new image
    echo "   📦 Building Docker image..."
    docker-compose build "$service"
    
    # Deploy with new image
    echo "   🚀 Deploying new container..."
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
    local max_attempts=15
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$port$endpoint" > /dev/null 2>&1; then
            echo "✅ Healthy"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    echo "⚠️ Health check timeout (check logs: docker logs $service)"
}

# Main logic
SERVICE_NAME="${1:-help}"

case "$SERVICE_NAME" in
    "all")
        echo "🔨 Deploying code changes for all AI services..."
        echo ""
        
        for service in "${CODE_SERVICES[@]}"; do
            deploy_service "$service"
            echo ""
        done
        ;;
        
    "market-predictor"|"devops-ai-agent"|"coding-ai-agent")
        echo "🔨 Deploying code changes for: $SERVICE_NAME"
        deploy_service "$SERVICE_NAME"
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
        echo "💡 WHEN TO USE:"
        echo "   - After changing Python source code in src/"
        echo "   - After updating requirements.txt"
        echo "   - After modifying Dockerfile"
        echo ""
        echo "🔥 WHAT THIS DOES:"
        echo "   1. Builds new Docker image with your code changes"
        echo "   2. Stops old container"
        echo "   3. Starts new container with new image"
        echo "   4. Performs health check"
        echo ""
        echo "⚡ FOR CONFIG CHANGES ONLY:"
        echo "   Use ./scripts/restart-platform.sh instead (faster)"
        ;;
esac

echo "" 