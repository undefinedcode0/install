#!/bin/bash
set -e  # Stop script if any command fails

# Run the commands in order
echo "You WILL have to manually configure your disk. Luckily for you, the script formats the disk after. Here is your layout: boot, swap, root, home."
read -p "Enter your disk name in `/dev` (e.g. 'sda' or 'nvme0n1'): " ddisk

# Ask for confirmation before proceeding
read -p "WARNING: This will format the disk and destroy all data on /dev/$ddisk. Are you sure? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborting."
    exit 1
fi

# Disk partitioning
gdisk "/dev/$ddisk"
cgdisk "/dev/$ddisk"

# Format partitions
mkfs.ext4 "/dev/${ddisk}3"
mkfs.ext4 "/dev/${ddisk}4"
mkswap "/dev/${ddisk}2"
swapon "/dev/${ddisk}2"
mkfs.fat -F 32 "/dev/${ddisk}1"

# Mount partitions
mount "/dev/${ddisk}3" /mnt
mkdir -p /mnt/boot  # Ensure the directory exists
mount "/dev/${ddisk}1" /mnt/boot

# Install necessary packages
pacman -Sy --noconfirm pacman-contrib
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

# Install base system
pacstrap /mnt base linux linux-firmware base-devel

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt
