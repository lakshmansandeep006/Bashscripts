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
    if command -v mpstat &> /dev/null; then
        local idle=$(mpstat 1 1 | awk '/Average/ {print 100 - $NF}')
        echo "$idle"
    else
        local idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}')
        local usage=$(echo "100 - $idle" | bc)
        echo "$usage"
    fi
}

# Function to get memory utilization
get_mem_usage() {
    local mem_usage=$(free | awk '/Mem:/ {printf "%.2f", $3/$2 * 100}')
    echo "$mem_usage"
}

# Function to get disk utilization (root partition)
get_disk_usage() {
    local disk_usage=$(df --output=pcent / | tail -n1 | tr -dc '0-9')
    echo "$disk_usage"
}

# Fetch metrics
cpu=$(get_cpu_usage)
mem=$(get_mem_usage)
disk=$(get_disk_usage)

# Determine health status
overall_status="HEALTHY"
explanation=""

# CPU Check
if (( $(echo "$cpu > $THRESHOLD" | bc -l) )); then
    overall_status="NOT HEALTHY"
    explanation+="CPU Usage: ${cpu}%\n"
fi

# Memory Check
if (( $(echo "$mem > $THRESHOLD" | bc -l) )); then
    overall_status="NOT HEALTHY"
    explanation+="Memory Usage: ${mem}%\n"
fi

# Disk Check
if (( "$disk" > "$THRESHOLD" )); then
    overall_status="NOT HEALTHY"
    explanation+="Disk Usage: ${disk}%\n"
fi

# Display output
echo -e "${BLUE}=== RedHat 9 Instance Health Check ===${NC}\n"

# Disk Section
echo -e "${YELLOW}Disk Usage:${NC}"
echo -e "Status: ${disk}%"
if (( "$disk" > "$THRESHOLD" )); then
    echo -e "Health: ${RED}NOT HEALTHY${NC}"
else
    echo -e "Health: ${GREEN}HEALTHY${NC}"
fi
echo

# CPU Section
echo -e "${YELLOW}CPU Usage:${NC}"
echo -e "Status: ${cpu}%"
if (( $(echo "$cpu > $THRESHOLD" | bc -l) )); then
    echo -e "Health: ${RED}NOT HEALTHY${NC}"
else
    echo -e "Health: ${GREEN}HEALTHY${NC}"
fi
echo

# Memory Section
echo -e "${YELLOW}Memory Usage:${NC}"
echo -e "Status: ${mem}%"
if (( $(echo "$mem > $THRESHOLD" | bc -l) )); then
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
