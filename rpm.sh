#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null
echo "FAN_NAME: $FAN_NAME" > /dev/null

start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

get_Rpm() {
   stringRpm=$($start sdr type fan | grep -B1 "$FAN_NAME" | grep -oE '[0-9]+ RPM' | awk '{print $1}' | tail -n 1)
   echo ${stringRpm}
}

get_Rpm
