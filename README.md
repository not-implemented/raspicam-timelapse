RaspiCam-Timelapse
==================

Simple Web-App and complete HowTo for setting up a Raspberry Pi with Camera for Time-lapse Photography.

- Web-App for controlling and monitoring the camera and the Raspberry Pi
- Reverse-SSH-Tunnel to another server - reach your Raspberry Pi behind firewalls (optional)
- Dynamic-DNS-Client - find your Raspberry Pi easier in your local network (optional)
- Wi-Fi autoconnect - if you have a USB Wi-Fi Adapter (optional)
- Prerequisites: Raspberry Pi + Power + SD-Card, RaspiCam, USB Wi-Fi Adapter (optional)

![Screenshot](screenshot.jpg)


HowTo
-----

### Setup SD-Card

- Download current [Raspbian](https://www.raspberrypi.org/downloads/raspbian/)
- Write extracted ".img"-file to SD-Card - [see OS specific instructions](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)
- Attach the camera to the Raspberry Pi - [see instructions](https://www.raspberrypi.org/documentation/configuration/camera.md)
- Put the SD-Card into your Raspberry Pi, Connect to your LAN (DHCP server needed), Power on
- Login via SSH (maybe use local IP): `ssh raspberrypi` (Login: pi / Password: raspberry)
- Make complete SD-Card usable: `sudo raspi-config` - 1 Expand Filesystem - Finish - Reboot


### Setup Raspbian + Raspberry Pi Camera

- Install updates: `sudo apt-get update` and `sudo apt-get dist-upgrade`
- For some helpful optional customizations of your Raspberry Pi - [see here](Raspberry-Customizing.md)
- Enable camera: `sudo raspi-config` - 5 Enable Camera - Enable - Finish  
  (this also sets Memory Split to 128 MB)
- Disable camera LED when taking pictures (optional):  
  `sudo sh -c 'echo "disable_camera_led=1" >> /boot/config.txt'`
- Reboot for the camera settings to take effect: `sudo reboot`


### Setup RaspiCam-Timelapse

Install WebApp:

```bash
# Check out this repository:
cd ~
git clone https://github.com/not-implemented/raspicam-timelapse.git

# The WebApp needs Bootstrap and jQuery:
wget https://github.com/twbs/bootstrap/releases/download/v3.3.5/bootstrap-3.3.5-dist.zip
unzip -d raspicam-timelapse/webapp bootstrap-3.3.5-dist.zip
mv raspicam-timelapse/webapp/bootstrap-3.3.5-dist raspicam-timelapse/webapp/bootstrap
rm bootstrap-3.3.5-dist.zip

wget http://code.jquery.com/jquery-2.1.4.min.js
mkdir raspicam-timelapse/webapp/jquery
mv jquery-2.1.4.min.js raspicam-timelapse/webapp/jquery/jquery.min.js

# Prepare capture directory:
mkdir capture

# Make directories writable by Webserver (only needed if you don't run Apache as "pi" user):
chmod 777 raspicam-timelapse/config
chmod 777 capture
```

Install Webserver:

```bash
# We need Apache and PHP:
sudo apt-get install apache2 php5

# Allow access to Camera for Apache (only needed if you don't run Apache as "pi" user):
sudo usermod -a -G video www-data

# Run Apache as "pi" user to avoid permission problems:
sudo editor /etc/apache2/envvars

export APACHE_RUN_USER=pi
export APACHE_RUN_GROUP=pi

# ... and fix permissions then:
sudo chown pi /var/lock/apache2

# Create a user for HTTP-Login:
htpasswd -c .htpasswd timelapse

# Enable WebApp in Webserver:
sudo editor /etc/apache2/sites-available/default

# Please change "DocumentRoot /var/www" and "<Directory /var/www/>" to this:
DocumentRoot /home/pi/raspicam-timelapse/webapp
<Directory /home/pi/raspicam-timelapse/webapp>

# Enable HTTP-Login - put this inside "<Directory /home/pi/raspicam-timelapse/webapp>":
AuthType Basic
AuthName "RaspiCam-Timelapse"
AuthUserFile "/home/pi/.htpasswd"
Require valid-user

# Restart Apache:
sudo service apache2 restart
```

... now open your browser - i.e. with http://raspberrypi/ or IP address :-)


### Reverse SSH-Tunnel (optional)

Be sure, to change the default password before allowing connections from untrusted
networks - [see here](Raspberry-Customizing.md).

Generate key on Raspberry Pi (press ENTER everywhere):

```bash
ssh-keygen -t rsa
cat .ssh/id_rsa.pub
```

Allow SSH connections from Raspberry Pi on your remote server:

```bash
# Maybe add a user - i.e. "timelapse" on your remote server:
adduser --gecos Timelapse timelapse
chmod go-rwx /home/timelapse
cd /home/timelapse

# Add the raspberry's key (.ssh/id_rsa.pub from above) on your remote server
# to the new user and just allow port-forwarding (no login):
mkdir -p .ssh
echo "command=\"echo 'This account can only be used for port-forwarding'\",no-agent-forwarding,no-X11-forwarding" \
    "{raspberry-public-key-from-above}" >> .ssh/authorized_keys
chmod -R go-rwx .ssh
chown -R timelapse:timelapse .ssh

# Some global settings:
editor /etc/ssh/sshd_config

# Enable listening on all interfaces for port-forwarding on your remote server
# (otherwise port-forwarding will listen only on localhost):
GatewayPorts yes

# Detect and close dead connections faster and close forwarded ports to reuse them:
ClientAliveInterval 60

# Restart SSH server:
service sshd restart
```

Back on Raspberry Pi: Configure tunnels to be established - create a script with
`editor tunnels.sh` like the following example to forward port 10022 from your
remote server to port 22 on Raspberry Pi - same with port 80:

```bash
#!/bin/bash

~/raspicam-timelapse/ssh-reverse-tunnel/open-tunnel.sh timelapse@www.example.com 10022 22 &
~/raspicam-timelapse/ssh-reverse-tunnel/open-tunnel.sh timelapse@www.example.com 10080 80 &
```

```bash
# Make it executable:
chmod +x tunnels.sh

# Check SSH-Connection and permanently add the key (type "yes"):
ssh timelapse@www.example.com echo "test"

# Add script to crontab:
crontab -e

# Insert this lines into crontab:
@reboot ~/tunnels.sh
* * * * * ~/tunnels.sh
```


### Dynamic-DNS-Client (optional)

```bash
# Copy script:
sudo cp raspicam-timelapse/dynamic-dns-client/etc_ifplugd_action.d_z-dynamic-dns /etc/ifplugd/action.d/z-dynamic-dns
sudo chmod 700 /etc/ifplugd/action.d/z-dynamic-dns

# Change config vars directly in z-dynamic-dns:
sudo editor /etc/ifplugd/action.d/z-dynamic-dns
```


### Wi-Fi autoconnect (optional)

```bash
sudo editor /etc/wpa_supplicant/wpa_supplicant.conf
```

Append as many networks as you want - some examples:

```
# Secure Wi-Fi example:
network={
    ssid="{your-ssid}"
    psk="{your-key}"
}

# Open Wi-Fi example:
network={
    ssid="muenchen.freifunk.net"
    key_mgmt=NONE
}
```


TODO
----

- Implement cron-mode (and automatic recover in raspistill mode after reboot)
- Implement --hflip, --vflip
- Change umask to avoid permission problems
- Implement sync of pictures to a remote server and local cleanup
- Get Dynamic-DNS-Client more stable (trigger on IP adress changes, not just on cable plug)
