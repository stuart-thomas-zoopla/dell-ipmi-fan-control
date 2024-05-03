#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null

lowerTempLimit=20
upperTempLimit=25
dangerTemp=26
lowerRpmLimit=50
upperRpmLimit=120

pkill -fe low.sh

automap=53
autoMap=55
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
   automap=$(map $temp $lowerTempLimit $upperTempLimit $lowerRpmLimit $upperRpmLimit)
   autoMap=$(round_to_nearest $automap)
fi
printf "Automap value  $autoMap"

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

eval $start "raw $setSpeed$hex"