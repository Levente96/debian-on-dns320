# Running Debian on a DNS-320 REV-A1
## 1. Soldering up the Serial header
Inspecting the pins that look like a serial connection under microscope:
![image](https://github.com/user-attachments/assets/be980292-f23e-41f9-96ec-03d6ee4ea1e8)
The two pins on either side has a trace that are then router next to each other for some time. This means, that those two must be the `TX` and `RX` line. Measuring the pins against the shielding gives the `ground` pin to be the middle one out of the 3 close together, and connecting a logic analyzer to the 2 suspected pins, with the help of the ground pin, the following can be measured:
![image](https://github.com/user-attachments/assets/8e877251-684c-4988-a5f9-dc407a2d8f95)
The connection baudrate is 115200, and connect your serial to USB , so that :
- the pin closes to the MCU is the `RX` of the nas (`TX` pin of the serial adapter)
- the farthest pin is the `TX` of the nas (`RX` pin of the serial adapter).

![image](https://github.com/user-attachments/assets/b8024588-4506-4817-90f1-c90c814c2736)


## 2. Building Debian for it
With a quick online search one can find [this page.](https://jamie.lentin.co.uk/devices/dlink-dns325/) Based on this I created the following scripts (download them from this repository) to be able to generate the bootable linux pendrive quite quick:

```sh

docker-compose run linux builder

```

The generated `.tar.gz` will be inside the `build` folder.

![image](https://github.com/user-attachments/assets/0d11e887-357a-406d-899c-4014c65f021b)

## 3. Flash Debian to your flash drive
Use the partitioning tool of your choiche to format your drive to `ext2` and set the boot lag to `true`.
>**Note:** Normal USB drive is recommanded with no adapters, etc.

![image](https://github.com/user-attachments/assets/3c9b511e-85db-4098-8ad8-6dc2cae71841)
Use the following command to write everything to the drive:
```sh
sudo tar xzf ./build/bullseye-armel.tar.gz -C /mnt/usb/
cd /mnt/usb/
sync
```
>**Note:**`sync` is recommended to save everything to the drive.


## 4. Starting Debian instead of the original FW
Connect to your serial adapter with the
```sh
screen -L /dev/ttyUSB0 115200
```
Starting the nas with the button and as soon as the boot text start rolling press `space` and the `1`. This will be queued and will stip the boot at the u-boot stage, you should get the following terminal:
```txt
Marvell>>
```
Save the result of the command `printenv`, it might come handy.
Connect the USB, adn use the following commands to make u-boot boot from that:
```txt
Marvell>> setenv ethaddr 78:57:2E:26:AE:44 
Marvell>> setenv bootargs console=ttyS0,115200 root=/dev/sda1 usb-storage.delay_use=0 rootdelay=1 rw
Marvell>> usb reset ; ext2load usb 0:1 0xa00000 /boot/uImage ; ext2load usb 0:1 0xf00000 /boot/uInitrd
Marvell>> bootm 0xa00000 0xf00000
```
This will:
- Set the MAC address (anything else can be set here, does not need to be this)
- Set the boot arguments so that the USB will be used
- Reinit the USB, so all drives will be refreshed, and load the `uImage` and the `uInitrd`
>**Note:** This is needed because DLINK's uboot is only willing to boot from this address
- boot from the memory, where you didi just load the `uImage` and `uInitrd`

### Done!
