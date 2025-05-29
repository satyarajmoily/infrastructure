#!/bin/bash
# Infrastructure Testing Script - Comprehensive testing before GitHub push

echo "🧪 AI Agent Team Platform - Infrastructure Testing"
echo "=================================================="
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

echo "📋 DIRECTORY STRUCTURE VALIDATION"
run_test "Config directory exists" "[ -d config ]"
run_test "Scripts directory exists" "[ -d scripts ]"
run_test "Monitoring directory exists" "[ -d monitoring ]"
run_test "Documentation exists" "[ -f README.md ]"

echo ""
echo "📋 CONFIGURATION FILES"
run_test "repositories.yml exists" "[ -f config/repositories.yml ]"
run_test "agents.yml exists" "[ -f config/agents.yml ]"
run_test "docker-compose.yml exists" "[ -f docker-compose.yml ]"

echo ""
echo "📋 SCRIPT VALIDATION"
run_test "list-repositories.sh executable" "[ -x scripts/list-repositories.sh ]"

echo ""
echo "📋 FUNCTIONAL TESTS"
run_test "list-repositories.sh runs" "./scripts/list-repositories.sh > /dev/null"

echo ""
echo "📊 TEST RESULTS"
echo "✅ Tests Passed: $TESTS_PASSED"
echo "❌ Tests Failed: $TESTS_FAILED"
echo "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! Infrastructure is ready for GitHub!"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "1. Initialize git repository: git init"
    echo "2. Add files: git add ."
    echo "3. Commit: git commit -m 'Initial AI Agent Team Platform infrastructure'"
    echo "4. Add remote: git remote add origin https://github.com/satyarajmoily/infrastructure.git"
    echo "5. Push: git push -u origin main"
    exit 0
else
    echo ""
    echo "❌ SOME TESTS FAILED! Please fix before pushing to GitHub."
    exit 1
fi 