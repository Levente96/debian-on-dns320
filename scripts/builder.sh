#!/bin/bash -ex

arch=armel
suite=$1
mirror=http://ftp2.de.debian.org/debian/

packages=(
  # Kernel
  linux-image-marvell # * Linux for Marvell Kirkwood/Orion (meta-package)
  device-tree-compiler # * Device Tree Compiler for Flat Device Trees

  # Admin
  cron # process scheduling daemon
  dbus-user-session # * simple interprocess messaging system (systemd --user integration)
  hdparm # * tune hard disk parameters for high performance
  mdadm
  procps # /proc file system utilities
  u-boot-tools # * companion tools for Das U-Boot bootloader
  udev # /dev/ and hotplug management daemon

  # Network
  ifupdown # high level tools to configure network interfaces
  net-tools # NET-3 networking toolkit
  netbase # Basic TCP/IP networking system
  systemd-timesyncd # minimalistic service to synchronize local time with NTP servers

  # Network - Servers
  netatalk # Basic TCP/IP networking system
  nfs-kernel-server # support for NFS kernel server
  openssh-server # secure shell (SSH) server, for secure access from remote machines

  # Utils
  busybox # Tiny utilities for small and embedded systems
  dialog # Displays user-friendly dialog boxes from shell scripts
  fdisk # collection of partitioning utilities
  nano # small, friendly text editor inspired by Pico
  sudo # Provide limited super user privileges to specific users
  wget # retrieves files from the web
  zstd # fast lossless compression algorithm
)

# Create the working directory
mkdir -p /chroot

# Generate the rootf itself
if [ -f /dist/$suite-$arch.tar ]; then
    echo 'Untar existing deboostrap'
    tar xf /dist/$suite-$arch.tar -C /chroot
else
    echo 'Run deboostrap'

    function join { local IFS="$1"; shift; echo "$*"; }
    include=$(join , ${packages[@]})
    echo $include

    debootstrap --foreign --arch=$arch --variant=minbase --include=$include $suite /chroot $mirror \
       || (cp /chroot/debootstrap/debootstrap.log /dist && exit 1)
    tar -cf /build/$suite-$arch.tar -C /chroot/ .
fi

cp ./scripts/config.sh ./chroot/config.sh
update-binfmts --enable
cp /usr/bin/qemu-arm-static /chroot/usr/bin
LANG=C.UTF-8
chroot /chroot qemu-arm-static /bin/bash -ex config.sh

tar czf /build/$suite-$arch.tar.gz -C /chroot/ .
