#!/bin/bash

# VPS Infrastructure Testing Framework
# Comprehensive testing suite for validating infrastructure deployment and functionality

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test configuration
TEST_LOG="/var/log/infrastructure-tests.log"
RESULTS_DIR="/tmp/test-results-$(date +%Y%m%d_%H%M%S)"
FAILED_TESTS=0
PASSED_TESTS=0
TOTAL_TESTS=0

# Infrastructure configuration
GITLAB_PRIVATE_IP="10.0.0.10"
NGINX_PRIVATE_IP="10.0.0.20"
GITLAB_PUBLIC_IP="136.243.208.130"
NGINX_PUBLIC_IP="136.243.208.131"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$TEST_LOG"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$TEST_LOG"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$TEST_LOG"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$TEST_LOG"
}

success() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$TEST_LOG"
}

# Test result functions
test_pass() {
    local test_name="$1"
    echo -e "  ✅ ${GREEN}PASS${NC}: $test_name" | tee -a "$TEST_LOG"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo -e "  ❌ ${RED}FAIL${NC}: $test_name - $reason" | tee -a "$TEST_LOG"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

test_skip() {
    local test_name="$1"
    local reason="$2"
    echo -e "  ⏭️  ${YELLOW}SKIP${NC}: $test_name - $reason" | tee -a "$TEST_LOG"
    ((TOTAL_TESTS++))
}

# Show test banner
show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║    🧪 VPS Infrastructure Testing Framework                                    ║
║                                                                               ║
║    Comprehensive validation of GitLab + Nginx VPS infrastructure             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Initialize testing environment
init_testing() {
    log "🚀 Initializing testing environment..."

    # Create results directory
    mkdir -p "$RESULTS_DIR"

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "Testing framework must be run as root for comprehensive tests"
        exit 1
    fi

    log "📁 Test results will be saved to: $RESULTS_DIR"

    # Clear previous logs
    > "$TEST_LOG"

    success "Testing environment initialized"
}

# Test 1: System Requirements
test_system_requirements() {
    echo ""
    info "🔍 Testing System Requirements"

    # Check available memory
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $memory_gb -ge 16 ]]; then
        test_pass "System has sufficient memory (${memory_gb}GB)"
    else
        test_fail "System memory insufficient" "Has ${memory_gb}GB, requires 16GB+"
    fi

    # Check available disk space
    local disk_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $disk_gb -ge 200 ]]; then
        test_pass "System has sufficient disk space (${disk_gb}GB available)"
    else
        test_fail "System disk space insufficient" "Has ${disk_gb}GB, requires 200GB+"
    fi

    # Check virtualization support
    if command -v kvm-ok &> /dev/null && kvm-ok &> /dev/null; then
        test_pass "KVM virtualization supported"
    else
        test_fail "KVM virtualization not supported" "kvm-ok failed"
    fi

    # Check required commands
    local required_commands=("vagrant" "virsh" "docker" "git")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            test_pass "Required command available: $cmd"
        else
            test_fail "Required command missing: $cmd" "Command not found"
        fi
    done
}

# Test 2: Network Configuration
test_network_configuration() {
    echo ""
    info "🌐 Testing Network Configuration"

    # Check bridge interfaces
    if ip link show | grep -q "virbr"; then
        test_pass "Virtual bridge interfaces configured"
    else
        test_fail "Virtual bridge interfaces missing" "No virbr interfaces found"
    fi

    # Check IP forwarding
    if sysctl net.ipv4.ip_forward | grep -q "1"; then
        test_pass "IP forwarding enabled"
    else
        test_fail "IP forwarding disabled" "net.ipv4.ip_forward = 0"
    fi

    # Test network connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        test_pass "External network connectivity"
    else
        test_fail "External network connectivity failed" "Cannot reach 8.8.8.8"
    fi

    # Check for conflicting services
    if ss -tlnp | grep -q ":80\b"; then
        local service=$(ss -tlnp | grep ":80\b" | head -1 | awk -F'"' '{print $2}')
        test_fail "Port 80 conflict detected" "Service using port 80: $service"
    else
        test_pass "Port 80 available"
    fi

    if ss -tlnp | grep -q ":443\b"; then
        local service=$(ss -tlnp | grep ":443\b" | head -1 | awk -F'"' '{print $2}')
        test_fail "Port 443 conflict detected" "Service using port 443: $service"
    else
        test_pass "Port 443 available"
    fi
}

