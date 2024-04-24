#!/bin/bash
while true; do
    pkill -fe low.sh
    pkill -fe high.sh

    sensor_data=$(sensors)

    highest_temp=-273 

    while IFS= read -r line; do
        temp=$(echo "$line" | grep -o '+[0-9.]\+' | sed 's/[^0-9.]//g' | head -1)

        temp=${temp#+}

        if (( $(echo "$temp > $highest_temp" | bc -l) )); then
            highest_temp=$temp
        fi
    done <<< "$sensor_data"

    if (( $(echo "$highest_temp > 65" | bc -l) )); then
        /var/www/html/fan/high.sh & 
    elif (( $(echo "$highest_temp < 55" | bc -l) )); then
        /var/www/html/fan/low.sh &
    fi

    sleep 15
done