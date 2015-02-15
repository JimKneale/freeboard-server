#!/bin/bash
#
# Copyright 2012,2013 Robert Huitema robert@42.co.nz
# 
# This file is part of FreeBoard.
#
#  FreeBoard is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  FreeBoard is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with FreeBoard.  If not, see <http://www.gnu.org/licenses/>.
#
# Script to setup and install freeboard to the raspberry pi
#
# What this tries to do :
# In /home/pi
# Get out a copy of freeboard-server-0.5.10-SNAPSHOT-all.zip
# unzip it, it will create freeboard-server-0.5.10-SNAPSHOT-all dir - thats wrong
# Move the contents of freeboard-server-0.5.10-SNAPSHOT-all back into home/pi, so now there is a /home/pi/freeboard/
# cd freeboard - dont run install if it was already done.
# Install java-8-oracle, and update start.sh to use this.
# Setup wifi and networking ready for the boat.

# Now you can run ./start.sh,  go to http://???:8080/freeboard to see.
#
# logs will be in /home/pi/freeboard/logs/start.log - send that if its still not up
# 
# Modify the system account files to add user pi as a member of the following groups
# Note that this will remove the pi user from any groups that are not listed
#   adm,dialout,cdrom,floppy,audio,dip,video, and admin
cd /home/pi
sudo usermod -G adm,dialout,cdrom,floppy,audio,dip,video,admin pi

####################
read -p "Do you want to check for updates? [Y/N/Abort]" -n 1 -r
####################
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
   sudo apt-get update
   sudo apt-get upgrade
fi
if [[ $REPLY =~ ^[Aa]$ ]]
then
   exit 1
fi


####################
read -p "Do you want to install zip, unzip, and dnsmasq? [Y/N/Abort]" -n 1 -r
####################
#  zip - package and compress (archive) files 
#  unzip - list, test and extract compressed files in a ZIP archive
#  dnsmasq - A lightweight DHCP and caching DNS server (Manages IP addresses)
if [[ $REPLY =~ ^[Yy]$ ]]
then
   sudo apt-get install zip unzip dnsmasq
fi
if [[ $REPLY =~ ^[Aa]$ ]]
then
   exit 1
fi
####################
read -p "Do you want to install wpasupplicant, usbutils, wireless-tools, iw, and hostapd? [Y/N/Abort]" -n 1 -r
####################
# See http://cberner.com/2013/02/03/using-hostapd-on-ubuntu-to-create-a-wifi-access-point/
#  wpasupplicant - implements key negotiation with a IEEE 802.11 WPA Authenticator 
#  usbutils - load the following tools:
#     usb-devices is a (bash) shell script that can be used to display details of USB buses in the system and the devices connected to them
#     lsusb is a utility for displaying information about USB buses in the system and the devices connected to them.
#     update-usbids to download new version of the USB ID list
#  wireless-tools - load the following tools:
#     iwconfig to manipulate the basic wireless parameters
#     iwlist to initiate scanning and list frequencies, bit-rates, encryption keys...
#     iwspy to get per node link quality
#     iwpriv to manipulate the Wireless Extensions specific to a driver (private)
#     ifrename to name interfaces based on various static criteria
#  iw - show / manipulate wireless devices and their configuration
#  hostapd - creates a wireless access point
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
   sudo apt-get install wpasupplicant usbutils wireless-tools iw hostapd
fi
if [[ $REPLY =~ ^[Aa]$ ]]
then
   exit 1
fi


####################
read -p "Do you want to install oracle-java8-jdk? [Y/N/Abort]" -n 1 -r
####################
# if you have problems see http://www.raspberrypi.org/forums/viewtopic.php?f=81&t=59036&p=442375&hilit=oracle+jdk#p442375
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then
   echo Java will install in the /usr/lib/jvm directory
   sudo apt-get install oracle-java8-jdk
   #Run the selection option to be sure you are using this version.
   sudo update-alternatives --install /usr/bin/javac javac /opt/jdk1.8.0/bin/javac 1
   sudo update-alternatives --install /usr/bin/java java /opt/jdk1.8.0/bin/java 1
fi
if [[ $REPLY =~ ^[Aa]$ ]]
then
   exit 1
fi


