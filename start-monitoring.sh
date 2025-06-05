#!/bin/bash
# Load environment variables and start monitoring stack
set -e

# Source the .env file
source .env

# Export the variables needed by docker-compose and envsubst
export SLACK_WEBHOOK_URL

# Generate the final alertmanager.yml from template using envsubst
echo "🔄 Generating alertmanager.yml from template..."
envsubst < monitoring/alertmanager/alertmanager.yml.template > monitoring/alertmanager/alertmanager.yml

# Verify the substitution worked
if grep -q "\${SLACK_WEBHOOK_URL}" monitoring/alertmanager/alertmanager.yml; then
    echo "❌ ERROR: Environment variable substitution failed - template variables still present"
    exit 1
fi

if grep -q "hooks.slack.com" monitoring/alertmanager/alertmanager.yml; then
    echo "✅ SUCCESS: Environment variable substitution completed"
else
    echo "❌ ERROR: Environment variable substitution failed - Slack URL not found"
    exit 1
fi

# Start the monitoring stack
echo "🚀 Starting monitoring stack..."
docker-compose -f docker-compose.monitoring.yml up -d 