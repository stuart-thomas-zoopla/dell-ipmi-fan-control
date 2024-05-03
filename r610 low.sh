#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null

lowerTempLimit=20
upperTempLimit=29
dangerTemp=30
lowerRpmLimit=21
upperRpmLimit=50

pkill -fe high.sh

autoMap=1
setManual="0x30 0x30 0x01 0x00"
setAuto="0x30 0x30 0x01 0x01"
setSpeed="0x30 0x30 0x02 0xff " 

start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

do_Setup() {
   chmod +x /usr/bin/ipmitool
   eval $start "raw 0x30 0x30 0x01 0x00"
}

get_Temp() {
   stringtemp=$(eval $start sdr type temperature | grep Ambient | grep degrees | grep -Po '\d{2}' | tail -1)
   stringtemp=${stringtemp#*|}
   echo ${stringtemp//[!0-9]/}
}

get_Sensors() {
   stringSensors=$(eval $start sdr elist full)
   echo "$stringSensors"
   }

map() {
   in=$1
   in_min=$2
   in_max=$3
   out_min=$4
   out_max=$5
   result=$(( ($in - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min ))
   echo $result
}

do_Setup

temp=$(get_Temp)
sensors=$(get_Sensors)
now=$(date)

if [ $temp -ge $dangerTemp ]; then
   eval $start "raw $setAuto"
   echo "Temps are too high, switching back to auto mode for 5 minutes"
   sleep 300
   eval $start "raw $setManual"
fi

if [ $temp -gt $lowerTempLimit ]; then
   autoMap=$(map $temp $lowerTempLimit $upperTempLimit $lowerRpmLimit $upperRpmLimit)
fi
printf "Automap value  $autoMap"
hex=$(printf '%x' "$autoMap")

if [[ "$autoMap" -le 22 ]]; then
   hex=$(printf '%x' "23")
   eval $start "raw $setSpeed"'0'"$hex"
elif [[ "$autoMap" -gt 25 && "$autoMap" -le 32 ]]; then
 hex=$(printf '%x' "32")   
   eval $start "raw $setSpeed$hex"
elif [[ "$autoMap" -gt 41 ]]; then
   hex=$(printf '%x' "50")   
   eval $start "raw $setSpeed$hex"
else
   eval $start "raw $setSpeed$hex"
fi

echo $temp