# Test 3: VPS Instance Status
test_vps_instances() {
    echo ""
    info "🖥️ Testing VPS Instances"

    # Check GitLab VPS
    if virsh list --all | grep -q "gitlab-vps"; then
        local gitlab_status=$(virsh list --all | grep "gitlab-vps" | awk '{print $3}')
        if [[ "$gitlab_status" == "running" ]]; then
            test_pass "GitLab VPS is running"

            # Test GitLab VPS connectivity
            if ping -c 3 "$GITLAB_PRIVATE_IP" >/dev/null 2>&1; then
                test_pass "GitLab VPS network connectivity"
            else
                test_fail "GitLab VPS network connectivity" "Cannot ping $GITLAB_PRIVATE_IP"
            fi
        else
            test_fail "GitLab VPS not running" "Status: $gitlab_status"
        fi
    else
        test_fail "GitLab VPS not found" "VPS instance does not exist"
    fi

    # Check Nginx VPS
    if virsh list --all | grep -q "nginx-app-vps"; then
        local nginx_status=$(virsh list --all | grep "nginx-app-vps" | awk '{print $3}')
        if [[ "$nginx_status" == "running" ]]; then
            test_pass "Nginx App VPS is running"

            # Test Nginx VPS connectivity
            if ping -c 3 "$NGINX_PRIVATE_IP" >/dev/null 2>&1; then
                test_pass "Nginx App VPS network connectivity"
            else
                test_fail "Nginx App VPS network connectivity" "Cannot ping $NGINX_PRIVATE_IP"
            fi
        else
            test_fail "Nginx App VPS not running" "Status: $nginx_status"
        fi
    else
        test_fail "Nginx App VPS not found" "VPS instance does not exist"
    fi

    # Check inter-VPS connectivity
    if ping -c 1 "$GITLAB_PRIVATE_IP" >/dev/null 2>&1 && ping -c 1 "$NGINX_PRIVATE_IP" >/dev/null 2>&1; then
        test_pass "Inter-VPS network connectivity"
    else
        test_fail "Inter-VPS network connectivity" "VPS instances cannot communicate"
    fi
}

# Test 4: Service Availability
test_service_availability() {
    echo ""
    info "🔧 Testing Service Availability"

    # Test GitLab services
    if ping -c 1 "$GITLAB_PRIVATE_IP" >/dev/null 2>&1; then
        # Test GitLab web interface
        if timeout 10 bash -c "</dev/tcp/$GITLAB_PRIVATE_IP/80" 2>/dev/null; then
            test_pass "GitLab HTTP service accessible"
        else
            test_fail "GitLab HTTP service" "Port 80 not accessible"
        fi

        # Test GitLab HTTPS
        if timeout 10 bash -c "</dev/tcp/$GITLAB_PRIVATE_IP/443" 2>/dev/null; then
            test_pass "GitLab HTTPS service accessible"
        else
            test_fail "GitLab HTTPS service" "Port 443 not accessible"
        fi

        # Test GitLab Container Registry
        if timeout 10 bash -c "</dev/tcp/$GITLAB_PRIVATE_IP/5050" 2>/dev/null; then
            test_pass "GitLab Container Registry accessible"
        else
            test_fail "GitLab Container Registry" "Port 5050 not accessible"
        fi

        # Test Netdata monitoring
        if timeout 10 bash -c "</dev/tcp/$GITLAB_PRIVATE_IP/19999" 2>/dev/null; then
            test_pass "GitLab Netdata monitoring accessible"
        else
            test_fail "GitLab Netdata monitoring" "Port 19999 not accessible"
        fi
    else
        test_skip "GitLab service tests" "GitLab VPS not reachable"
    fi

    # Test Nginx services
    if ping -c 1 "$NGINX_PRIVATE_IP" >/dev/null 2>&1; then
        # Test Nginx web server
        if timeout 10 bash -c "</dev/tcp/$NGINX_PRIVATE_IP/80" 2>/dev/null; then
            test_pass "Nginx HTTP service accessible"
        else
            test_fail "Nginx HTTP service" "Port 80 not accessible"
        fi

        # Test Nginx HTTPS
        if timeout 10 bash -c "</dev/tcp/$NGINX_PRIVATE_IP/443" 2>/dev/null; then
            test_pass "Nginx HTTPS service accessible"
        else
            test_fail "Nginx HTTPS service" "Port 443 not accessible"
        fi

        # Test Node.js application
        if timeout 10 bash -c "</dev/tcp/$NGINX_PRIVATE_IP/3000" 2>/dev/null; then
            test_pass "Node.js application accessible"
        else
            test_fail "Node.js application" "Port 3000 not accessible"
        fi

        # Test Netdata monitoring
        if timeout 10 bash -c "</dev/tcp/$NGINX_PRIVATE_IP/19999" 2>/dev/null; then
            test_pass "Nginx Netdata monitoring accessible"
        else
            test_fail "Nginx Netdata monitoring" "Port 19999 not accessible"
        fi
    else
        test_skip "Nginx service tests" "Nginx VPS not reachable"
    fi
}

