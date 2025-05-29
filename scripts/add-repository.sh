#!/bin/bash
# Add Repository Script - Fully Persistent Configuration
# Usage: ./scripts/add-repository.sh "repo-name" "github-url" "repo-type" "port"
# Example: ./scripts/add-repository.sh "client-webapp" "https://github.com/client/webapp.git" "react" "3000"

set -e  # Exit on any error

# Script arguments
REPO_NAME=$1
REPO_URL=$2
REPO_TYPE=${3:-"python"}
REPO_PORT=${4:-"8080"}

# Validate arguments
if [ -z "$REPO_NAME" ] || [ -z "$REPO_URL" ]; then
    echo "❌ Error: Missing required arguments"
    echo "Usage: ./scripts/add-repository.sh <repo-name> <github-url> [repo-type] [port]"
    echo "Example: ./scripts/add-repository.sh \"client-webapp\" \"https://github.com/client/webapp.git\" \"react\" \"3000\""
    exit 1
fi

echo "🚀 Adding repository: $REPO_NAME (FULLY PERSISTENT)"
echo "📦 Repository URL: $REPO_URL"
echo "🏷️  Repository Type: $REPO_TYPE"
echo "🔌 Port: $REPO_PORT"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Backup existing configuration
echo "💾 Creating configuration backup..."
cp "$CONFIG_DIR/repositories.yml" "$CONFIG_DIR/repositories.yml.backup.$(date +%Y%m%d_%H%M%S)"

# Check if repository already exists
if grep -q "^  $REPO_NAME:" "$CONFIG_DIR/repositories.yml"; then
    echo "⚠️  Repository '$REPO_NAME' already exists in configuration"
    echo "❓ Would you like to update it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Aborted - Repository not added"
        exit 1
    fi
    echo "🔄 Updating existing repository configuration..."
fi

# Get repository type defaults from config
case $REPO_TYPE in
    "fastapi")
        HEALTH_ENDPOINT="/health"
        METRICS_ENDPOINT="/metrics"
        TEST_COMMAND="pytest"
        ;;
    "react")
        HEALTH_ENDPOINT="/health"
        METRICS_ENDPOINT=""
        TEST_COMMAND="npm test"
        ;;
    "nodejs")
        HEALTH_ENDPOINT="/health"
        METRICS_ENDPOINT=""
        TEST_COMMAND="npm test"
        ;;
    *)
        HEALTH_ENDPOINT="/status"
        METRICS_ENDPOINT=""
        TEST_COMMAND="python -m pytest"
        ;;
esac

echo "📝 Adding to persistent configuration..."

# Remove existing entry if updating
if grep -q "^  $REPO_NAME:" "$CONFIG_DIR/repositories.yml"; then
    # Use sed to remove the existing entry (from the repo name line to the next repo or end of section)
    sed -i '' "/^  $REPO_NAME:/,/^  [a-zA-Z]/{ /^  [a-zA-Z]/!d; /^  $REPO_NAME:/d; }" "$CONFIG_DIR/repositories.yml"
fi

# Create a temporary file with the new repository configuration
cat > "$CONFIG_DIR/new_repo.tmp" << EOF
  $REPO_NAME:
    github_url: "$REPO_URL"
    type: "$REPO_TYPE"
    port: $REPO_PORT
    health_endpoint: "$HEALTH_ENDPOINT"
EOF

# Add metrics endpoint if it exists
if [ -n "$METRICS_ENDPOINT" ]; then
    echo "    metrics_endpoint: \"$METRICS_ENDPOINT\"" >> "$CONFIG_DIR/new_repo.tmp"
fi

# Add the rest of the configuration
cat >> "$CONFIG_DIR/new_repo.tmp" << EOF
    coding_enabled: true
    monitoring_enabled: true
    auto_recovery: true
    test_command: "$TEST_COMMAND"
    description: "Added via add-repository script"
    added_date: "$(date '+%Y-%m-%d')"
    added_by: "$(whoami)"
EOF

# Insert the new configuration after "target_repositories:"
awk '
    /^target_repositories:/ { 
        print
        while ((getline line < "'"$CONFIG_DIR/new_repo.tmp"'") > 0) {
            print line
        }
        close("'"$CONFIG_DIR/new_repo.tmp"'")
        print ""
        next 
    }
    { print }
' "$CONFIG_DIR/repositories.yml" > "$CONFIG_DIR/repositories.yml.tmp"

mv "$CONFIG_DIR/repositories.yml.tmp" "$CONFIG_DIR/repositories.yml"
rm "$CONFIG_DIR/new_repo.tmp"

echo "✅ Repository '$REPO_NAME' added to persistent configuration"

# Optional: Clone repository locally for development
if [ ! -d "../$REPO_NAME" ]; then
    echo "📥 Clone repository locally for development? (y/N)"
    read -r clone_response
    if [[ "$clone_response" =~ ^[Yy]$ ]]; then
        echo "📦 Cloning repository..."
        cd "$(dirname "$SCRIPT_DIR")"
        git clone "$REPO_URL" "../$REPO_NAME"
        echo "✅ Repository cloned to ../$REPO_NAME"
    fi
fi

# Restart agents to load new configuration
echo "🔄 Restarting agents to load new repository..."
cd "$(dirname "$SCRIPT_DIR")"

if docker-compose ps 2>/dev/null | grep -q "Up"; then
    echo "🔄 Restarting AI agents..."
    docker-compose restart coding-ai-agent devops-ai-agent
    
    # Wait for agents to restart
    sleep 5
    
    # Verify agents are healthy
    echo "🩺 Verifying agent health..."
    if curl -s -f http://localhost:8002/health > /dev/null 2>&1; then
        echo "✅ Coding AI Agent is healthy"
    else
        echo "⚠️  Coding AI Agent health check failed"
    fi
    
    if curl -s -f http://localhost:8001/health > /dev/null 2>&1; then
        echo "✅ DevOps AI Agent is healthy"
    else
        echo "⚠️  DevOps AI Agent health check failed"
    fi
else
    echo "ℹ️  Agents are not currently running"
    echo "💡 Start them with: docker-compose up -d"
fi

echo ""
echo "🎉 SUCCESS: Repository '$REPO_NAME' added permanently!"
echo "📄 Configuration saved to: config/repositories.yml"
echo "🔄 Agents will automatically manage this repository on ALL future restarts"
echo "📋 View all repositories: ./scripts/list-repositories.sh"
echo ""

# Show current repository count
REPO_COUNT=$(grep -c "^  [a-zA-Z].*:" "$CONFIG_DIR/repositories.yml" || echo "0")
echo "📊 Total configured repositories: $REPO_COUNT" 