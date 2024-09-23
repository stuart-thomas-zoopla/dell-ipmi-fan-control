#!/bin/bash
prompt_system_type() {
    read -p "Please enter your system type, e.g., R710 (Leaving blank will allow you to provide your own min/max RPM and temperature range figures): " system_type
    system_type=$(echo "$system_type" | tr '[:upper:]' '[:lower:]') 
    echo ""
}

prompt_variable_values() {
    read -p "Please enter the minimum RPM demand value (normally between 1 and 20): " lowerrpm
    read -p "Please enter the upper RPM demand value (normally 120): " upperrpm
    read -p "Please enter the minimum normal CPU temperature (normally between 30 and 40): " mintemp
    read -p "Please enter the maximum CPU temperature (this is the temperature your want your fans at max RPM): " hightemp
    read -p "Please enter the sensor name for the fan you want to display RPM readings for (leaving this blank will use a default value known to work for R710):  " fanname
    fan_name="${fan_name:-'FAN 3 RPM'}"  # Assign default value if fan_name is blank
    echo ""
}

update_env() {
    local idrac_ip=$1
    local idrac_user=$2
    local idrac_pwd=$3
    local lowerrpm=$4
    local upperrpm=$5
    local mintemp=$6
    local hightemp=$7
    local fanname=$8
    echo "IDRAC_IP=$idrac_ip" > /dev/null
    echo "IDRAC_USER=$idrac_user" > /dev/null
    echo "IDRAC_PWD=$idrac_pwd" > /dev/null
    echo "LOWERRPM=$lowerrpm" > /dev/null
    echo "UPPERRPM=$upperrpm" > /dev/null
    echo "MINTEMP=$mintemp" > /dev/null
    echo "HIGHTEMP=$hightemp" > /dev/null
    echo "FAN_NAME=$fanname" > /dev/null
    cat <<EOF >.env
IDRAC_IP=$idrac_ip
IDRAC_USER=$idrac_user
IDRAC_PWD=$idrac_pwd
LOWERRPM=$lowerrpm
UPPERRPM=$upperrpm
MINTEMP=$mintemp
HIGHTEMP=$hightemp
FAN_NAME=$fanname
HYSTERESIS=2
EOF
    echo "Environment file (.env) updated."
}

install_packages() {
    apt update && apt upgrade -y
    apt install -y git nodejs npm net-tools lm-sensors redis-server bc
    redis-server --daemonize yes
    apt-get update && apt-get install -y ipmitool
    chmod +x /usr/bin/ipmitool 
}

setup_repository() {
    git clone https://github.com/stuart-thomas-zoopla/dell-ipmi-fan-control /var/www/html/fan
    cd /var/www/html/fan
    chmod +x /var/www/html/fan/auto.sh /var/www/html/fan/ambient_temp.sh /var/www/html/fan/rpm.sh
    npm i

    CRON_COMMANDS=(
        "@reboot (redis-server --daemonize yes && sleep 5)"
        "@reboot node /var/www/html/fan/server.js"
        "@reboot bash /var/www/html/fan/auto.sh"
    )
    for command in "${CRON_COMMANDS[@]}"; do
        (
            crontab -l 2>/dev/null || true
            echo "$command"
        ) | crontab -
    done
}

waitToReboot() {
    echo "Installation is complete. Press Enter to reboot..."
    read -r key
    if [ "$key" == "" ]; then
        echo "Rebooting now..."
        sudo reboot
    fi
}

main() {
    while true; do
        prompt_system_type

        case $system_type in
            r610|r710|r720)
                echo "System type '$system_type' is valid."
                # Use predefined values for the entered system type
                case $system_type in
                    r610)
                        lowerrpm=21
                        upperrpm=120
                        mintemp=30
                        hightemp=85
                        fanname="'FAN MOD 3A RPM'"
                        ;;
                    r710)
                        lowerrpm=1
                        upperrpm=120
                        mintemp=40
                        hightemp=85
                        fanname="'FAN 3 RPM'"

                        ;;
                    r720)
                        lowerrpm=1
                        upperrpm=120
                        mintemp=40
                        hightemp=85
                        fanname="'FAN3'"
                        ;;
                esac
                ;;
            *)
                echo "System type '$system_type' is not recognized."
                prompt_variable_values
                ;;
        esac

        echo "Please enter your IDRAC credentials. Note, these will be stored in plain text in the .env file"
        read -p "Enter IDRAC IP: " idrac_ip
        read -p "Enter IDRAC username: " idrac_user
        read -s -p "Enter IDRAC password: " idrac_pwd
        echo ""

        install_packages
        setup_repository
        update_env "$idrac_ip" "$idrac_user" "$idrac_pwd" "$lowerrpm" "$upperrpm" "$mintemp" "$hightemp" "$fanname"
        waitToReboot
    done
}

main
