Raspberry Pi Customizing
========================

Theese customizations are all optional - just use your favourite settings here.

Hostname
--------
- `sudo raspi-config`
- 8 Advanced Options - A2 Hostname - "timelapse"
- Finish

Locale
------
- `sudo raspi-config`
- 4 Internationalisation Options - I1 Change Locale - de_DE.UTF-8 - as default
- 4 Internationalisation Options - I2 Change Timezone - Europe/Berlin
- 4 Internationalisation Options - I3 Change Keyboard Layout
- Finish

Install vim
-----------
```bash
sudo apt-get install vim
sudo update-alternatives --config editor
```

Additional aliases
------------------
```bash
vi .bashrc
```

Insert below other aliases:
```
alias l='ls -lA'
```

SSH autologin by key
--------------------
```bash
mkdir .ssh
echo "{your-public-key}" >> .ssh/authorized_keys
chmod -R go-rwx .ssh
```
