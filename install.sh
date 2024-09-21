#!/bin/bash

# Run the commands in order
echo "You WILL have to manually configure your disk, luckily for you, the script formats the disk after. Here is your layout, boot, swap, root, home"
read -p "Enter your disk name in `/dev` (e.g. 'sda'): " ddisk
gdisk /dev/$ddisk
cgdisk /dev/$ddisk
mkfs.ext4 /dev/$ddisk3
mkfs.ext4 /dev/$ddisk4
mkswap /dev/$ddisk2
swapon /dev/$ddisk2
mkfs.fat -F 32 /dev/$ddisk1
mount /dev/$ddisk3 /mnt
mount --mkdir /dev/sda1 /mnt/boot
sudo pacman -Sy --noconfirm pacman-contrib
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
pacstrap -K /mnt base linux linux-firmware base-devel
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
