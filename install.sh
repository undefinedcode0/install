#!/bin/bash

# Run the commands in order
echo "You WILL have to manually configure your disk, luckily for you, the script formats it the disk. Here is your layout, boot, swap, root, home"
gdisk /dev/sda
cgdisk /dev/sda
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4
mkswap /dev/sda2
swapon /dev/sda2
mkfs.fat -F 32 /dev/sda1
mount /dev/sda3 /mnt
mount --mkdir /dev/sda1 /mnt/boot
sudo pacman -Sy pacman-contrib
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
pacstrap -K /mnt base linux linux-firmware base-devel
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
