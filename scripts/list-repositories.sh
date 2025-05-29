#!/bin/bash
# List Repositories Script - Show all configured repositories
# Usage: ./scripts/list-repositories.sh

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

echo "🤖 AI Agent Team Platform - Configured Repositories"
echo "=================================================="
echo ""

# Check if repositories.yml exists
if [ ! -f "$CONFIG_DIR/repositories.yml" ]; then
    echo "❌ Configuration file not found: $CONFIG_DIR/repositories.yml"
    exit 1
fi

# Extract repository information
echo "📋 CONFIGURED REPOSITORIES:"
echo ""

# Count total repositories
REPO_COUNT=$(grep -c "^  [a-zA-Z].*:" "$CONFIG_DIR/repositories.yml" 2>/dev/null || echo "0")

if [ "$REPO_COUNT" -eq 0 ]; then
    echo "📭 No repositories configured yet"
    echo ""
    echo "💡 Add a repository with:"
    echo "   ./scripts/add-repository.sh \"repo-name\" \"github-url\" \"repo-type\" \"port\""
    exit 0
fi

# Parse and display repository information
awk '
BEGIN { 
    in_repos = 0
    repo_name = ""
    printf "%-20s %-15s %-6s %-30s %-12s %s\n", "NAME", "TYPE", "PORT", "GITHUB URL", "STATUS", "ADDED"
    printf "%-20s %-15s %-6s %-30s %-12s %s\n", "----", "----", "----", "----------", "------", "-----"
}

/^target_repositories:/ { in_repos = 1; next }
/^[a-zA-Z]/ && in_repos && !/^  / { in_repos = 0 }

in_repos && /^  [a-zA-Z].*:/ { 
    repo_name = $1
    gsub(/:/, "", repo_name)
    gsub(/^  /, "", repo_name)
}

in_repos && /github_url:/ {
    gsub(/.*"/, "", $0)
    gsub(/".*/, "", $0)
    github_url = $0
}

in_repos && /type:/ {
    gsub(/.*"/, "", $0)
    gsub(/".*/, "", $0)
    repo_type = $0
}

in_repos && /port:/ {
    port = $2
}

in_repos && /coding_enabled:/ {
    coding_enabled = $2
}

in_repos && /monitoring_enabled:/ {
    monitoring_enabled = $2
}

in_repos && /added_date:/ {
    gsub(/.*"/, "", $0)
    gsub(/".*/, "", $0)
    added_date = $0
}

# When we reach the next repo or end of section, print current repo
/^  [a-zA-Z].*:/ && in_repos && repo_name != "" && NR > prev_repo_line + 1 {
    if (prev_repo_name != "") {
        status = ""
        if (prev_coding_enabled == "true") status = status "C"
        if (prev_monitoring_enabled == "true") status = status "M"
        if (status == "") status = "N/A"
        
        printf "%-20s %-15s %-6s %-30s %-12s %s\n", prev_repo_name, prev_repo_type, prev_port, substr(prev_github_url,1,28) "...", status, prev_added_date
    }
    prev_repo_name = repo_name
    prev_repo_type = repo_type
    prev_port = port
    prev_github_url = github_url
    prev_coding_enabled = coding_enabled
    prev_monitoring_enabled = monitoring_enabled
    prev_added_date = added_date
    prev_repo_line = NR
}

END {
    if (repo_name != "") {
        status = ""
        if (coding_enabled == "true") status = status "C"
        if (monitoring_enabled == "true") status = status "M"
        if (status == "") status = "N/A"
        
        printf "%-20s %-15s %-6s %-30s %-12s %s\n", repo_name, repo_type, port, substr(github_url,1,28) "...", status, added_date
    }
}
' "$CONFIG_DIR/repositories.yml"

echo ""
echo "📊 SUMMARY:"
echo "   Total Repositories: $REPO_COUNT"
echo "   Status Codes: C=Coding Enabled, M=Monitoring Enabled"
echo ""

# Check agent status
echo "🤖 AGENT STATUS:"
if command -v docker-compose &> /dev/null && docker-compose ps &> /dev/null; then
    CODING_STATUS="❌ Down"
    DEVOPS_STATUS="❌ Down"
    
    if docker-compose ps | grep -q "coding-ai-agent.*Up"; then
        CODING_STATUS="✅ Running"
    fi
    
    if docker-compose ps | grep -q "devops-ai-agent.*Up"; then
        DEVOPS_STATUS="✅ Running"
    fi
    
    echo "   Coding AI Agent: $CODING_STATUS"
    echo "   DevOps AI Agent: $DEVOPS_STATUS"
else
    echo "   Docker Compose: Not available"
fi

echo ""
echo "💡 COMMANDS:"
echo "   Add Repository:    ./scripts/add-repository.sh <name> <url> <type> <port>"
echo "   Remove Repository: ./scripts/remove-repository.sh <name>"
echo "   Start Agents:      docker-compose up -d"
echo "   Stop Agents:       docker-compose down" 