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
PRECK_SCRPT="lms_gw_prechecks.sh"
CONF_FILE="lms_gw_install.conf"
PKG_FILE="packages.conf"
### CODE ###

### PRECHECKS

source ${BIN_PATH}/${PRECK_SCRPT}
if [ $? != 0 ];  then
	echo [FAILED]	Prechecks failed
	exit 1
fi
	

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


### PRECHECKS

source ${BIN_PATH}/${PRECK_SCRPT}

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
