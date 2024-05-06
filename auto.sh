#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null
echo "LOWERRPM: $LOWERRPM" > /dev/null
echo "UPPERRPM: $UPPERRPM" > /dev/null
echo "MINTEMP: $MINTEMP" > /dev/null
echo "HIGHTEMP: $HIGHTEMP" > /dev/null

# Set lower and upper RPM limits
lowerRpmLimit=$LOWERRPM
upperRpmLimit=$UPPERRPM

# Set minimum and high temperature thresholds
minTemp=$MINTEMP
highTemp=$HIGHTEMP

setManual="0x30 0x30 0x01 0x00"
setAuto="0x30 0x30 0x01 0x01"
setSpeed="0x30 0x30 0x02 0xff " 

start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

do_Setup() {
   chmod +x /usr/bin/ipmitool 
   eval $start "raw 0x30 0x30 0x01 0x00"
}

# Function to extract CPU temperature from sensors output
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

# Function to calculate fan speed based on CPU temperature
calculateDemandValue() {
    cpu_temp="$1"

    if (( $(echo "$cpu_temp < $minTemp" | bc -l) )); then
        autoMap=$lowerRpmLimit
    elif (( $(echo "$cpu_temp > $highTemp" | bc -l) )); then
        autoMap=$upperRpmLimit
        else
        # Convert temperatures to integers for arithmetic operations
        cpu_temp_int=$(printf "%.0f" "$cpu_temp")
        minTemp_int=$(printf "%.0f" "$minTemp")

        # Calculate the temperature difference
        temp_diff=$((cpu_temp_int - minTemp_int))

        # Linearly interpolate fan speed between lower and upper RPM limits based on temperature
        temp_range=$((highTemp - minTemp))
        speed_range=$((upperRpmLimit - lowerRpmLimit))

        # Calculate fan speed using linear interpolation
        automap=$((lowerRpmLimit + (temp_diff * speed_range) / temp_range))
    fi

    if [[ "$automap" -gt 49 ]]; then
        autoMap=$(round_to_nearest $automap)
    else
        autoMap=$automap
    fi

    echo "$autoMap"
}

round_to_nearest() {
    local num=$1
    local remainder=$((num % 10))

    if [ $remainder -le 2 ]; then
        echo $((num - remainder))
    elif [ $remainder -ge 8 ]; then
        echo $((num + (10 - remainder)))
    else
        echo $((num + (5 - remainder)))
    fi
}

# Main script
while true; do

    sensor_data=$(sensors)
    
    cpu_temp=$(extractcpuTemperature "$sensor_data")
    autoMap=$(calculateDemandValue "$cpu_temp")

    echo "CPU Temperature: $cpu_temp°C"
    echo "Automap: $autoMap "

    if [[ "$autoMap" -le 22 ]]; then
    hex=$(printf '%x' "23")
    eval $start "raw $setSpeed"'0'"$hex"
    elif [[ "$autoMap" -gt 25 && "$autoMap" -le 32 ]]; then
    hex=$(printf '%x' "32")   
    eval $start "raw $setSpeed$hex"
    elif [[ "$autoMap" -gt 41 && "$autoMap" -le 50 ]]; then
    hex=$(printf '%x' "50")   
    eval $start "raw $setSpeed$hex"
    elif [[ "$autoMap" -gt 59 && "$autoMap" -le 65 ]]; then
    hex=$(printf '%x' "65")   
    eval $start "raw $setSpeed$hex"
    elif [[ "$autoMap" -gt 69 && "$autoMap" -le 75 ]]; then
    hex=$(printf '%x' "65")   
    eval $start "raw $setSpeed$hex"
    elif [[ "$autoMap" -gt 89 && "$autoMap" -le 100 ]]; then
    hex=$(printf '%x' "100")   
    eval $start "raw $setSpeed$hex"
    elif [[ "$autoMap" -gt 109 ]]; then
    hex=$(printf '%x' "120")   
    eval $start "raw $setSpeed$hex"
    else
    hex=$(printf '%x' "$autoMap")   
    eval $start "raw $setSpeed$hex"
    fi

    sleep 15
done