#!/bin/bash

# Threshold for health status
THRESHOLD=60

# Colors for formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'  # No color

# Function to get CPU utilization
get_cpu_usage() {
    if command -v mpstat &>/dev/null; then
        local idle=$(mpstat 1 1 | awk '/Average/ {print $NF}')
        if [[ -n "$idle" && "$idle" != "N/A" ]]; then
            local usage=$(awk "BEGIN {print 100 - $idle}")
            echo "$usage"
        else
            echo "N/A"
        fi
    else
        local idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1)
        if [[ -n "$idle" && "$idle" != "N/A" ]]; then
            local usage=$(awk "BEGIN {print 100 - $idle}")
            echo "$usage"
        else
            echo "N/A"
        fi
    fi
}

# Function to get memory utilization
get_mem_usage() {
    local mem_total=$(free | awk '/Mem:/ {print $2}')
    local mem_used=$(free | awk '/Mem:/ {print $3}')

    if [[ -n "$mem_total" && -n "$mem_used" && "$mem_total" -gt 0 ]]; then
        local mem_usage=$(awk "BEGIN {print ($mem_used/$mem_total)*100}")
        echo "$mem_usage"
    else
        echo "N/A"
    fi
}

# Function to get disk utilization (root partition)
get_disk_usage() {
    local disk_usage=$(df --output=pcent / | tail -n1 | tr -dc '0-9')
    if [[ -n "$disk_usage" ]]; then
        echo "$disk_usage"
    else
        echo "N/A"
    fi
}

# Fetch metrics
cpu=$(get_cpu_usage)
mem=$(get_mem_usage)
disk=$(get_disk_usage)

# Determine health status
overall_status="HEALTHY"
explanation=""

# CPU Check
if [[ "$cpu" != "N/A" && $(awk "BEGIN {print ($cpu > $THRESHOLD)}") -eq 1 ]]; then
    overall_status="NOT HEALTHY"
    explanation+="CPU Usage: ${cpu}%\n"
fi

# Memory Check
if [[ "$mem" != "N/A" && $(awk "BEGIN {print ($mem > $THRESHOLD)}") -eq 1 ]]; then
    overall_status="NOT HEALTHY"
    explanation+="Memory Usage: ${mem}%\n"
fi

# Disk Check
if [[ "$disk" != "N/A" && "$disk" -gt "$THRESHOLD" ]]; then
    overall_status="NOT HEALTHY"
    explanation+="Disk Usage: ${disk}%\n"
fi

# Display output
echo -e "${BLUE}=== RHEL 9 Instance Health Check ===${NC}\n"

# Disk Section
echo -e "${YELLOW}Disk Usage:${NC}"
echo -e "Status: ${disk}%"
if [[ "$disk" != "N/A" && "$disk" -gt "$THRESHOLD" ]]; then
    echo -e "Health: ${RED}NOT HEALTHY${NC}"
else
    echo -e "Health: ${GREEN}HEALTHY${NC}"
fi
echo

# CPU Section
echo -e "${YELLOW}CPU Usage:${NC}"
echo -e "Status: ${cpu}%"
if [[ "$cpu" != "N/A" && $(awk "BEGIN {print ($cpu > $THRESHOLD)}") -eq 1 ]]; then
    echo -e "Health: ${RED}NOT HEALTHY${NC}"
else
    echo -e "Health: ${GREEN}HEALTHY${NC}"
fi
echo

# Memory Section
echo -e "${YELLOW}Memory Usage:${NC}"
echo -e "Status: ${mem}%"
if [[ "$mem" != "N/A" && $(awk "BEGIN {print ($mem > $THRESHOLD)}") -eq 1 ]]; then
    echo -e "Health: ${RED}NOT HEALTHY${NC}"
else
    echo -e "Health: ${GREEN}HEALTHY${NC}"
fi
echo

# Detailed Explanation
echo -e "${YELLOW}=== Detailed Explanation ===${NC}"
echo -e "Disk Space: ${disk}%"
echo -e "CPU Usage: ${cpu}%"
echo -e "Memory Usage: ${mem}%"
echo -e "\nThreshold for all metrics: ${THRESHOLD}%\n"

# Overall System Health
echo -e "${BLUE}=== Overall System Health ===${NC}"
if [ "$overall_status" == "HEALTHY" ]; then
    echo -e "Status: ${GREEN}${overall_status}${NC}"
else
    echo -e "Status: ${RED}${overall_status}${NC}"
fi

# Exit with proper status
if [ "$overall_status" == "HEALTHY" ]; then
    exit 0
else
    exit 1
fi
