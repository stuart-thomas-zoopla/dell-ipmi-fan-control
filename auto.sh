#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null
echo "LOWERRPM: $LOWERRPM" > /dev/null
echo "UPPERRPM: $UPPERRPM" > /dev/null
echo "MINTEMP: $MINTEMP" > /dev/null
echo "HIGHTEMP: $HIGHTEMP" > /dev/null
echo "HYSTERESIS: $HYSTERESIS" >/dev/null

# Set lower and upper RPM limits
lowerRpmLimit=$LOWERRPM
upperRpmLimit=$UPPERRPM

# Set minimum and high temperature thresholds
minTemp=$MINTEMP
highTemp=$HIGHTEMP
hysteresis=$HYSTERESIS
previous_cpu_temp=-273

setManual="0x30 0x30 0x01 0x00"
setAuto="0x30 0x30 0x01 0x01"
setSpeed="0x30 0x30 0x02 0xff " 

start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

do_Setup() {
   eval $start "raw 0x30 0x30 0x01 0x00"
   pkill -fe auto.sh # prevent two instances of the script running
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
        automap=$lowerRpmLimit
    elif (( $(echo "$cpu_temp > $highTemp" | bc -l) )); then
        automap=$upperRpmLimit
        else
        # Convert temperatures to integers for arithmetic operations
        minTemp_int=$(printf "%.0f" "$minTemp")

        # Calculate the temperature difference
        temp_diff=$((cpu_temp - minTemp_int))

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
    cpu_temp_int=$(printf "%.0f" "$cpu_temp")
    autoMap=$(calculateDemandValue "$cpu_temp_int")

    echo "CPU Temperature: $cpu_temp°C"
    echo "Automap: $autoMap "

    # Check if the temperature difference is significant enough to adjust fan speed
    temp_diff=$((cpu_temp_int - previous_cpu_temp))
    echo "Temp diff: $temp_diff"
    if ((temp_diff >= hysteresis || temp_diff <= 0 - hysteresis)); then
        retry_count=0
        max_retries=10

        while [ $retry_count -lt $max_retries ]; do
            ((retry_count++))
            hex=$(printf '%x' "$autoMap")
        
            if [[ "$autoMap" -le 7 ]]; then
                command="raw $setSpeed"'0'"$hex"
            else
                command="raw $setSpeed$hex"
            fi
            
            output=$(eval "$start $command" 2>&1)

            if [[ $output == *"Given data"*"is invalid."* ]]; then
                ((autoMap++))
                echo "Retrying with incremented autoMap value: $autoMap"
            else
                echo "Command executed successfully."
                break
            fi
        done

        if [ $retry_count -eq $max_retries ]; then
            echo "Maximum retry attempts reached. Exiting."
        fi
        previous_cpu_temp=$cpu_temp_int

    else
        echo "Temperature difference less than hysteresis value. Skipping fan control."
    fi

    sleep 15
done