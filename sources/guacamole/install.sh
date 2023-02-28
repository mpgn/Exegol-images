#!/bin/bash

# Set versions
GUACVERSION="1.4.0"
MCJVER="8.0.26"

# Set variables
TOMCAT="tomcat9 tomcat9-admin tomcat9-common tomcat9-user"
SERVER="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACVERSION}"
TOMCAT_HOME="/root/.tomcat"

apt-get update
export DEBIAN_FRONTEND=noninteractive

# Install dependencies
apt-get -y install build-essential libcairo2-dev libjpeg62-turbo-dev libpng-dev libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev \
libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev \
libvorbis-dev libwebp-dev libwebsockets-dev freerdp2-x11 libtool-bin ghostscript dpkg-dev wget crudini libc-bin \
${TOMCAT}

# Download requirements
wget -q --show-progress -O guacamole-server-${GUACVERSION}.tar.gz ${SERVER}/source/guacamole-server-${GUACVERSION}.tar.gz
tar -xzf guacamole-server-${GUACVERSION}.tar.gz
wget -q --show-progress -O guacamole-${GUACVERSION}.war ${SERVER}/binary/guacamole-${GUACVERSION}.war

mkdir -p /etc/guacamole/{extensions,lib}

# Install guacamole-server
cd guacamole-server-${GUACVERSION}
export CFLAGS="-Wno-error"
./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
make
make install
ldconfig

# Configure guacamole
cd ../
mv -f guacamole-${GUACVERSION}.war /etc/guacamole/guacamole.war
rm -f /etc/guacamole/guacamole.properties

# Create a new tomcat instance
tomcat9-instance-create ${TOMCAT_HOME} 
ln -sf /etc/guacamole/guacamole.war ${TOMCAT_HOME}/webapps/ROOT.war

cat >> /etc/guacamole/guacd.conf <<- "EOF"
[server]
bind_host = 0.0.0.0
bind_port = 4822
EOF

# Add login mapping
cp user-mapping.xml /etc/guacamole/

# Install xrdp + kde
apt install -y kde-plasma-desktop dbus-x11
update-alternatives --set x-session-manager /usr/bin/startplasma-x11
apt install -y xrdp

sed -i "s/EnableSyslog=1/EnableSyslog=0/g" /etc/xrdp/sesman.ini

# Edit root password
echo -e "exegol4thewin\nexegol4thewin" | passwd root

# Cleanup
rm -rf guacamole-*
rm -rf user-mapping.xml
rm -rf install.sh 

# Stop services
service guacd stop
JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-arm64 ${TOMCAT_HOME}/bin/shutdown.sh
xrdp -k
pkill xrdp-sesman

# Unset variables
unset GUACVERSION="1.4.0"
unset MCJVER="8.0.26"
unset TOMCAT
unset SERVER
unset TOMCAT_HOME