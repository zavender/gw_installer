#!/bin/bash
#
####################################################################
#
#	Description:	Uninstall script for GroundWork Monitoring
#
#	Author: 	Patrik Humeny
#
#       Email:		phumeny@lenovo.com
#
#	Version:	1.0 	
#
#	Change log:	1.0	initial version 20171022	
#		
#	Supported GW versions:	7.1.0
#				7.1.1
#	Supported OS version:	OpenSUSE 42.3
#
####################################################################
### VARIABLES

LOG=/var/log/gw_uninstall_`date +%%m%d%Y_%H%M`.log

### CODE

if [ -f /usr/local/groundwork/ctlscript.sh ]; then
	echo "Stopping GW services" | tee -a $LOG
	/usr/local/groundwork/ctlscript.sh stop | tee -a $LOG
else
	echo "Groundwork control script not found"
fi
	
if [ -f /usr/local/groundwork/uninstall ]; then
	echo "Uninstaling Groundwork" | tee -a $LOG
	/usr/local/groundwork/uninstall | tee -a $LOG
else 	
	echo "GW uninstall script not found! cleanup triggered"
fi

pkill -u nagios 2>> $LOG
pkill -u postgres 2>> $LOG
userdel -r nagios 2>> $LOG
userdel -r postgres 2>> $LOG
rm -rf /usr/local/groundwork 2>> $LOG

if [ -d /usr/local/groundwork ]; then
	echo "Groundwork uninstalation FAILED" | tee -a $LOG
        echo "Log can be checked at $LOG"
        exit 1
else
	echo "Groundwork uninstalation COMPLETE" | tee -a $LOG
	echo "Log can be checked at $LOG"
	exit 0
fi
