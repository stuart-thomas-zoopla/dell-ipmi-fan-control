#!/bin/bash
while true; do
    pkill -fe low.sh
    pkill -fe high.sh

    sensor_data=$(sensors)

    cpu_temp=-273 

    while IFS= read -r line; do
        temp=$(echo "$line" | grep -o '+[0-9.]\+' | sed 's/[^0-9.]//g' | head -1)

        temp=${temp#+}

        if (( $(echo "$temp > $cpu_temp" | bc -l) )); then
            cpu_temp=$temp
        fi
    done <<< "$sensor_data"

    if (( $(echo "$cpu_temp > 65" | bc -l) )); then
        /var/www/html/fan/high.sh & 
    elif (( $(echo "$cpu_temp < 55" | bc -l) )); then
        /var/www/html/fan/low.sh &
    fi

    sleep 15
done