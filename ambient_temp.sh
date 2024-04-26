#!/bin/bash
source /var/www/html/fan/.env

echo "IDRAC_IP: $IDRAC_IP" > /dev/null
echo "IDRAC_USER: $IDRAC_USER" > /dev/null
echo "IDRAC_PWD: $IDRAC_PWD" > /dev/null

start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

get_Temp() {
   stringtemp=$(eval $start sdr type temperature | grep Ambient | grep degrees | grep -Po '\d{2}' | tail -1)
   stringtemp=${stringtemp#*|}
   echo ${stringtemp//[!0-9]/}
}

get_Temp
