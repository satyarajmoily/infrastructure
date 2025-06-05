# Slack Integration for Alertmanager

## Overview

This setup integrates Slack notifications with Alertmanager, implementing a dual-channel alerting strategy:

1. **Regular alerts** (critical/warning) → **Both Slack + DevOps AI Agent**
2. **Agent alerts** (ai-command-gateway/devops-ai-agent issues) → **Slack only** (prevents notification loops)

## Architecture

```
Prometheus → Alertmanager → {
  Regular alerts     → [Slack + DevOps AI Agent]
  Agent alerts      → [Slack only]
}
```

## Configuration Method

**Important:** Alertmanager does not natively support environment variable expansion in configuration files. The `{{ env "VAR" }}` syntax is NOT supported.

**Solution:** We use `envsubst` for template substitution:

1. **Template file:** `monitoring/alertmanager/alertmanager.yml.template` (uses `${VARIABLE}` syntax)
2. **Generated file:** `monitoring/alertmanager/alertmanager.yml` (contains actual values)
3. **Substitution:** Done by `envsubst` in `start-monitoring.sh`

### Environment Variables

The Slack webhook URL is stored in `infrastructure/.env`:
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/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
```

### Alert Routing Rules

1. **Slack-only alerts** (prevent loops):
   - `ai-command-gateway` service alerts
   - `devops-ai-agent` service alerts  
   - `market-programmer-agent` service alerts (legacy)

2. **Dual notifications** (Slack + AI Agent):
   - All `critical` severity alerts
   - All `warning` severity alerts
   - All other service alerts

### Receivers

- **slack-only**: Sends alerts only to Slack #alerts channel
- **dual-notifications**: Sends alerts to both Slack and DevOps AI Agent webhook
- **slack-notifications**: Default Slack notifications

## Deployment

### Starting the Stack

Use the provided script to ensure environment variables are properly loaded:

```bash
cd infrastructure
./start-monitoring.sh
```

Or manually:

```bash
cd infrastructure
source .env
export SLACK_WEBHOOK_URL
docker-compose -f docker-compose.monitoring.yml up -d
```

### Verification

1. **Check Alertmanager status**:
   ```bash
   docker ps | grep alertmanager
   curl -s http://localhost:9093/api/v2/status
   ```

2. **Check logs**:
   ```bash
   docker logs alertmanager
   ```

3. **Access Alertmanager UI**:
   Open http://localhost:9093 in browser

## File Structure

```
infrastructure/
├── monitoring/alertmanager/
│   ├── alertmanager.yml.template  # Template with ${VARIABLES}
│   └── alertmanager.yml           # Generated (gitignored)
├── start-monitoring.sh            # Deployment script
├── .env                          # Environment variables
└── .gitignore                    # Excludes generated config
```

## Testing

To test Slack notifications, you can trigger test alerts through Prometheus or directly through the Alertmanager API.

## Security

- Slack webhook URL is stored as an environment variable in `infrastructure/.env`
- Generated config contains secrets, so it's gitignored
- Template substitution happens at deployment time
- No hardcoded credentials in configuration files - all secrets are externalized

## Key Insights

1. **Template Syntax:** Use `${VAR}` (shell/envsubst syntax), NOT `{{ env "VAR" }}` (unsupported)
2. **Security:** Generated config contains secrets, so it's gitignored
3. **Automation:** Always use `start-monitoring.sh` for deployment
4. **Verification:** Script includes checks to ensure substitution worked

## Troubleshooting

### Template Substitution Issues
If template substitution fails:

1. **Check the template file:**
   ```bash
   cat monitoring/alertmanager/alertmanager.yml.template | grep SLACK
   ```

2. **Check environment variable:**
   ```bash
   source .env && echo $SLACK_WEBHOOK_URL
   ```

3. **Test envsubst manually:**
   ```bash
   source .env && envsubst < monitoring/alertmanager/alertmanager.yml.template
   ```

4. **Check generated file:**
   ```bash
   grep -A2 "api_url" monitoring/alertmanager/alertmanager.yml
   ```

### Configuration Validation
```bash
# Check Alertmanager health
curl http://localhost:9093/-/healthy

# Check logs for errors
docker logs alertmanager --tail 10

# Verify configuration loaded
curl -s http://localhost:9093/api/v2/status | jq .config.original
``` 