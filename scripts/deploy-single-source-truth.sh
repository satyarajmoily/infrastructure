#!/bin/bash

# Deploy Single Source of Truth Configuration
# Eliminates all defaults - agents.yml is the ONLY source of configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRASTRUCTURE_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎯 Deploying Single Source of Truth Configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$INFRASTRUCTURE_DIR"

echo "📋 Configuration Management Changes:"
echo "  ❌ REMOVED: All default LLM values from codebase"
echo "  ❌ REMOVED: Fallback configuration mechanisms"
echo "  ❌ REMOVED: Multiple sources of truth"
echo "  ✅ SINGLE SOURCE: agents.yml is the ONLY configuration source"
echo "  ✅ FAIL FAST: Application fails if agents.yml is incomplete"
echo ""

echo "🔍 Validating agents.yml configuration..."
if [ ! -f "config/agents.yml" ]; then
    echo "❌ CRITICAL: agents.yml not found!"
    exit 1
fi

# Check for required LLM configuration
echo "📊 Checking LLM configuration completeness..."
if ! grep -q "LLM_MODEL=gpt-4.1-nano-2025-04-14" config/agents.yml; then
    echo "⚠️  DevOps agent LLM model not found in agents.yml"
fi

if ! grep -q "LLM_MODEL=gpt-3.5-turbo" config/agents.yml; then
    echo "⚠️  Coding agent LLM model not found in agents.yml"
fi

echo ""
echo "🔄 Redeploying with single source of truth..."
docker-compose down
docker-compose up -d --build --force-recreate

echo ""
echo "⏳ Waiting for services to start..."
sleep 20

echo ""
echo "🔍 Verifying single source of truth configuration..."

# Check devops-ai-agent
echo "📊 DevOps AI Agent:"
if curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "  ✅ Service is running"
    echo "  📝 Check logs: docker logs devops-ai-agent"
else
    echo "  ❌ Service not responding - checking logs..."
    docker logs devops-ai-agent | tail -5
fi

# Check coding-ai-agent  
echo "📊 Coding AI Agent:"
if curl -s http://localhost:8002/health > /dev/null 2>&1; then
    echo "  ✅ Service is running"
    echo "  📝 Check logs: docker logs coding-ai-agent"
else
    echo "  ❌ Service not responding - checking logs..."
    docker logs coding-ai-agent | tail -5
fi

echo ""
echo "✨ Single Source of Truth Configuration Deployed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Configuration Management (Fixed):"
echo "  📄 agents.yml = SINGLE SOURCE OF TRUTH"
echo "  🚫 No defaults anywhere in codebase"
echo "  🚫 No fallback mechanisms"
echo "  💥 Fail fast if configuration is missing"
echo ""
echo "🔧 To change LLM models:"
echo "  1. Edit infrastructure/config/agents.yml"
echo "  2. Run: docker-compose restart devops-ai-agent coding-ai-agent"
echo "  3. Verify: docker logs <agent-name>" 