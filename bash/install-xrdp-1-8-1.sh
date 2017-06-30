################################################################
# Script_Name : install-xrdp-1.8-1.sh
# Description : Perform an automated custom installation of xrdp
# on ubuntu 16.04.2
# Date : June 30th 2017
# written by : Griffon (modified by igordcard)
# Web Site :http://www.c-nergy.be - http://www.c-nergy.be/blog
# Version : 1.8.1
#
# Disclaimer : Script provided AS IS. Use it at your own risk....
#
##################################################################
 
##################################################################
#Step 1 - Install prereqs for compilation
##################################################################
 
echo "Installing prereqs for compiling xrdp..."
echo "----------------------------------------"
sudo apt-get -y install libx11-dev libxfixes-dev libssl-dev libpam0g-dev libtool libjpeg-dev flex bison gettext autoconf libxml-parser-perl libfuse-dev xsltproc libxrandr-dev python-libxml2 nasm xserver-xorg-dev fuse git pkg-config

# extra, non-related to compilation, make sure xserver-xorg is installed:
sudo apt-get -y install xserver-xorg

# extra, non-related to compilation, install a desktop environment:
#sudo apt-get -y install ubuntu-desktop
#sudo apt-get -y install mate

##################################################################
#Step 2 - Obtain xrdp packages 
################################################################## 

 
## -- Download the xrdp latest files
echo "Ready to start the download of xrdp package"
echo "-------------------------------------------"
git clone https://github.com/neutrinolabs/xrdp.git

## -- compiling xrdp packages

echo "Installing and compiling xrdp..."
echo "--------------------------------"
cd xrdp
git checkout v0.9
./bootstrap
./configure --enable-fuse --enable-jpeg  
make
sudo make install

##################################################################
#Step 3 -  Download and compiling xorgxrdp packages
################################################################## 
cd ..
git clone https://github.com/neutrinolabs/xorgxrdp.git


cd xorgxrdp 
./bootstrap 
./configure 
make
sudo make install


##################################################################
#Step 4 - Modify Service Unit Files
################################################################## 


## Needed in order to have systemd working properly with xrdp
echo "-----------------------"
echo "Modify xrdp.service "
echo "-----------------------"

#Comment the EnvironmentFile - Ubuntu does not have sysconfig folder
sudo sed -i.bak 's/EnvironmentFile/#EnvironmentFile/g' /lib/systemd/system/xrdp.service
#Replace /usr/sbin/xrdp with /usr/local/sbin/xrdp as this is the correct location
sudo sed -i.bak 's/usr\/sbin\/xrdp/usr\/local\/sbin\/xrdp/g' /lib/systemd/system/xrdp.service
echo "-----------------------"
echo "Modify xrdp-sesman.service "
echo "-----------------------"

#Comment the EnvironmentFile - Ubuntu does not have sysconfig folder
sudo sed -i.bak 's/EnvironmentFile/#EnvironmentFile/g' /lib/systemd/system/xrdp-sesman.service
#Replace /usr/sbin/xrdp with /usr/local/sbin/xrdp-sesman as this is the correct location
sudo sed -i.bak 's/usr\/sbin\/xrdp/usr\/local\/sbin\/xrdp/g' /lib/systemd/system/xrdp-sesman.service

#Issue systemctl command to reflect change and enable the service
sudo systemctl daemon-reload
sudo systemctl enable xrdp.service
sudo systemctl enable xrdp-sesman.service
## copy the following in the .xsession file 

cat >~/.xsession << EOF

/usr/lib/gnome-session/gnome-session-binary --session=ubuntu &
/usr/lib/x86_64-linux-gnu/unity/unity-panel-service &
/usr/lib/unity-settings-daemon/unity-settings-daemon &

for indicator in /usr/lib/x86_64-linux-gnu/indicator-*; 
do
basename='basename \${indicator}' 
dirname='dirname \${indicator}' 
service=\${dirname}/\${basename}/\${basename}-service 
\${service} &
done
unity
EOF

## Configure Polkit to avoid popu in Xrdp Session

cat >/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf  <<EOF

polkit.addRule(function(action, subject) {
if ((action.id == “org.freedesktop.color-manager.create-device” ||
action.id == “org.freedesktop.color-manager.create-profile” ||
action.id == “org.freedesktop.color-manager.delete-device” ||
action.id == “org.freedesktop.color-manager.delete-profile” ||
action.id == “org.freedesktop.color-manager.modify-device” ||
action.id == “org.freedesktop.color-manager.modify-profile”) &&
subject.isInGroup(“{group}”)) {
return polkit.Result.YES;
}
});
EOF

 
echo "Restart the Computer"
echo "----------------------------"
#sudo shutdown -r now 
