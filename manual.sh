#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null

if [ $# -eq 0 ]; then
    echo "Usage: $0 <variable>"
    exit 1
fi

pkill -fe auto.sh

autoMap="$1"
setSpeed="0x30 0x30 0x02 0xff " 
start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

eval $start "raw 0x30 0x30 0x01 0x00"

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