####################  Not used in 5.10 - Delete this when certain that it isn't needed
#read -p "Do you want to install gdal-bin, python-gdal, and imagemagick? [Y/N/Abort]" -n 1 -r
####################
# gdal-bin - Geospatial Data Abstraction Library: a set of tools for working with raster and vector geographic data.
# python-gdal - GDAL’s Python interfaces for raster manipulation
# imagemagick - software suite which can be used to create, edit and display bitmap images
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
#   sudo apt-get install gdal-bin python-gdal imagemagick
fi
if [[ $REPLY =~ ^[Aa]$ ]]
then
#   exit 1
fi

####################
read -p "Do you want to extract the freeboard-server archive? [Y/N/Abort]" -n 1 -r
####################
# prior to this, you need to have copied the file over per the freeboard install notes
FREEBOARD_CURRENT=freeboard-server-0.5.10-SNAPSHOT
unzip $FREEBOARD_CURRENT-all.zip

#copy the freeboard directory back to here
cp -rf $FREEBOARD_CURRENT/freeboard .
#we need the logs directory
mkdir freeboard/logs

###################
#Install autostart
#copy and rename the file to /etc/init.d - you must do this as root hence 'sudo'
sudo cp -rf ./freeboard/freeboard.init.d.sh /etc/init.d/freeboard
# change owner and permissions
sudo chmod 755 /etc/init.d/freeboard
sudo chown root:root /etc/init.d/freeboard
# add to startup process
sudo update-rc.d freeboard defaults

# stop the apache server, its in the way
sudo update-rc.d -f apache2 remove
sudo update-rc.d -f udhcpd remove

##################
#Optional: if you are having problems exit here
#Setup networking
#/etc/network/interfaces
if ! grep -Fq "#Run as wireless access point" /etc/network/interfaces 
then
    sudo echo "" >> /etc/network/interfaces
    sudo echo "#Run as wireless access point" >> /etc/network/interfaces
    sudo echo "auto wlan0" >> /etc/network/interfaces
    sudo echo "iface wlan0 inet static" >> /etc/network/interfaces
    sudo echo "    address 192.168.0.1" >> /etc/network/interfaces
    sudo echo "    netmask 255.255.255.0" >> /etc/network/interfaces
    sudo echo "    gateway 192.168.0.1" >> /etc/network/interfaces
fi
#/etc/hostname
sudo echo "freeboard" > /etc/hostname

#/etc/hosts
sudo echo "# www.zkoss.org is in here to speed the web interface when there is no internet connection" > /etc/hosts
sudo echo "127.0.0.1       localhost www.zkoss.org" >> /etc/hosts
sudo echo "# Note: the a.freeboard, b.freeboard, etc entries are used by the Leaflet mapping lib to speed up map loading, you only need them if you are using the chartplotter." >> /etc/hosts
sudo echo "192.168.0.1	freeboard a.freeboard b.freeboard c.freeboard d.freeboard" >> /etc/hosts

#dnsmasq
# Configuration file for dnsmasq.
sudo echo "interface=wlan0" > /etc/dnsmasq.conf
sudo echo "dhcp-range=192.168.0.10,192.168.0.128,12h" >> /etc/dnsmasq.conf
sudo echo "" >> /etc/dnsmasq.conf
sudo echo "#usb interface " >> /etc/dnsmasq.conf
sudo echo "interface  usb0" >> /etc/dnsmasq.conf
sudo echo "dhcp-range=192.168.7.1,192.168.7.1,12h" >> /etc/dnsmasq.conf



##################
#set up wifi

sudo mkdir /etc/hostapd
sudo mv /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak

# write hostapd.conf
sudo echo "interface=wlan0" > /etc/hostapd/hostapd.conf
sudo echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
sudo echo "ctrl_interface=/var/run/hostapd" >> /etc/hostapd/hostapd.conf
sudo echo "ctrl_interface_group=0" >> /etc/hostapd/hostapd.conf
sudo echo "#use YOUR boatname here!" >> /etc/hostapd/hostapd.conf
sudo echo "ssid=freeboard" >> /etc/hostapd/hostapd.conf
sudo echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
sudo echo "channel=10" >> /etc/hostapd/hostapd.conf
sudo echo "wpa=1" >> /etc/hostapd/hostapd.conf
sudo echo "#use your passphrase here!" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_passphrase=freeboard" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
sudo echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
sudo echo "beacon_int=100" >> /etc/hostapd/hostapd.conf
sudo echo "auth_algs=3" >> /etc/hostapd/hostapd.conf
sudo echo "wmm_enabled=1" >> /etc/hostapd/hostapd.conf

#/etc/default/hostapd
sudo echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" > /etc/default/hostapd