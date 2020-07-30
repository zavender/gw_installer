#!/bin/bash
#
#####################################################################
#
#       Description:    Install script for GroundWork Monitoring
#
#       Author:         Patrik Humeny
#
#		Email:		phumeny@lenovo.com
#
#       Version:        1.0
#
#       Change log:     1.0     initial version 20171022
#
#       Supported GW versions:  7.1.0
#                               7.1.1
#       Supported OS version:   OpenSUSE 42.3
#
####################################################################
### Exit codes
#
## PRECHECKS Exit codes
# 20 - gw instalation package not found
# 21 - package permission could not been changed
# 22 - configuration file not found
# 23 - previous gw uninstalation was cancelled by user
# 24 - gw uninstall failed check uninstall log
# 30 - Instalation aborted by user
#
### VARIABLES
HOSTNAME=`hostname -f`
PWD=`pwd`
CONF_PATH="${PWD}/conf"
BIN_PATH="${PWD}/scripts"
LOG_PATH="${PWD}/log"
PKG_PATH="${PWD}/packages"
UNIN_SCRPT="lms_gw_uninstall.sh"
SSL_SCRPT="lms_gw_ssl.sh"
CONF_FILE="lms_gw_install.conf"
PKG_FILE="packages.conf"
### CODE ###

### PRECHECKS
# Checking for supported package
PKG_NAME=`ls -1 $PKG_PATH | grep -wf ${CONF_PATH}/${PKG_FILE} | grep -v "#" | tail -1`
PKG_VER=`echo $PKG_NAME | awk -F"-" {'print $2"-"$3"-"$4"-"$5$6'}`
if [ ! -z $PKG_NAME ]; then
	echo "Package version $PKG_VER found"
	echo "[OK]	Supported package found"
else
	echo "[FAILED]	Supported Package found"
	echo "NO supported package found at path $PKG_PATH"
	exit 20
fi

# Checking execute permissions for $PKG_NAME
if [ ! -x ${PKG_PATH}/${PKG_NAME} ]; then
        echo "Package $PKG_NAME cannot be executed"
        echo "Current permissions"
        ls -l ${PKG_PATH}/${PKG_NAME}
        echo "Changing permissions"
        chmod u+x  ${PKG_PATH}/${PKG_NAME}
        ls -l ${PKG_PATH}/${PKG_NAME}
fi
if [ ! -x ${PKG_PATH}/${PKG_NAME} ]; then
                echo "[FAILED]	Execute permission"
                exit 21
else
        echo "[OK]	Execute permissions"
fi

# Looking for configuration file
if [ ! -f ${CONF_PATH}/$CONF_FILE ];then
	echo "[FAILED]	Config file found"
        echo "$CONF_FILE NOT FOUND! at path $CONF_PATH"
        exit 22
fi
echo "[OK]	Config file found"

# Check whether hostname -f is pingable
ping -c 1 $HOSTNAME
if [ $? = 0 ]; then	
	echo [OK] server $HOSTNAME is pingable!
else	
	echo "Please add primary IP and HOSTNAME into /etc/hosts"
	exit  25
fi

#FINAL STATUS
echo [OK]	ALL prechecks succesfully completed
exit 0