# Test 5: Application Functionality
test_application_functionality() {
    echo ""
    info "🚀 Testing Application Functionality"

    # Test GitLab web interface response
    if command -v curl &> /dev/null; then
        if curl -f -s -k "http://$GITLAB_PRIVATE_IP" >/dev/null; then
            test_pass "GitLab web interface responds"
        else
            test_fail "GitLab web interface" "HTTP request failed"
        fi

        # Test GitLab health check
        if curl -f -s -k "http://$GITLAB_PRIVATE_IP/-/health" >/dev/null; then
            test_pass "GitLab health check endpoint"
        else
            test_fail "GitLab health check" "Health endpoint not responding"
        fi
    else
        test_skip "GitLab web tests" "curl command not available"
    fi

    # Test Node.js application
    if command -v curl &> /dev/null && ping -c 1 "$NGINX_PRIVATE_IP" >/dev/null 2>&1; then
        if curl -f -s "http://$NGINX_PRIVATE_IP:3000/health" >/dev/null; then
            test_pass "Node.js application health check"
        else
            test_fail "Node.js application health" "Health endpoint not responding"
        fi

        # Test application API
        if curl -f -s "http://$NGINX_PRIVATE_IP:3000/api/status" >/dev/null; then
            test_pass "Node.js application API"
        else
            test_fail "Node.js application API" "API endpoint not responding"
        fi
    else
        test_skip "Node.js application tests" "curl not available or VPS not reachable"
    fi
}

# Test 6: Security Configuration
test_security_configuration() {
    echo ""
    info "🔐 Testing Security Configuration"

    # Test firewall status
    if ufw status | grep -q "Status: active"; then
        test_pass "UFW firewall is active"
    else
        test_fail "UFW firewall status" "Firewall is not active"
    fi

    # Test fail2ban
    if systemctl is-active --quiet fail2ban; then
        test_pass "Fail2ban is running"

        # Check fail2ban jails
        local jail_count=$(fail2ban-client status | grep "Jail list" | awk -F: '{print $2}' | wc -w)
        if [[ $jail_count -gt 0 ]]; then
            test_pass "Fail2ban jails configured ($jail_count jails)"
        else
            test_fail "Fail2ban jails" "No jails configured"
        fi
    else
        test_fail "Fail2ban service" "Service not running"
    fi

    # Test SSH configuration
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
        test_pass "SSH password authentication disabled"
    else
        test_fail "SSH password authentication" "Password auth still enabled"
    fi

    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        test_pass "SSH root login disabled"
    else
        test_fail "SSH root login" "Root login still enabled"
    fi

    # Test for exposed services
    local exposed_services=$(nmap -sT localhost 2>/dev/null | grep "open" | grep -v "22/tcp\|80/tcp\|443/tcp" | wc -l)
    if [[ $exposed_services -eq 0 ]]; then
        test_pass "No unexpected services exposed"
    else
        test_fail "Service exposure" "$exposed_services unexpected services exposed"
    fi
}

