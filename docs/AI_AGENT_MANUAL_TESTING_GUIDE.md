# AI Agent Manual Testing Guide

**Autonomous Trading Builder - Market Programmer Agent**  
**Manual Operational Testing for AI-Driven Alert Response**

---

## Overview

This guide provides step-by-step instructions for manually testing how the AI agent responds to real alerts from Alertmanager, with particular focus on:

- ✅ **OpenAI API Available**: Enhanced AI analysis with GPT-4
- ⚠️ **OpenAI API Unavailable**: Fallback to rule-based analysis
- 🔄 **Recovery Actions**: Container restart and service recovery
- 📊 **Real-time Monitoring**: Observing agent behavior and decision-making

## Prerequisites

- Docker and Docker Compose installed
- OpenAI API key configured (optional - we'll test both scenarios)
- Access to project repository with latest code
- Terminal access for log monitoring

---

## Part 1: Environment Setup

### 1.1 Service Startup Procedure

```bash
# Navigate to project root
cd AutonomousTradingBuilder

# Option A: Start with monitoring stack (recommended for full testing)
docker-compose -f docker-compose.monitoring.yml up -d

# Option B: Start basic services only
docker-compose up -d

# Verify all services are running
docker ps

# Expected containers:
# - market-predictor (port 8000)
# - market-programmer-agent (port 8001) 
# - prometheus (port 9090)
# - alertmanager (port 9093)
# - grafana (port 3000)
```

### 1.2 Service Health Validation

```bash
# Check Market Predictor
curl http://localhost:8000/health
# Expected: {"status": "healthy", ...}

# Check Market Programmer Agent  
curl http://localhost:8001/health
# Expected: {"status": "healthy", "monitoring_active": true, ...}

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
# Expected: All targets should be "up"

# Check Alertmanager
curl http://localhost:9093/api/v1/status
# Expected: {"status": "success", ...}
```

### 1.3 Initial Log Monitoring Setup

```bash
# Terminal 1: Agent logs (main focus)
docker logs -f market-programmer-agent

# Terminal 2: Predictor logs
docker logs -f market-predictor

# Terminal 3: Alertmanager logs
docker logs -f $(docker ps -q --filter "name=alertmanager")

# Terminal 4: Prometheus logs (optional)
docker logs -f $(docker ps -q --filter "name=prometheus")
```

---

## Part 2: OpenAI API Configuration Testing

### 2.1 Test Scenario 1: OpenAI API Available

**Setup: Configure OpenAI API Key and FALLBACK**

```bash
# Create/update .env file in market-programmer-agent directory
echo "OPENAI_API_KEY=sk-your-actual-api-key-here" > market-programmer-agent/.env
echo "FALLBACK_ENABLED=false" >> market-programmer-agent/.env

# Restart agent to pick up new configuration
docker-compose restart market-programmer-agent

# Watch agent startup logs
docker logs -f market-programmer-agent
```

### 📝 FALLBACK_ENABLED Configuration

This guide includes testing with **`FALLBACK_ENABLED=false`** to test pure AI efficiency:

- **`FALLBACK_ENABLED=true`** (default): AI agent falls back to rule-based analysis if OpenAI fails
- **`FALLBACK_ENABLED=false`**: AI agent fails immediately if OpenAI API is unavailable
  - ✅ **Use this setting to test pure AI efficiency**
  - ✅ **Ensures 100% AI-driven decision making**
  - ❌ **If OpenAI fails, monitoring cycles will abort with error**

**Expected Startup Behavior:**
```
🤖 Starting market-programmer-agent v0.1.0
🌍 Environment: production
📡 API will be available at http://0.0.0.0:8001
🔒 Agent initialized in alert-driven mode
📡 Waiting for alerts from Prometheus/Alertmanager at /webhook/alerts
🛠️  Manual monitoring available via /monitoring/cycle
```

**Verify AI Analysis Available:**
```bash
# Trigger manual monitoring cycle
curl -X POST http://localhost:8001/monitoring/cycle

# Check logs for AI analysis indicators
# Look for: "Analyzing monitoring data with AI agent"
# Should NOT see: "Analysis agent not available, using basic monitoring"
```

### 2.2 Test Scenario 2: OpenAI API Unavailable

**Setup: Remove/Invalid OpenAI API Key**

```bash
# Option A: Remove API key entirely
sed -i 's/OPENAI_API_KEY=.*/OPENAI_API_KEY=/' market-programmer-agent/.env

# Option B: Use invalid API key
echo "OPENAI_API_KEY=invalid-key-12345" > market-programmer-agent/.env

# Option C: Remove .env file completely
rm market-programmer-agent/.env

# Restart agent
docker-compose restart market-programmer-agent

# Watch startup logs
docker logs -f market-programmer-agent
```

**Expected Fallback Behavior:**
```
🤖 Starting market-programmer-agent v0.1.0
⚠️  Analysis agent not available, using basic monitoring
🔒 Agent initialized in alert-driven mode (fallback mode)
📡 Waiting for alerts from Prometheus/Alertmanager at /webhook/alerts
```

**Verify Fallback Analysis:**
```bash
# Trigger manual monitoring cycle
curl -X POST http://localhost:8001/monitoring/cycle

# Check logs for fallback indicators
# Look for: "Analysis agent not available, using basic monitoring"
# Should see: Rule-based analysis messages
```

---

## Part 3: Alert Simulation and Response Testing

### 3.1 MarketPredictorDown Alert Testing

**Trigger Service Failure:**
```bash
# Stop the market-predictor service
docker stop market-predictor

# Monitor agent logs immediately
# Expected timeline:
# - Prometheus detects service down within 10 seconds
# - Alertmanager processes alert and sends webhook within 30 seconds  
# - Agent receives alert and triggers recovery within 5 seconds
```

**Expected Agent Response Logs:**

**With OpenAI Available:**
```
📡 Received alert webhook from Alertmanager
🔍 Processing MarketPredictorDown alert for service: market-predictor
🤖 Analyzing alert context with AI...
💡 AI Analysis Result:
   - Issue: Service availability failure
   - Confidence: 0.95
   - Recommendation: Immediate container restart
🔄 Executing recovery strategy: CHECK_LOGS → RESTART_SERVICE → CHECK_SERVICE_HEALTH
✅ Recovery completed successfully for MarketPredictorDown
   Duration: 2.3s
   Steps executed: 3
```

**With OpenAI Unavailable:**
```
📡 Received alert webhook from Alertmanager
🔍 Processing MarketPredictorDown alert for service: market-predictor
⚠️ Analysis agent not available, using basic monitoring
🔄 Executing recovery strategy: CHECK_LOGS → RESTART_SERVICE → CHECK_SERVICE_HEALTH
✅ Recovery completed successfully for MarketPredictorDown
   Duration: 2.1s
   Steps executed: 3
```

**Verify Recovery Actions:**
```bash
# Check if container was restarted
docker ps -a --filter "name=market-predictor"
# Look for recent restart time

# Verify service health restored
curl http://localhost:8000/health
# Should return healthy response

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
# market-predictor should be "up" again
```

### 3.2 High Memory Usage Alert Testing

**Simulate Memory Pressure:**
```bash
# Option A: Use stress testing inside predictor container
docker exec market-predictor python -c "
import time
data = []
for i in range(1000000):
    data.append('x' * 1000)
    time.sleep(0.001)
"

# Option B: Manually create alert via Alertmanager API
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "HighMemoryUsage",
      "service": "market-predictor",
      "severity": "warning"
    },
    "annotations": {
      "summary": "High memory usage detected",
      "action_required": "check_logs"
    }
  }]'
```

**Expected Agent Response:**

**With OpenAI:**
```
📡 Received HighMemoryUsage alert for service: market-predictor
🤖 AI Analysis: Memory pattern suggests application leak
💡 Recommendations: 
   - Review memory allocation patterns
   - Check for memory leaks in application code
   - Consider container memory limit adjustment
🔄 Executing: CHECK_RESOURCE_USAGE → CHECK_LOGS
```

**Without OpenAI:**
```
📡 Received HighMemoryUsage alert for service: market-predictor
⚠️ Using basic monitoring - memory threshold exceeded
🔄 Executing: CHECK_RESOURCE_USAGE → CHECK_LOGS
💡 Basic recommendations:
   - Review application memory usage patterns
   - Check container memory limits
```

### 3.3 Agent Self-Alert Protection Testing

**Trigger Agent Down Alert:**
```bash
# Stop the agent briefly to trigger alert
docker stop market-programmer-agent

# Wait 30 seconds for alert to fire, then restart
sleep 30
docker start market-programmer-agent

# Monitor logs after restart
docker logs market-programmer-agent --since 1m
```

**Expected Protection Behavior:**
```
📡 Received MarketProgrammerAgentDown alert
⚠️ Skipping self-recovery for MarketProgrammerAgentDown - agent cannot restart itself
   Self-alerts are handled by external monitoring (Docker health checks)
🛡️ Bootstrap paradox protection activated
```

**Verify Alert Routing:**
```bash
# Check Alertmanager routing (agent alerts should go to external endpoint)
curl http://localhost:9093/api/v1/alerts | jq '.data[] | select(.labels.service == "market-programmer-agent")'

# Should see alerts routed to 'agent-self-monitoring' receiver, not back to agent
```

---

## Part 4: Performance and Behavior Observation

### 4.1 Recovery Time Measurement

**Expected Performance Metrics:**
- **Alert Detection**: 10-30 seconds (Prometheus → Alertmanager → Agent)
- **Recovery Execution**: 2.1-2.5 seconds (container restart)  
- **Health Validation**: 5-10 seconds (service startup + health check)
- **Total Recovery Time**: 20-45 seconds end-to-end

**Measurement Commands:**
```bash
# Monitor recovery timing in real-time
docker logs -f market-programmer-agent | grep -E "(Received|Recovery completed|Duration)"

# Check Docker container restart events
docker events --filter container=market-predictor --since 5m

# Prometheus metrics for recovery duration
curl http://localhost:8001/metrics | grep recovery_duration
```

### 4.2 AI Analysis Quality Comparison

**Test Different Alert Types:**

```bash
# Test 1: Service Down (should trigger immediate restart recommendation)
docker stop market-predictor

# Test 2: Performance Degradation (should suggest investigation)
# Simulate slow responses in predictor

# Test 3: Resource Issues (should recommend resource monitoring)
# Create HighMemoryUsage alert manually
```

**Compare AI vs Fallback Analysis:**

| Scenario | With OpenAI | Without OpenAI |
|----------|-------------|----------------|
| **Confidence Score** | 0.7-0.9 | 0.3 (fixed) |
| **Analysis Depth** | Context-aware, detailed reasoning | Rule-based thresholds |
| **Recommendations** | Specific, actionable insights | Generic best practices |
| **Response Time** | 2-5 seconds (API call) | <1 second (local) |
| **Recovery Actions** | AI-guided strategy selection | Predefined strategy execution |

### 4.3 Multiple Alert Handling

**Stress Test Scenario:**
```bash
# Trigger multiple alerts simultaneously
docker stop market-predictor &
sleep 2
curl -X POST http://localhost:9093/api/v1/alerts -H "Content-Type: application/json" -d '[{
  "labels": {"alertname": "HighMemoryUsage", "service": "market-predictor", "severity": "warning"},
  "annotations": {"summary": "Memory usage spike"}
}]' &

# Monitor how agent handles concurrent alerts
docker logs -f market-programmer-agent | grep -E "(Received|Processing|Recovery)"
```

**Expected Behavior:**
- Agent processes alerts sequentially
- Recovery actions don't interfere with each other  
- Both alerts resolved successfully
- No duplicate recovery attempts

---

## Part 5: Advanced Testing Scenarios

### 5.1 OpenAI API Failure During Operation

**Runtime API Failure Simulation:**
```bash
# Start with working OpenAI key
echo "OPENAI_API_KEY=sk-valid-key" > market-programmer-agent/.env
docker-compose restart market-programmer-agent

# Wait for agent to be ready, then trigger alert
docker stop market-predictor

# While recovery is in progress, invalidate API key
echo "OPENAI_API_KEY=invalid" > market-programmer-agent/.env

# Trigger another alert and observe fallback behavior
# (Note: Agent won't pick up new config until restart, but this tests API failures)
```

### 5.2 Network Connectivity Testing

**Test Alert Delivery:**
```bash
# Check webhook endpoint accessibility
curl -X POST http://localhost:8001/webhook/alerts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer agent-webhook-token-123" \
  -d '{
    "alerts": [{
      "labels": {
        "alertname": "TestAlert",
        "service": "test-service",
        "severity": "warning"
      },
      "annotations": {
        "summary": "Manual test alert"
      },
      "status": "firing"
    }]
  }'

# Expected response: {"status": "processed", "message": "Processed 1 alerts..."}
```

### 5.3 Extended Monitoring Period

**Long-Running Observation:**
```bash
# Run continuous monitoring for 30 minutes
timeout 1800 docker logs -f market-programmer-agent | tee agent_behavior_log.txt

# During this period:
# 1. Trigger various alerts every 5-10 minutes
# 2. Toggle OpenAI availability
# 3. Monitor recovery success rates
# 4. Check for memory leaks or performance degradation
```

---

## Part 6: What to Look For (Success Criteria)

### 6.1 Normal Operation Indicators

**✅ With OpenAI Available:**
- Agent startup shows no API key warnings
- Manual monitoring cycles show "Analyzing monitoring data with AI agent"
- Alert processing includes confidence scores 0.7-0.9
- Recovery recommendations are contextual and specific
- JSON-formatted AI analysis in logs

**✅ With OpenAI Unavailable:**
- Agent startup shows "Analysis agent not available, using basic monitoring"
- Manual monitoring cycles use rule-based analysis
- Alert processing shows confidence score 0.3
- Recovery actions still execute successfully
- Fallback recommendations are generic but functional

### 6.2 Recovery Action Validation

**✅ Container Restart Success:**
```bash
# Service should restart within 2.1-2.5 seconds
# Container status should change: running → exited → running
# Health endpoint should return success within 30 seconds
# Prometheus target should show "up" status
# Alert should automatically resolve
```

**✅ Multi-Step Workflow Execution:**
```
CHECK_LOGS → View container logs for error patterns
RESTART_SERVICE → Execute Docker container restart
CHECK_SERVICE_HEALTH → Validate service responds to health checks
```

### 6.3 Error Conditions to Monitor

**❌ Problems to Watch For:**
- Agent crashes on OpenAI API failures
- Recovery actions fail due to AI analysis errors
- Alert processing stops when OpenAI is unavailable
- Container restart loops or fails
- Agent attempts to restart itself (bootstrap paradox)
- Webhook authentication failures
- Memory leaks during extended operation

### 6.4 Performance Benchmarks

**Expected Metrics:**
- **Alert Processing**: < 5 seconds from receipt to recovery start
- **Container Restart**: 2.1-2.5 seconds consistently
- **Health Validation**: < 30 seconds for service recovery
- **AI Analysis**: < 10 seconds even with OpenAI API calls
- **Memory Usage**: Stable over extended periods
- **CPU Usage**: Low baseline, spikes only during recovery

---

## Part 7: Troubleshooting Guide

### 7.1 Common Issues and Solutions

**Issue: Agent not receiving alerts**
```bash
# Check Alertmanager configuration
curl http://localhost:9093/api/v1/config
# Verify webhook URL points to agent

# Check agent webhook endpoint
curl http://localhost:8001/webhook/alerts -I
# Should return 405 (Method Not Allowed) for GET

# Check authentication token
grep "webhook-token" monitoring/alertmanager/alertmanager.yml
```

**Issue: OpenAI API failures**
```bash
# Test API key manually
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Check agent logs for specific error messages
docker logs market-programmer-agent | grep -i "openai\|api\|error"
```

**Issue: Container restart fails**
```bash
# Check Docker permissions
ls -la /var/run/docker.sock

# Verify agent has access to Docker API
docker exec market-programmer-agent ls -la /var/run/docker.sock

# Test manual container restart
docker restart market-predictor
```

### 7.2 Debug Commands

**Comprehensive Status Check:**
```bash
# Agent detailed status
curl http://localhost:8001/status | jq

# Monitoring status
curl http://localhost:8001/monitoring/status | jq

# Recent agent actions
curl http://localhost:8001/monitoring/actions | jq

# Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Active alerts
curl http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state}'
```

### 7.3 Reset Procedures

**Clean Reset:**
```bash
# Stop all services
docker-compose -f docker-compose.monitoring.yml down

# Clean up containers and volumes
docker system prune -a
docker volume prune

# Restart fresh
docker-compose -f docker-compose.monitoring.yml up -d

# Wait for services to stabilize
sleep 60

# Verify all services healthy
curl http://localhost:8000/health && curl http://localhost:8001/health
```

---

## Part 8: Test Results Documentation

### 8.1 Test Execution Checklist

- [ ] **Service Startup**: All containers running and healthy
- [ ] **OpenAI Available**: AI analysis working with confidence scores 0.7+
- [ ] **OpenAI Unavailable**: Fallback analysis working with confidence 0.3
- [ ] **Service Recovery**: MarketPredictorDown triggers successful restart
- [ ] **Performance**: Recovery time within 2.1-2.5 second target
- [ ] **Alert Routing**: Agent self-alerts go to external endpoint
- [ ] **Multi-Alert**: Concurrent alert processing works correctly
- [ ] **Extended Operation**: No memory leaks or performance degradation
- [ ] **Error Handling**: Graceful failure handling for all scenarios

### 8.2 Expected Test Duration

- **Basic Functionality**: 30 minutes
- **OpenAI Scenarios**: 15 minutes  
- **Recovery Testing**: 45 minutes
- **Performance Validation**: 30 minutes
- **Extended Monitoring**: 2+ hours
- **Total Comprehensive Testing**: 3-4 hours

### 8.3 Success Metrics Summary

**✅ PASS Criteria:**
- Agent maintains 100% availability during testing
- Recovery actions succeed in both OpenAI available/unavailable scenarios  
- Performance targets met consistently (2.1-2.5s recovery)
- No crashes, errors, or bootstrap paradox issues
- Fallback analysis provides reasonable recommendations
- Alert processing continues seamlessly during OpenAI failures

**🎯 Bonus Success Indicators:**
- AI analysis provides noticeably better insights than fallback
- Recovery time improvements with AI guidance
- Intelligent alert correlation and pattern recognition
- Smooth degradation and recovery of AI capabilities

---

## Conclusion

This manual testing guide validates that your AI agent:

1. **Maintains Core Functionality** regardless of OpenAI API status
2. **Provides Enhanced Intelligence** when AI is available  
3. **Degrades Gracefully** to rule-based analysis when needed
4. **Executes Recovery Actions** reliably in all scenarios
5. **Prevents Bootstrap Paradox** through multiple protection layers

The agent should demonstrate professional-grade resilience and intelligent behavior whether running with full AI capabilities or in fallback mode.

**Ready to begin testing? Start with Part 1: Environment Setup! 🚀** 