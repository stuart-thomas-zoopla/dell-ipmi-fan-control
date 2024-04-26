#!/bin/bash

source /var/www/html/fan/.env

start="ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_USER -P $IDRAC_PWD"

get_Temp() {
   stringtemp=$(eval $start sdr type temperature | grep Ambient | grep degrees | grep -Po '\d{2}' | tail -1)
   stringtemp=${stringtemp#*|}
   echo ${stringtemp//[!0-9]/}
}

get_Temp
