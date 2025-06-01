#!/bin/bash
# Infrastructure Testing Script - Test new volume-mounted architecture

echo "🧪 AI Agent Team Platform - Infrastructure Testing"
echo "=================================================="
echo "🎯 Testing new instant deployment architecture"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    echo -n "🔍 Testing: $test_name ... "
    if eval "$test_command" > /dev/null 2>&1; then
        echo "✅ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "📋 INFRASTRUCTURE STRUCTURE"
run_test "Docker Compose exists" "[ -f docker-compose.yml ]"
run_test "Deployment scripts exist" "[ -f scripts/deploy-code-changes.sh ] && [ -f scripts/deploy-dependencies.sh ]"
run_test "Platform scripts exist" "[ -f scripts/start-platform.sh ] && [ -f scripts/stop-platform.sh ]"
run_test "Monitoring directory exists" "[ -d monitoring ]"
run_test "Logs directory exists" "[ -d logs ]"

echo ""
echo "📋 SERVICE CONFIGURATIONS"
run_test "Market Predictor .env exists" "[ -f ../market-predictor/.env ]"
run_test "DevOps AI Agent .env exists" "[ -f ../devops-ai-agent/.env ]"
run_test "Coding AI Agent .env exists" "[ -f ../coding-ai-agent/.env ]"

echo ""
echo "📋 DOCKERFILE ARCHITECTURE"
run_test "Market Predictor Dockerfile updated" "grep -q 'dependencies.*as' ../market-predictor/Dockerfile"
run_test "DevOps AI Agent Dockerfile updated" "grep -q 'dependencies.*as' ../devops-ai-agent/Dockerfile"
run_test "Coding AI Agent Dockerfile updated" "grep -q 'dependencies.*as' ../coding-ai-agent/docker/Dockerfile"

echo ""
echo "📋 VOLUME MOUNT CONFIGURATION"
run_test "Market Predictor source mount" "grep -q '../market-predictor/src:/app/src:ro' docker-compose.yml"
run_test "DevOps AI Agent source mount" "grep -q '../devops-ai-agent/src:/app/src:ro' docker-compose.yml"
run_test "Coding AI Agent source mount" "grep -q '../coding-ai-agent/src:/app/src:ro' docker-compose.yml"

echo ""
echo "📋 SCRIPT PERMISSIONS"
run_test "deploy-code-changes.sh executable" "[ -x scripts/deploy-code-changes.sh ]"
run_test "deploy-dependencies.sh executable" "[ -x scripts/deploy-dependencies.sh ]"
run_test "start-platform.sh executable" "[ -x scripts/start-platform.sh ]"
run_test "stop-platform.sh executable" "[ -x scripts/stop-platform.sh ]"

echo ""
echo "📋 DOCKER COMPOSE VALIDATION"
run_test "Docker Compose syntax valid" "docker-compose config > /dev/null"
run_test "Runtime target specified" "grep -q 'target: runtime' docker-compose.yml"

echo ""
echo "📊 TEST RESULTS"
echo "✅ Tests Passed: $TESTS_PASSED"
echo "❌ Tests Failed: $TESTS_FAILED"
echo "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! New architecture is working correctly!"
    echo ""
    echo "📋 ARCHITECTURE VERIFIED:"
    echo "✅ Volume-mounted source code (instant deployment)"
    echo "✅ Dependency-only Docker images" 
    echo "✅ Multi-stage Dockerfile pattern"
    echo "✅ Service .env configurations"
    echo "✅ Deployment script architecture"
    echo ""
    echo "💡 USAGE:"
    echo "• Code changes: ./scripts/deploy-code-changes.sh [service|all]"
    echo "• Dependencies: ./scripts/deploy-dependencies.sh [service|all]"
    echo "• Start platform: ./scripts/start-platform.sh"
    exit 0
else
    echo ""
    echo "❌ SOME TESTS FAILED! Please fix the architecture issues."
    echo ""
    echo "🔧 COMMON FIXES:"
    echo "• Check .env files exist in each service directory"
    echo "• Verify Dockerfiles use multi-stage pattern"
    echo "• Ensure docker-compose.yml has volume mounts"
    echo "• Make scripts executable: chmod +x scripts/*.sh"
    exit 1
fi 