# Test 7: Monitoring Systems
test_monitoring_systems() {
    echo ""
    info "📊 Testing Monitoring Systems"

    # Test Netdata
    if systemctl is-active --quiet netdata; then
        test_pass "Netdata monitoring service running"

        # Test Netdata web interface
        if timeout 5 bash -c "</dev/tcp/localhost/19999" 2>/dev/null; then
            test_pass "Netdata web interface accessible"
        else
            test_fail "Netdata web interface" "Port 19999 not accessible"
        fi
    else
        test_fail "Netdata monitoring" "Service not running"
    fi

    # Test Prometheus Node Exporter
    if systemctl is-active --quiet prometheus-node-exporter; then
        test_pass "Prometheus Node Exporter running"

        # Test metrics endpoint
        if timeout 5 bash -c "</dev/tcp/localhost/9100" 2>/dev/null; then
            test_pass "Node Exporter metrics accessible"
        else
            test_fail "Node Exporter metrics" "Port 9100 not accessible"
        fi
    else
        test_fail "Prometheus Node Exporter" "Service not running"
    fi

    # Test Collectd
    if systemctl is-active --quiet collectd; then
        test_pass "Collectd monitoring service running"
    else
        test_fail "Collectd monitoring" "Service not running"
    fi

    # Test monitoring scripts
    if [[ -x "/opt/monitoring-dashboard.sh" ]]; then
        test_pass "Monitoring dashboard script available"
    else
        test_fail "Monitoring dashboard" "Script not found or not executable"
    fi

    if [[ -x "/opt/health-check.sh" ]]; then
        test_pass "Health check script available"
    else
        test_fail "Health check script" "Script not found or not executable"
    fi
}

# Test 8: Backup System
test_backup_system() {
    echo ""
    info "💾 Testing Backup System"

    # Test backup script
    if [[ -x "/opt/xcloud/vps-hosting-infrastructure/core/shared/scripts/backup-management.sh" ]]; then
        test_pass "Backup management script available"

        # Test backup verification
        if /opt/xcloud/vps-hosting-infrastructure/core/shared/scripts/backup-management.sh --verify >/dev/null 2>&1; then
            test_pass "Backup system verification"
        else
            test_fail "Backup system verification" "Verification failed"
        fi
    else
        test_fail "Backup management script" "Script not found or not executable"
    fi

    # Check backup directory
    if [[ -d "/backup" ]]; then
        test_pass "Backup directory exists"

        # Check backup permissions
        if [[ -w "/backup" ]]; then
            test_pass "Backup directory writable"
        else
            test_fail "Backup directory permissions" "Directory not writable"
        fi
    else
        test_fail "Backup directory" "Directory /backup does not exist"
    fi

    # Check cron jobs
    if crontab -l 2>/dev/null | grep -q "backup\|health-check"; then
        test_pass "Backup/monitoring cron jobs configured"
    else
        test_fail "Cron jobs" "No backup or monitoring cron jobs found"
    fi
}

# Test 9: Performance Validation
test_performance_validation() {
    echo ""
    info "⚡ Testing Performance Validation"

    # Test system load
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpu_cores=$(nproc)

    if (( $(echo "$load_avg < $cpu_cores" | bc -l) )); then
        test_pass "System load acceptable ($load_avg < $cpu_cores cores)"
    else
        test_fail "System load high" "Load average $load_avg exceeds CPU cores $cpu_cores"
    fi

    # Test memory usage
    local memory_usage=$(free | grep '^Mem:' | awk '{printf "%.1f", $3/$2 * 100.0}')
    local memory_usage_int=${memory_usage%.*}

    if [[ $memory_usage_int -lt 80 ]]; then
        test_pass "Memory usage acceptable (${memory_usage}%)"
    else
        test_fail "Memory usage high" "Memory usage ${memory_usage}% exceeds threshold"
    fi

    # Test disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    if [[ $disk_usage -lt 80 ]]; then
        test_pass "Disk usage acceptable (${disk_usage}%)"
    else
        test_fail "Disk usage high" "Disk usage ${disk_usage}% exceeds threshold"
    fi

    # Test response times
    if command -v curl &> /dev/null && ping -c 1 "$NGINX_PRIVATE_IP" >/dev/null 2>&1; then
        local response_time=$(curl -o /dev/null -s -w '%{time_total}' "http://$NGINX_PRIVATE_IP:3000/health" 2>/dev/null || echo "999")

        if (( $(echo "$response_time < 2.0" | bc -l) )); then
            test_pass "Application response time acceptable (${response_time}s)"
        else
            test_fail "Application response time" "Response time ${response_time}s exceeds 2s threshold"
        fi
    else
        test_skip "Response time test" "curl not available or VPS not reachable"
    fi
}

