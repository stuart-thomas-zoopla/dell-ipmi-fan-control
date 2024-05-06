#!/bin/bash

prompt_system_type() {
    read -p "Please enter your system type, e.g., R710 (Leaving blank will allow you to provide your own min/max RPM and temperature range figures): " system_type
    system_type=$(echo "$system_type" | tr '[:upper:]' '[:lower:]')  # Convert input to lowercase
    echo ""
}

prompt_variable_values() {
    read -p "Please enter the minimum RPM demand value (normally between 1 and 20): " lowerrpm
    read -p "Please enter the upper RPM demand value (normally 120): " upperrpm
    read -p "Please enter the minimum normal CPU temperature (normally between 30 and 40): " mintemp
    read -p "Please enter the maximum CPU temperature (this si the temperature your want your fans at max RPM): " hightemp
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
    cat <<EOF >.env
IDRAC_IP=$idrac_ip
IDRAC_USER=$idrac_user
IDRAC_PWD=$idrac_pwd
LOWERRPM=$lowerrpm
UPPERRPM=$upperrpm
MINTEMP=$mintemp
HIGHTEMP=$hightemp
EOF
    echo "Environment file (.env) updated."
}

install_packages() {
    apt update && apt upgrade -y
    apt install -y git nodejs npm net-tools lm-sensors redis-server bc
    redis-server --daemonize yes
    apt-get update && apt-get install -y ipmitool
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
                        echo "$predefined_values_R610"
                        ;;
                    r710)
                        echo "$predefined_values_R710"
                        ;;
                    r720)
                        echo "$predefined_values_R720"
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

        update_env "$idrac_ip" "$idrac_user" "$idrac_pwd" "$lowerrpm" "$upperrpm" "$mintemp" "$hightemp"
        install_packages
        setup_repository
        waitToReboot
    done
}

main