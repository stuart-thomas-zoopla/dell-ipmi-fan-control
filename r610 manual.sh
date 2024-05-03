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
   eval $start "raw $setSpeed$hex"
fi