# Test 10: Integration Tests
test_integration_functionality() {
    echo ""
    info "🔗 Testing Integration Functionality"

    # Test GitLab to Nginx communication
    if ping -c 1 "$GITLAB_PRIVATE_IP" >/dev/null 2>&1 && ping -c 1 "$NGINX_PRIVATE_IP" >/dev/null 2>&1; then
        test_pass "GitLab-Nginx network communication"

        # Test if Nginx can proxy to GitLab
        if command -v curl &> /dev/null; then
            # This would test a configured proxy path
            test_skip "GitLab proxy integration" "Requires specific proxy configuration"
        fi
    else
        test_fail "GitLab-Nginx integration" "Network communication failed"
    fi

    # Test Docker integration
    if command -v docker &> /dev/null && docker ps >/dev/null 2>&1; then
        test_pass "Docker integration functional"

        # Test if there are running containers
        local container_count=$(docker ps -q | wc -l)
        if [[ $container_count -gt 0 ]]; then
            test_pass "Docker containers running ($container_count containers)"
        else
            test_skip "Docker containers" "No containers currently running"
        fi
    else
        test_fail "Docker integration" "Docker not available or not running"
    fi

    # Test infrastructure management script
    if [[ -x "/opt/xcloud/vps-hosting-infrastructure/core/shared/scripts/infrastructure-mgmt.sh" ]]; then
        test_pass "Infrastructure management script available"

        # Test status command
        if /opt/xcloud/vps-hosting-infrastructure/core/shared/scripts/infrastructure-mgmt.sh status >/dev/null 2>&1; then
            test_pass "Infrastructure status command functional"
        else
            test_fail "Infrastructure status command" "Command execution failed"
        fi
    else
        test_fail "Infrastructure management script" "Script not found or not executable"
    fi
}

# Generate test report
generate_test_report() {
    echo ""
    log "📋 Generating Test Report"

    local report_file="$RESULTS_DIR/test-report.txt"
    local json_report="$RESULTS_DIR/test-report.json"

    # Text report
    cat > "$report_file" << EOF
VPS Infrastructure Test Report
=============================

Date: $(date)
Hostname: $(hostname)
Test Duration: ${SECONDS}s

Test Summary:
- Total Tests: $TOTAL_TESTS
- Passed: $PASSED_TESTS
- Failed: $FAILED_TESTS
- Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%

System Information:
- OS: $(lsb_release -d | cut -f2)
- Kernel: $(uname -r)
- CPU Cores: $(nproc)
- Memory: $(free -h | grep '^Mem:' | awk '{print $2}')
- Disk Space: $(df -h / | tail -1 | awk '{print $4}') available

Network Configuration:
- GitLab VPS: $GITLAB_PRIVATE_IP (Private), $GITLAB_PUBLIC_IP (Public)
- Nginx VPS: $NGINX_PRIVATE_IP (Private), $NGINX_PUBLIC_IP (Public)

Test Results:
$(cat "$TEST_LOG" | grep -E "(PASS|FAIL|SKIP)")

EOF

    # JSON report
    cat > "$json_report" << EOF
{
  "test_summary": {
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "duration_seconds": $SECONDS,
    "total_tests": $TOTAL_TESTS,
    "passed_tests": $PASSED_TESTS,
    "failed_tests": $FAILED_TESTS,
    "success_rate": $(( PASSED_TESTS * 100 / TOTAL_TESTS ))
  },
  "system_info": {
    "os": "$(lsb_release -d | cut -f2)",
    "kernel": "$(uname -r)",
    "cpu_cores": $(nproc),
    "memory_gb": $(free -g | awk '/^Mem:/{print $2}'),
    "disk_available_gb": "$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')"
  },
  "network_config": {
    "gitlab_private_ip": "$GITLAB_PRIVATE_IP",
    "gitlab_public_ip": "$GITLAB_PUBLIC_IP",
    "nginx_private_ip": "$NGINX_PRIVATE_IP",
    "nginx_public_ip": "$NGINX_PUBLIC_IP"
  }
}
EOF

    success "Test report generated: $report_file"
    success "JSON report generated: $json_report"
}

