# Dell-IPMI/idrac6-fan-control
These scripts provide an override for the fan control on Dell PowerEdge servers that have IPMI access.  It was developed against a R710 with iDRAC 6 and is designed to be run in contrainer or VM. I personally run Proxmox and so run it inside an LXC container.

## What does it do?
Once installed, by default a script called auto.sh will run in the background. This checks CPU temperature and then picks between two other scripts, one for low demand and one for high demand (or low and high temp).  These scripts then check the ambient temperature sensor in the server and set a fan speed based on that value.  High demand will set faster fan speeds for the same ambient temperature than the low demand script does, as the CPU's are hotter.

Also included is a simple web interface that allows you to override the auto settings and set a manual value for the fan speed. Setting this to 1 sets the fans to around 1000rpm. Setting it to 120 sets the fans just over 10000rpm. Anything in between is inbetween. Within the Web interface you can also set it back to Auto, or if things have gone squiffy, reboot the container/vm you have this running in.

## Installation
From a Linux CLI run 
```
wget https://raw.githubusercontent.com/stuart-thomas-zoopla/dell-ipmi-fan-control/main/install.sh && bash install.sh
```

Then answer the prompts for IP address and login credentials for your idrac module and go make a cup of tea. When you come back it should have restarted the container/vm and the web interface will be available at <containerip>:3001 eg 192.168.0.1:3001

## Known Compatiability
This configuration has been tested on the latest idrac6 (2.92 at time of writing) on both Dell R610 and Dell R710 servers.

IMPORTANT NOTE: You need to test the various automap values (From 1 to 120) and ensure they work with your system. R610 specifically are likely to need different to default values. See R610 *.sh files

Some of the changes made to the R610 scripts may be worth porting to the R710 scripts too, but I haven't had opprtunity to look at that yet.