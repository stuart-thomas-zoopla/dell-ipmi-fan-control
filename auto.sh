#!/bin/bash

extractcpuTemperature() {
    sensorsOutput="$1"
    maxTemp=-273  # Initialize with absolute zero

    while IFS= read -r line; do
        # Remove everything after '('
        cleanedLine=$(echo "$line" | cut -d'(' -f1)
        
        # Match temperature pattern
        temp=$(echo "$cleanedLine" | grep -oP '\+\d+\.\d+\s*C' | grep -oP '\d+\.\d+')
        if [ ! -z "$temp" ]; then
            if (( $(echo "$temp > $maxTemp" | bc -l) )); then
                maxTemp="$temp"
            fi
        fi
    done <<< "$sensorsOutput"

    echo "$maxTemp"
}

while true; do
    pkill -fe low.sh
    pkill -fe high.sh

    sensor_data=$(sensors)

    cpu_temp=$(extractcpuTemperature "$sensor_data")

    if (( $(echo "$cpu_temp > 65" | bc -l) )); then
        /var/www/html/fan/high.sh & 
    elif (( $(echo "$cpu_temp < 55" | bc -l) )); then
        /var/www/html/fan/low.sh &
    fi

    sleep 15
done
