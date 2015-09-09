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

Check out this repository:

```bash
cd /home/pi
git clone https://github.com/not-implemented/raspicam-timelapse.git
```

*+++ TODO +++*


### Reverse SSH-Tunnel (optional)

*+++ TODO +++*


### Dynamic-DNS-Client (optional)

*+++ TODO +++*


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
