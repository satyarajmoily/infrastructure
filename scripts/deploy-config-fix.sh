#!/bin/bash

# Deploy Configuration Management Fix
# Removes dual-configuration issue between agents.yml and docker-compose.yml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔧 Deploying Configuration Management Fix..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$INFRASTRUCTURE_DIR"

echo "📋 Configuration Change Summary:"
echo "  • Removed hardcoded LLM variables from docker-compose.yml"
echo "  • agents.yml is now the single source of truth for LLM configuration"
echo "  • No more dual-configuration management needed"
echo ""

echo "🔄 Redeploying containers..."
docker-compose down
docker-compose up -d --force-recreate

echo ""
echo "⏳ Waiting for services to start..."
sleep 15

echo ""
echo "🔍 Verifying agent configurations..."

# Check devops-ai-agent
echo "📊 DevOps AI Agent:"
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "  ✅ Service is running"
    echo "  📝 Check logs: docker logs devops-ai-agent"
else
    echo "  ❌ Service not responding"
fi

# Check coding-ai-agent  
echo "📊 Coding AI Agent:"
if curl -s http://localhost:8002/health > /dev/null 2>&1; then
    echo "  ✅ Service is running"
    echo "  📝 Check logs: docker logs coding-ai-agent"
else
    echo "  ❌ Service not responding"
fi

echo ""
echo "✨ Configuration Management Fixed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Next Steps:"
echo "  1. Only edit agents.yml for LLM configuration changes"
echo "  2. Use './scripts/restart-platform.sh' for config changes"
echo "  3. Verify agent logs to confirm they're reading from agents.yml"
echo ""
echo "💡 Configuration Hierarchy (Fixed):"
echo "  agents.yml → Agent Settings (Single Source of Truth)"
echo "  .env → Infrastructure secrets"
echo "  docker-compose.yml → Container orchestration only" 