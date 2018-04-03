#!/bin/bash
# Prompt User for Installation

currentDir=$(
  cd $(dirname "$0")
  pwd
) 

SSPARI_PATH=$currentDir 
export SSPARI_PATH
SSPARI_BACKUP_PATH="$SSPARI_PATH/backup_files"
export SSPARI_BACKUP_PATH
touch "$SSPARI_BACKUP_PATH/files"
if [ $SUDO_USER ]; 
then 
	user=$SUDO_USER;echo 
else 
	echo "Must be run as root user!!" 
	exit 1 
fi

cd "$currentDir"
chmod -R 777 .
# Set up file-based logging
exec 1> >(tee install.log)
source functions.sh
source dependencies.sh
restore_originals
# Add Environment Variables, used for uninstallation
HOME_PROF="/home/$user/.profile"
save_original $HOME_PROF
echo "export SSPARI_PATH=$SSPARI_PATH" >> "/home/$user/.profile"
echo "export SSPARI_BACKUP_PATH=$SSPARI_PATH/backup_files" >> "/home/$user/.profile"

log "Select Your Install Options"
# Begins Logging

installlog "Install the Raspberry Pi Audio Receiver Home Installation"

Install="0"

# Home Installation - Previously Raspberry Pi Audio Receiver Install
AirPlay="y"
Bluetooth="y"
AP="n"
Kodi="n"
Lirc="n"
SoundCardInstall="y"
GMedia="n"
SNAPCAST="n"

# Prompts the User to check whether or not to use individual names for the chosen devices
# Asks for All Devices Identical Name
MYNAME=<%= @bt_name %>
APName=$MYNAME
BluetoothName=$MYNAME
AirPlayName=$MYNAME
GMediaName=$MYNAME
SNAPNAME=$MYNAME

AirPlaySecured="n"
AirPlayPass=""
<% if @airplay_pass == true %>
AirPlaySecured="y"
AirPlayPass=<%= @airplay_pass %>
<% end %>

installlog "2. HifiBerry DAC Standard/Pro"
SoundCard="SoundCard"
SoundCard=2

chmod +x ./*.sh
# Updates and Upgrades the Raspberry Pi

log "Updating via Apt-Get"
apt-get update -y
log "Upgrading via Apt-Get"
apt-get upgrade -y


# If Bluetooth is Chosen, it installs Bluetooth Dependencies and issues commands for proper configuration
export BluetoothName
run ./bt_pa_install.sh
VOL_USER=`cat /etc/os-release | grep VOLUMIO_ARCH | sed "s/VOLUMIO_ARCH=//"`
if [ "$VOL_USER" = "\"arm\"" ]
then
	export VOL_USER
	apt-get purge bluez -y
	for _dep in ${VOLUMIO_DEPS[@]}; do
			apt_install $_dep;
	done
	#exc usermod -aG "sudo" $user
	vol_groups=`groups $user | sed "s/$user : //"`
            sed -i "s/$user ALL=(ALL) ALL/$user ALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
	run su ${user} -c ./bt_pa_config.sh
	sudo usermod -G "" $user
	sed -i "s/$user ALL=(ALL) NOPASSWD: ALL/$user ALL=(ALL) ALL/" /etc/sudoers
	for _dep in ${vol_groups[@]}; do     sudo usermod -aG "$_dep" volumio; done
else
        run su ${user} -c ./bt_pa_config.sh
	#for _dep in ${vol_groups[@]}; do     usermod -aG "$_dep" $user; done

fi

export SoundCard
run ./sound_card_install.sh 

# If AirPlay is Chosen, it installs AirPlay Dependencies and issues commands for proper configuration
export SoundCard
export AirPlayPass
export AirPlayName
export AirPlay
run ./airplay_install.sh 
run ./airplay_config.sh 

log You should now reboot
