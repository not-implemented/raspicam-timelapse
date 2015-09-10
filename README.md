RaspiCam-Timelapse
==================

Simple Web-App and complete HowTo for setting up a Raspberry Pi Camera for Time-lapse Photography.

- Web-App for controlling and monitoring the camera
- Reverse-SSH-Tunnel if you have your own server - to reach your Raspberry Pi behind a firewall (optional)
- Dynamic-DNS-Client - maybe find out the IP of your Raspberry Pi in your local network easier (optional)
- Wi-Fi autoconnect (optional)
- Prerequisites: Raspberry Pi + Power + SD-Card, RaspiCam, USB Wi-Fi Adapter (optional)


HowTo
-----

### Setup SD-Card

- Download current [Raspbian](https://www.raspberrypi.org/downloads/raspbian/)
- Write extracted ".img"-file to SD-Card - [see OS specific instructions](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)
- Attach the camera to the Raspberry Pi - [see instructions](https://www.raspberrypi.org/documentation/configuration/camera.md)
- Put the SD-Card into your Raspberry Pi, Connect to your LAN (DHCP server needed), Power on
- Login via SSH (maybe use local IP): `ssh raspberrypi` (Login: pi / Password: raspberry)
- Install updates: `sudo apt-get update` and `sudo apt-get dist-upgrade`
- For some helpful optional customizations of your Raspberry Pi - [see here](Raspberry-Customizing.md)
- Make complete SD-Card usable: `sudo raspi-config` - 1 Expand Filesystem - Finish
- `reboot` (partition will be resized on reboot)


### Setup Raspberry Pi Cam

Enable camera:

- `sudo raspi-config`
- 5 Enable Camera - Enable (this also sets gpu_mem to 128 - needed by camera)
- Finish

Disable camera LED when taking pictures (optional):

```bash
sudo -i
echo "disable_camera_led=1" >> /boot/config.txt
exit
```

Reboot for the camera settings to take effect:

```bash
reboot
```


### Setup RaspiCam-Timelapse

Install WebApp:

```bash
# Check out this repository:
cd /home/pi
git clone https://github.com/not-implemented/raspicam-timelapse.git

# The WebApp needs Bootstrap and jQuery:
wget https://github.com/twbs/bootstrap/releases/download/v3.3.5/bootstrap-3.3.5-dist.zip
unzip -d raspicam-timelapse/webapp bootstrap-3.3.5-dist.zip
mv raspicam-timelapse/webapp/bootstrap-3.3.5-dist raspicam-timelapse/webapp/bootstrap

wget http://code.jquery.com/jquery-2.1.4.min.js
mkdir raspicam-timelapse/webapp/jquery
mv jquery-2.1.4.min.js raspicam-timelapse/webapp/jquery/jquery.min.js

# Prepare capture directory:
mkdir capture && chmod 777 capture
```

Install Webserver:

```bash
# We need Apache and PHP:
sudo apt-get install apache2 php5

# Allow access to Camera for Apache:
sudo usermod -a -G video www-data

# Change document-root:
sudo vi /etc/apache2/sites-available/default

# Please change "DocumentRoot" and "Directory" to this:
DocumentRoot /home/pi/raspicam-timelapse/webapp
<Directory /home/pi/raspicam-timelapse/webapp>

# Restart Apache:
sudo service apache2 restart
```

... now open your browser i.e. with http://raspberrypi/ :-)


### Reverse SSH-Tunnel (optional)

Generate key on Raspberry Pi (press ENTER everywhere):

```bash
ssh-keygen -t rsa
cat .ssh/id_rsa.pub
```

Allow SSH connections from Raspberry Pi on your remote server:

```bash
# Add a user - i.e. "timelapse" on your remote server:
adduser --gecos Timelapse timelapse
chmod go-rwx /home/timelapse
cd /home/timelapse

# Add the key on your remote server to the new user:
mkdir .ssh
echo "{raspberry-public-key-from-above}" >> .ssh/authorized_keys
chmod -R go-rwx .ssh
chown -R timelapse:timelapse .ssh

# Enable listening on all interfaces for port-forwarding on your remote server:
vi /etc/ssh/sshd_config
GatewayPorts yes
service sshd restart
```

Configure tunnels to be established - create a script with `vi tunnels.sh` like this to
forward port 10022 from your remote server to port 22 on Raspberry Pi - same with port 80:

```bash
#!/bin/bash

~/raspicam-timelapse/ssh-reverse-tunnel/open-tunnel.sh timelapse@www.example.com 10022 22 &
~/raspicam-timelapse/ssh-reverse-tunnel/open-tunnel.sh timelapse@www.example.com 10080 80 &
```

```bash
# Make it executable:
chmod +x tunnels.sh

# Add script to crontab:
crontab -e

@reboot ~/tunnels.sh
* * * * * ~/tunnels.sh
```


### Dynamic-DNS-Client (optional)

```bash
# Copy script:
sudo cp raspicam-timelapse/dynamic-dns-client/etc_ifplugd_action.d_z-dynamic-dns /etc/ifplugd/action.d/z-dynamic-dns
sudo chmod 700 /etc/ifplugd/action.d/z-dynamic-dns

# Change config vars directly in z-dynamic-dns:
sudo vi /etc/ifplugd/action.d/z-dynamic-dns
```


### Wi-Fi autoconnect (optional)

```bash
sudo vi /etc/wpa_supplicant/wpa_supplicant.conf
```

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
