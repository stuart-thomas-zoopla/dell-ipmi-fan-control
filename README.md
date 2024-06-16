# Dell-IPMI/idrac6-fan-control
These scripts provide an override for the fan control on Dell PowerEdge servers that have IPMI access.  It has been developed and tested against an R710 and an R610 with iDRAC 6, and an R720 with idrac7. It is designed to be run in a container or VM. I personally run Proxmox and so run it inside an LXC container.

## What does it do?
Once installed, by default a script called auto.sh will run in the background. This checks CPU temperature and set a fan speed based on that value.

Also included is a simple web interface that allows you to override the auto settings and set a manual value for the fan speed. The effect of the values in this setting vary slightly based on the system you are running against. Setting this to 1 on a R710 sets the fans to around 1000rpm, where as on an R610 you should not set below 20 otherwise you get low RPM warnings and the fans can stop altogether. On the other hand 120 seems to be a safe universal maximum speed, with the actual fan speed being between 10,000 (R710) and 14,000 rpm (R610), again depending on system. Anything in between is inbetween. Within the Web interface you can also set it back to Auto, or if things have gone squiffy, reboot the container/vm you have this running in.

## Installation
From a Linux CLI run 
```
wget https://raw.githubusercontent.com/stuart-thomas-zoopla/dell-ipmi-fan-control/main/install.sh && bash install.sh
```

You will recieve a couple of prompts to provide values.

#### System Type
Currently supported are R610, R710, and R720. Othe systems, including non-Dell systems that support IPMI will likely work. To test with those system leave the system type blank and you will prompted you to provide your own values instead of using the defaults.

#### Fan speed and Temperature values
If you don't enter a recognised system type, or leave it blank, you will be prompted to provide values for:

Minimum RPM demand value: This is normally between 1 and 20, depending on the system.
Upper RPM demand value: This can normally be safely set to 120.
Minimum normal CPU temperature: This is the CPU temperature at which your fans will spin at the Minimum RPM demand value.
Maximum CPU temperature: This is the CPU temperature at which your fans will spin at max RPM.
Sensor name for fan RPM readings: This is used to get the RPM reading. Leaving it blank will use a value known to work on an R710.

#### iDRAC credentials
You will then be asked to provide your iDRAC credentials, includind the IP address, username and password for your iDRAC module.

After that the install will run and prompt you to restart.Once the container/vm has restarted the web interface will be available at `containerip`:3001 eg 192.168.0.1:3001

## Known Compatiability
This configuration has been tested on the latest idrac6 (2.92 at time of writing) on both Dell R610 and Dell R710 servers, as well as idrac7 on a Dell R720.

# Use at your own risk. I will take no responsibility for you damaging your hardware by using this script.
