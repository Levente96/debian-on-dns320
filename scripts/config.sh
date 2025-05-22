./debootstrap/debootstrap --second-stage
for f in $(busybox --list-full | grep -v readlink); do [ -e $f ] || ln -s /bin/busybox $f; done

# Setup the user
useradd -m -s /bin/bash -G sudo dlink
echo 'dlink:dns320' | chpasswd

cat >/etc/myconfig.conf <<EOL
line 1, ${kernel}
line 2,
line 3, ${distro}
line 4 line
...
EOL

# Setup drives
cat >/etc/fstab <<EOF
/dev/root   /       auto    noatime                 0 0
tmpfs       /tmp    tmpfs   nodev,nosuid,size=32M   0 0
EOF

# Setup networking
echo 'nas' > etc/hostname
cat >etc/network/interfaces.d/eth0 <<EOF
# Edit to match your network
auto eth0
iface eth0 inet static
    address 192.168.1.2
    netmask 255.255.255.0
    gateway 192.168.1.1
EOF
echo "nameserver 192.168.1.1" > etc/resolv.conf

# Setup modules
cat >etc/initramfs-tools/modules <<EOF
# Thermal management
gpio-fan
kirkwood_thermal
# SATA
ehci_orion
sata_mv
# Ethernet
mv643xx_eth
marvell
mvmdio
ipv6
# Power / USB buttons
evdev
gpio_keys
# USB disks
sd_mod
usb_storage
EOF

cat >/etc/kernel/postinst.d/zz-local-build-image <<EOF
#!/bin/sh -e
# passing the kernel version is required
version="$1"
[ -z "${version}" ] && exit 0

# NB: change depending on your NAS model
cat /boot/vmlinuz-${version} /usr/lib/linux-image-${version}/kirkwood-dns320.dtb \
    > /tmp/appended_dtb

/usr/bin/mkimage -A arm -O linux -T kernel -C none -n uImage \
                 -a 0x00008000 -e 0x00008000 \
                 -d /tmp/appended_dtb /boot/uImage-${version}
ln -sf /boot/uImage-${version} /boot/uImage

/usr/bin/mkimage -A arm -O linux -T ramdisk -C gzip -n uInitrd \
                 -a 0x00e00000 -e 0x00e00000 \
                 -d /boot/initrd.img-${version} /boot/uInitrd-${version}
ln -sf /boot/uInitrd-${version} /boot/uInitrd
EOF

# Build u-boot images for already installed kernel
dpkg-reconfigure $(dpkg --get-selections | egrep 'linux-image-[0-9]' | cut -f1)

apt-get clean
rm -- tmp/* var/tmp/* var/lib/apt/lists/* var/cache/debconf/* var/log/*.log || true