# Main test execution
run_all_tests() {
    log "🧪 Starting comprehensive infrastructure testing..."

    test_system_requirements
    test_network_configuration
    test_vps_instances
    test_service_availability
    test_application_functionality
    test_security_configuration
    test_monitoring_systems
    test_backup_system
    test_performance_validation
    test_integration_functionality

    generate_test_report
}

# Quick smoke tests
run_smoke_tests() {
    log "💨 Running quick smoke tests..."

    test_vps_instances
    test_service_availability
    test_monitoring_systems

    generate_test_report
}

# Security-focused tests
run_security_tests() {
    log "🔐 Running security-focused tests..."

    test_security_configuration
    test_service_availability

    generate_test_report
}

# Performance tests
run_performance_tests() {
    log "⚡ Running performance tests..."

    test_performance_validation
    test_application_functionality

    generate_test_report
}

# Show usage
show_usage() {
    cat << EOF
VPS Infrastructure Testing Framework
Usage: $0 [OPTIONS]

OPTIONS:
    --all               Run all tests (default)
    --smoke             Run quick smoke tests
    --security          Run security-focused tests
    --performance       Run performance tests
    --network           Run network tests only
    --services          Run service tests only
    --help              Show this help message

EXAMPLES:
    $0                  # Run all tests
    $0 --smoke          # Quick validation
    $0 --security       # Security audit
    $0 --performance    # Performance check

OUTPUTS:
    Test results are saved to: /tmp/test-results-<timestamp>/
    Detailed logs: /var/log/infrastructure-tests.log

EOF
}

# Display test summary
show_test_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${PURPLE}🧪 VPS Infrastructure Test Summary${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "📊 Total Tests: ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "✅ Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "❌ Failed: ${RED}$FAILED_TESTS${NC}"

    if [[ $TOTAL_TESTS -gt 0 ]]; then
        local success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
        echo -e "📈 Success Rate: ${CYAN}${success_rate}%${NC}"

        if [[ $FAILED_TESTS -eq 0 ]]; then
            echo -e "🎉 ${GREEN}All tests passed! Infrastructure is ready.${NC}"
        elif [[ $success_rate -ge 80 ]]; then
            echo -e "⚠️  ${YELLOW}Most tests passed. Review failures.${NC}"
        else
            echo -e "🚨 ${RED}Many tests failed. Infrastructure needs attention.${NC}"
        fi
    fi

    echo -e "📁 Results saved to: ${BLUE}$RESULTS_DIR${NC}"
    echo "═══════════════════════════════════════════════════════════════"
}

# Main function
main() {
    show_banner
    init_testing

    case "${1:-}" in
        "--smoke")
            run_smoke_tests
            ;;
        "--security")
            run_security_tests
            ;;
        "--performance")
            run_performance_tests
            ;;
        "--network")
            test_network_configuration
            test_vps_instances
            generate_test_report
            ;;
        "--services")
            test_service_availability
            test_application_functionality
            generate_test_report
            ;;
        "--help")
            show_usage
            exit 0
            ;;
        "--all"|"")
            run_all_tests
            ;;
        *)
            error "Unknown option: $1. Use --help for usage information."
            exit 1
            ;;
    esac

    show_test_summary

    # Exit with error code if tests failed
    if [[ $FAILED_TESTS -gt 0 ]]; then
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
