# Nethunter-In-Termux
This script allow you install *Kali NetHunter* (Kali Linux) in your [Termux application](https://github.com/termux/termux-app) **without** rooted phone.
Yes, you don't need ~root~ to run [Kali Linux](https://www.kali.org/) on your phone.

### Steps For Installation
1. Download script in **HOME** `curl -LO https://raw.githubusercontent.com/marciowb/Nethunter-In-Termux/master/kalinethunter.sh`
2. Give execution permission `chmod +x kalinethunter.sh`
3. Run script `./kalinethunter.sh`

### Usage 
1. Use command `startkali` to start nethunter. Default user is __kali__ and default password is also __kali__.
2. if you want to start nethunter as a root user then use command `startkali -r`.

### VNC Guide
1. To start a vnc session `vnc start`
2. To stop a vnc session `vnc stop`
3. To check status ( Display and port number) of vnc session `vnc status`
4. If user is __kali__ then by default `vnc start` will start vncserver with `DISPLAY=:2` & `PORT=5902` and for root user `DISPLAY=:1` & `PORT=5901`


### In Case Of SSL error: certificate verify failed
Rerun script with extra parameter `--insecure` or copy paste this command `./kalinethunter.sh --insecure`

#### setup LXDE 
Default __DESKTOP__ is _XFCE4_ but you can setup __LXDE__ also https://www.hax4us.com/2018/07/how-to-install-lxde-in-kali-nethunter.html?m=1

#### You have any idea to improve ? So Just give PR
