function update_env() {
    local idrac_ip=$1
    local idrac_user=$2
    local idrac_pwd=$3
    cat <<EOF >.env
IDRAC_IP=$idrac_ip
IDRAC_USER=$idrac_user
IDRAC_PWD=$idrac_pwd
EOF
    echo "Environment file (.env) updated."
}

waitForEnter() {
    echo "Intallation is complete. Press Enter to reboot..."
    read -r key
    if [ "$key" == "" ]; then
        echo "Rebooting now..."
        sudo reboot
    fi
}

echo "Please enter your IDRAC credentials. Note, these will be stored in plain text in the .env file"
read -p "Enter IDRAC IP: " idrac_ip
read -p "Enter IDRAC username: " idrac_user
read -s -p "Enter IDRAC password: " idrac_pwd
echo ""

apt update && apt upgrade -y
apt install -y git nodejs npm net-tools lm-sensors redis-server bc
redis-server --daemonize yes
apt-get update && apt-get install -y ipmitool
git clone https://github.com/stuart-thomas-zoopla/dell-ipmi-fan-control /var/www/html/fan
cd /var/www/html/fan
chmod +x /var/www/html/fan/low.sh /var/www/html/fan/high.sh /var/www/html/fan/auto.sh /var/www/html/fan/ambient_temp.sh /var/www/html/fan/rpm.sh
update_env "$idrac_ip" "$idrac_user" "$idrac_pwd"
npm i
host=ifconfig | sed -n 's/.*inet ([0-9.] ).*/1/p' | head -n1

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

waitForEnter