#!/bin/bash
#
#####################################################################
#
#       Description:    SSL implementation for Groundwork server
#
#       Author:         Patrik Humeny
#
#       Email:          phumeny@lenovo.com
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
# 50 - Java keystore import failed
# 51 - Rollback aborted by user
# 52 - Could not stop restart of the gw services
# 53 - Config changes failed
# 54 - Backup has failed
# 55 - Revert has failed
# 56 - GW Environment variables not found
# 57 - SSL implementation FAILED
### VARIABLES
GW_SERVER=`hostname -f`
BKP_FOLDR="${PWD}/backup.`date +%m%d%Y_%H%M`"
APACHE_CONF="/usr/local/groundwork/apache2/conf/httpd.conf"
# How often check whether groundwork restart has finished
SLEEP="30"
TIME_LIMIT="300"
### CODE ###

### FUNCTIONS
# Revert changes
function F_revert {
	cp -a ${BKP_FOLDR}/httpd.conf $APACHE_CONF
		RVRT_EXTCODE="$?"
	cp -a ${BKP_FOLDR}/status-viewer.properties /usr/local/groundwork/config/status-viewer.properties
        	RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	cp -a ${BKP_FOLDR}/josso-agent-config.xml /usr/local/groundwork/config/josso-agent-config.xml
        	RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	cp -a ${BKP_FOLDR}/configuration.properties /usr/local/groundwork/config/configuration.properties
                RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	cp -a ${BKP_FOLDR}/apache2-noma.conf /usr/local/groundwork/apache2/conf/groundwork/apache2-noma.conf
                RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	cp -a ${BKP_FOLDR}/foundation-ui.conf /usr/local/groundwork/apache2/conf/groundwork/foundation-ui.conf
                RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	cp -a ${BKP_FOLDR}/server.xml /usr/local/groundwork/foundation/container/josso-1.8.4/conf/server.xml
                RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	cp -a ${BKP_FOLDR}/standalone.xml /usr/local/groundwork/foundation/container/jpp/standalone/configuration/standalone.xml
	        RVRT_EXTCODE=$[RVRT_EXTCODE+$?]
	
	if [ $RVRT_EXTCODE -eq "0" ]; then
		echo "Revert finished SUCCESSFULLY"
	else 
		echo "Revert has FAILED"
		exit 55
	fi
}

# Create backup folder if does not exist
if [ ! -d $BKP_FOLDR ]; then
	mkdir -p $BKP_FOLDR
	echo "Backup dir created $BKP_FOLDR"
fi

### IMPLEMENTATION 

# load environment variables

if [ -f /usr/local/groundwork/scripts/setenv.sh ]; then
	source /usr/local/groundwork/scripts/setenv.sh
else
	echo "File /usr/local/groundwork/scripts/setenv.sh not found"
	echo "Groundwork is not installed"
	exit 56
fi

### Generate SSL certs ###

cd /usr/local/groundwork/common/openssl/certs
echo "Folder changed to:" `pwd`

openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.pem -days 3653 -sha256 -set_serial `date +%s` -subj "/C=/ST=/L=/O=/OU=/CN=$GW_SERVER/emailAddress=/"

