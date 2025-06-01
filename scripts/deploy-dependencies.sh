#!/bin/bash
# AI Agent Team Platform - Dependency Deployment Script
# Usage: ./scripts/deploy-dependencies.sh [service-name|all]
# 
# Use this script when you change requirements.txt or Dockerfile
# This rebuilds the dependency-only base images

set -e

echo "🔧 AI Agent Team Platform - Dependency Deployment"
echo "================================================"
echo "🎯 Rebuilding base images with new dependencies..."
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRASTRUCTURE_DIR"

# Define services that have dependencies
DEPENDENCY_SERVICES=("market-predictor" "devops-ai-agent" "coding-ai-agent")

# Function to deploy service dependency changes
deploy_dependencies() {
    local service="$1"
    echo "🔧 Rebuilding $service with new dependencies..."
    
    # Force rebuild base image (no cache for dependency changes)
    echo "   📦 Rebuilding base image with no cache..."
    docker-compose build --no-cache --force-rm "$service"
    
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
        echo "🔧 Rebuilding dependencies for all AI services..."
        echo ""
        
        for service in "${DEPENDENCY_SERVICES[@]}"; do
            deploy_dependencies "$service"
            echo ""
        done
        
        echo "🎉 All dependency deployments complete!"
        ;;
        
    "market-predictor"|"devops-ai-agent"|"coding-ai-agent")
        echo "🔧 Rebuilding dependencies for: $SERVICE_NAME"
        deploy_dependencies "$SERVICE_NAME"
        echo ""
        echo "🎉 $SERVICE_NAME dependencies deployed!"
        ;;
        
    "help"|*)
        echo "📋 USAGE:"
        echo "   ./scripts/deploy-dependencies.sh [service]"
        echo ""
        echo "🎯 OPTIONS:"
        echo "   all                    - Rebuild all AI service dependencies"
        echo "   market-predictor       - Rebuild market predictor dependencies"
        echo "   devops-ai-agent        - Rebuild DevOps AI agent dependencies"
        echo "   coding-ai-agent        - Rebuild coding AI agent dependencies"
        echo ""
        echo "🔧 WHEN TO USE:"
        echo "   - After changing requirements.txt"
        echo "   - After modifying Dockerfile"
        echo "   - After adding new system dependencies"
        echo "   - After changing Python version"
        echo ""
        echo "🔥 WHAT THIS DOES:"
        echo "   1. Rebuilds base image with no cache (ensures fresh dependencies)"
        echo "   2. Stops old container"
        echo "   3. Starts new container with new base image"
        echo "   4. Source code remains mounted as volume (no rebuild needed)"
        echo ""
        echo "⚡ FOR CODE CHANGES ONLY:"
        echo "   Use ./scripts/deploy-code-changes.sh instead (instant restart)"
        ;;
esac

echo "" 