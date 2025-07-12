# NanoPi-Neo-3-WiFi-Hotspot
Allow WiFi Hotspot using compatible USB WiFi dongle on Nano Pi Neo 3 running Armbian Ubuntu 24 Noble

This repo is written solely to allow the nano pi neo 3 to act as an access point using a wifi dongle

HOW TO USE:
1. plug in the compatible wifi dongle to the USB3 or USB2 gpios (5V DM1 DP1 GND) <-- these work on the nano pi neo 3
2. bash setup_AP        : To download the required packages and start the hotspot
3. bash begin_AP        : For systemd automated start of hotspot in case it fails
4. bash undo_setup_AP   : To remove changes to the network config 

If you have already used the wifi dongle for connecting to wifi, please remove the netplan.yaml config for the wifi interface

WiFi Dongle I used: https://www.aliexpress.com/item/1005004332857193.html

<img width="300" height="300" alt="image" src="https://github.com/user-attachments/assets/af159c4c-92bc-4f63-8522-24274bfdd6c9" />

