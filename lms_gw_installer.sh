#!/bin/bash
#
#####################################################################
#
#       Description:    Install script for GroundWork Monitoring
#
#       Author:         Patrik Humeny
#
#	Email:		phumeny@lenovo.com
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
## SSL Exit codes
# 50 - Java keystore import failed
# 51 - Rollback aborted by user
# 52 - Could not stop restart of the gw services
# 53 - Config changes failed
# 54 - Backup has failed
# 55 - Revert has failed
# 56 - GW Environment variables not found
# 57 - SSL implementation FAILED
#
### VARIABLES 
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
	echo "Supported package found:	OK"
else
	echo "Supported Package found:	FAILED"
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
                echo "Execute permission:       	FAILED"
                exit 21
else
        echo "Execute permissions:       	OK"
fi

# Looking for configuration file
if [ ! -f ${CONF_PATH}/$CONF_FILE ];then
	echo "Config file found:		FAILED"
        echo "$CONF_FILE NOT FOUND! at path $CONF_PATH"
        exit 22
fi
echo "Config file found:         	OK"

# Check whether GW is already installed
if [ -d /usr/local/groundwork ]; then
        echo "Previous Groundwork instalation found"
        read -p "Do you want to remove it ? [Y/N] " UNIN_ANSR
        if [ "$UNIN_ANSR" == "Y" ]; then
                read -p "Are you sure? This action will remove everything under /usr/local/groundwork [Y/N] " UNIN_ANSR2
                if [ "$UNIN_ANSR2" == "Y" ]; then
                        echo "Removing previous GW instalation"
                        /bin/bash ${BIN_PATH}/${UNIN_SCRPT}
                fi
        else
                echo "Instalation cannot continue"
                exit 23
        fi
        if [ -d /usr/local/groundwork ]; then
                echo "GW uninstall:     FAILED"
                exit 24
        else
                echo "GW uninstall:     OK"
        fi
fi

# check na dns a hostname ci je v hosts file

echo "All prechecks:            OK"

### INSTALATION
echo "Your are about to install Groundwork Enterprise Monitoring version $PKG_VER"

read -p "Do you want to start instalation ? [Y/N] " INST_ANSR
echo $INST_ANSR
if [ "$INST_ANSR" == "Y" ]; then
        echo "Instalation has began..."
        ${PKG_PATH}/${PKG_NAME} --mode unattended --optionfile ${CONF_PATH}/${CONF_FILE}
        echo "Exit code from package is: $?"
else
        echo "Instalation aborted"
        exit 30
fi

### POST INSTALL CHECKS
# test if portal is working
#echo "Testing Groundwork Portal"

read -p "Do you want to implement SSL ? [Y/N] " SSL_ANSR
	if [ "$SSL_ANSR" == "Y" ]; then
        	echo "SSL implementation started"
		source ${BIN_PATH}/${SSL_SCRPT} `hostname`
	else
		echo "SSL implementation skipped"
	fi
exit 0
