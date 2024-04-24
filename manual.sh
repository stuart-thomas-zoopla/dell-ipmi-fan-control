#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null

if [ $# -eq 0 ]; then
    echo "Usage: $0 <variable>"
    exit 1
fi

pkill -fe low.sh
pkill -fe high.sh
pkill -fe auto.sh

autoMap="$1"
setSpeed="0x30 0x30 0x02 0xff " 
start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

eval $start "raw 0x30 0x30 0x01 0x00"

hex=$(printf '%x' "$autoMap")

if [[ "$autoMap" -le 7 ]]; then
   eval $start "raw $setSpeed"'0'"$hex"
elif [[ "$autoMap" -gt 7 && "$autoMap" -le 15 ]]; then
   hex=$(printf '%x' "16")   
   eval $start "raw $setSpeed$hex"
else
   eval $start "raw $setSpeed$hex"
fi