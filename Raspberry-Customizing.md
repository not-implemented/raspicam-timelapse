Raspberry Pi Customizing
========================

Theese customizations are optional and not directly related to RaspiCam-Timelapse,
but maybe helpful for you - just use your favourite settings here.

Change Password
---------------
- `sudo raspi-config`
- 2 Change User Password - ...
- Finish

Change Hostname
---------------
- `sudo raspi-config`
- 8 Advanced Options - A2 Hostname - (i.e. "timelapse")
- Finish

Change Locale
-------------
- `sudo raspi-config`
- 4 Internationalisation Options - I1 Change Locale - (i.e. "de_DE.UTF-8")
- 4 Internationalisation Options - I2 Change Timezone - (i.e. "Europe/Berlin")
- 4 Internationalisation Options - I3 Change Keyboard Layout
- Finish

Install vim
-----------
```bash
sudo apt-get install vim
sudo update-alternatives --config editor
# select "/usr/bin/vim.basic" as default editor here
```

Additional aliases
------------------
```bash
echo "alias l='ls -lA'" >> ~/.bash_aliases
```

SSH autologin by key
--------------------
```bash
mkdir -p ~/.ssh
echo "{your-public-key}" >> ~/.ssh/authorized_keys
chmod -R go-rwx .ssh
```

Change Memory Split
-------------------
If you use the Raspberry Pi without a GUI, you can reduce the GPU RAM to 16 MB.
But for Camera usage 128 MB is needed - and will be set anyway later by Camera Setup.

- `sudo raspi-config`
- 8 Advanced Options - A3 Memory Split - (i.e. "16")
- Finish