c_rehash
openssl verify /usr/local/groundwork/common/openssl/certs/*.pem

### Replace apache certificates
rm /usr/local/groundwork/apache2/conf/server.crt
rm /usr/local/groundwork/apache2/conf/server.key

ln -s /usr/local/groundwork/common/openssl/certs/server.pem /usr/local/groundwork/apache2/conf/server.crt
ln -s /usr/local/groundwork/common/openssl/certs/server.key /usr/local/groundwork/apache2/conf/server.key

cd - > /dev/null 2>&1
echo "Folder changed to:" `pwd`

### BACKUP config files

# Apache
mkdir -p $BKP_FOLDR
	BKP_EXTCODE="$?"
cp -a $APACHE_CONF $BKP_FOLDR
	BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/config/status-viewer.properties $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/foundation/container/jpp/modules/org/josso/generic-ee/agent/main/josso-agent-config.xml $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/foundation/container/jpp/standalone/configuration/gatein/configuration.properties $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/apache2/conf/groundwork/apache2-noma.conf $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/apache2/conf/groundwork/foundation-ui.conf $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/foundation/container/josso-1.8.4/conf/server.xml $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]
cp -a /usr/local/groundwork/foundation/container/jpp/standalone/configuration/standalone.xml $BKP_FOLDR
        BKP_EXTCODE=$[$BKP_EXTCODE+$?]

if [ $BKP_EXTCODE -eq "0" ]; then
        echo "Backup has been done SUCCESSFULLY"
else
        echo "Backup has FAILED"
        exit 54
fi

### MODIFY config files
# Apache
ROW_NUM=`grep -n "rewrite_module" $APACHE_CONF | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/LoadModule rewrite_module modules\/mod_rewrite.so/" $APACHE_CONF
	IMPL_EXTCODE="$?"
ROW_NUM=`grep -n "conf/extra/httpd-ssl.conf" $APACHE_CONF | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/Include conf\/extra\/httpd-ssl.conf/" $APACHE_CONF
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
ROW_NUM=`grep -n "RewriteEngine" $APACHE_CONF | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/RewriteEngine On/" $APACHE_CONF
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
ROW_NUM=`grep -n "RewriteCond" $APACHE_CONF | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/RewriteCond %{SERVER_PORT} \!^443\$/" $APACHE_CONF
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
ROW_NUM=`grep -n "RewriteRule" $APACHE_CONF | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/RewriteRule ^\/(\.\*)\$ https:\/\/$GW_SERVER\/\$1 [NE]/" $APACHE_CONF
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
# GW configs
sed -i 's/secure.access.enabled=false/secure.access.enabled=true/' /usr/local/groundwork/config/status-viewer.properties
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
sed -i "s/http:\/\/$GW_SERVER/https:\/\/$GW_SERVER/g" /usr/local/groundwork/config/josso-agent-config.xml
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
sed -i "s/http:\/\/$GW_SERVER/https:\/\/$GW_SERVER/" /usr/local/groundwork/config/configuration.properties
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
ROW_NUM=`grep -n "gatein.sso.josso.base.url=http" /usr/local/groundwork/config/configuration.properties | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/http/https/" /usr/local/groundwork/config/configuration.properties
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
sed -i "s/http:\/\/$GW_SERVER/https:\/\/$GW_SERVER/g" /usr/local/groundwork/apache2/conf/groundwork/apache2-noma.conf
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]
sed -i "s/http:\/\/$GW_SERVER/https:\/\/$GW_SERVER/g" /usr/local/groundwork/apache2/conf/groundwork/foundation-ui.conf
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]

ROW_NUM=`grep -n 'Connector connectionTimeout="20000" port="8888" protocol="HTTP/1.1"' /usr/local/groundwork/foundation/container/josso-1.8.4/conf/server.xml | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/\<Connector connectionTimeout=\"20000\" port=\"8888\" protocol=\"HTTP\/1.1\" scheme=\"https\" proxy-name=\"$GW_SERVER\" proxy-port=\"443\" redirectPort=\"8443\"\/\>/" /usr/local/groundwork/foundation/container/josso-1.8.4/conf/server.xml
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]

ROW_NUM=`grep -n 'connector name="http" protocol="HTTP/1.1" scheme="http" socket-binding="http"' /usr/local/groundwork/foundation/container/jpp/standalone/configuration/standalone.xml | awk -F":" {'print $1'}`
sed -i "${ROW_NUM}s/.*/\<connector name=\"http\" protocol=\"HTTP\/1.1\" scheme=\"https\" socket-binding=\"http\" proxy-name=\"$GW_SERVER\" proxy-port=\"443\" secure=\"true\"\/\>/" /usr/local/groundwork/foundation/container/jpp/standalone/configuration/standalone.xml
        IMPL_EXTCODE=$[IMPL_EXTCODE+$?]


if [ $IMPL_EXTCODE -eq "0" ]; then
        echo "Configs modified SUCCESSFULLY"
else
        read -p "Config changes FAILED. Revert changes ? [Y/N] " RVRT_ANSR
               if [ "$RVRT_ANSR" == "Y" ]; then
                        echo "Revert from BACKUP started"
                        F_revert
                        echo "Please try to start GW manually"
                        exit 53
               else
                        echo "Revert of the changes has been aborted"
                        exit 51
               fi
fi

# Java Keystore import

echo -e '\n In next step you are going to need a password "changeit" and then you will have to write yes \n'
echo "Press Any Key To Continue"; read -n 1

keytool -import -file /usr/local/groundwork/apache2/conf/server.crt -alias $GW_SERVER -keystore /usr/local/groundwork/java/jre/lib/security/cacerts

if [ "$?" -eq "1" ]; then
	read -p "Java KeyStore import FAILED. Revert changes ? [Y/N] " RVRT_ANSR
        	if [ "$RVRT_ANSR" == "Y" ]; then
        		echo "Revert from BACKUP started"
                	F_revert
                        echo "Please try to start GW manually"
                        exit 50
               else
                        echo "Revert of the changes has been aborted"
                        exit 51
		fi
fi

# Restart all GW services
echo "Restarting GW services in order to apply changes"

/usr/local/groundwork/ctlscript.sh restart &
sleep 1
TIMER=0
while ps -ef | grep "/usr/local/groundwork/ctlscript.sh restart"| grep -v grep > /dev/null 2>&1; do
        echo "--------------------------------------------------------------------------------------------"
        echo -e "\n"
        echo "  Groundwork restart has been running for $TIMER seconds and will be aborted after $TIME_LIMIT seconds"
        echo -e "\n"
        echo "--------------------------------------------------------------------------------------------"
        sleep $SLEEP
        TIMER=$[TIMER+SLEEP]
        if [ "$TIMER" -gt "$TIME_LIMIT" ]; then
                echo "Restart of the GW services has reached time limit and will be aborted"
                pkill -f "/usr/local/groundwork/"
                if [ $? == 0 ]; then
                        echo "Restart of the GW services has been aborted"
                        read -p "SSL implemementation FAILED. Revert changes ? [Y/N] " RVRT_ANSR
                                if [ "$RVRT_ANSR" == "Y" ]; then
                                        F_revert
					echo "Please try to start GW manually"
					exit 57
                                else
                                        echo "Revert of the changes has been aborted"
                                        exit 51
                                fi
                else
                        echo "Could not stop restart of the services script will exit!"
                        exit 52
                fi
        fi
done

echo "GW services has been succesfully restarted"

echo "SSL has been implemented! Please test: "https://$GW_SERVER""

exit 0

