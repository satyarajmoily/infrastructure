#!/bin/bash
# AI Agent Team Platform - Complete Shutdown Script
# Usage: ./scripts/stop-platform.sh

echo "🛑 AI Agent Team Platform - Shutdown"
echo "====================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$INFRASTRUCTURE_DIR"

echo "🔍 Checking running services..."
if docker-compose ps | grep -q "Up"; then
    echo "🛑 Stopping all services..."
    docker-compose down
    
    echo "🧹 Cleaning up..."
    docker system prune -f > /dev/null 2>&1
    
    echo ""
    echo "✅ Platform stopped successfully!"
    echo ""
    echo "💡 To start again: ./scripts/start-platform.sh"
else
    echo "ℹ️  No services are currently running."
    echo ""
    echo "💡 To start platform: ./scripts/start-platform.sh"
fi

echo "" 