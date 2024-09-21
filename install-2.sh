#!/bin/bash

# Prompt the user for their desired username and hostname
read -p "Enter your username: " username
read -p "Enter your hostname: " hostname
read -p "Enter your disk name again (e.g. sda): " ddisk

# Set timezone and system clock
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Install necessary packages
pacman -S --noconfirm nano bash-completion

# Set system locale
sed -i '/en_US.UTF-8/s/^#//g' /etc/locale.gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
locale-gen

# Set user-defined hostname
echo "$hostname" > /etc/hostname

# Set password for root
echo "Enter your 'root' password"
passwd

# Create user with specified username and add to necessary groups
useradd -m -g users -G wheel,storage,power -s /bin/bash "$username"
echo "Enter your password for $username"
passwd "$username"

# Configure sudoers file
EDITOR=nano visudo

# Additional configurations (if needed)
nano /etc/pacman.conf

# Install bootloader
bootctl install

# Create bootloader entries
mkdir -p /boot/loader/entries
echo "title Arch Linux" > /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux.img" >> /boot/loader/entries/arch.conf
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${ddisk}3) rw" >> /boot/loader/entries/arch.conf

# Install and enable NetworkManager
pacman -Sy --noconfirm
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service

# Completion message
echo "Done! Press Ctrl-D to exit the chroot environment, then run 'umount -R /mnt;reboot'."
exit
