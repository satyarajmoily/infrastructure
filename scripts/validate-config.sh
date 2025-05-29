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
echo "💡 To add repositories: Edit config/repositories.yml manually"
echo "🚀 To start platform: docker-compose up -d"
