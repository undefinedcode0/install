#!/bin/bash

# Prompt the user for their desired username, hostname, and disk name
read -p "Enter your username: " username
read -p "Enter your hostname: " hostname
read -p "Enter your disk name (e.g., sda): " ddisk

# Prompt the user for timezone selection
echo "Available timezones:"
ls /usr/share/zoneinfo
read -p "Enter your timezone (e.g., America/Mexico_City): " timezone

# Set timezone and sync hardware clock
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

pacman -S --noconfirm nano bash-completion git grub networkmanager efibootmgr

# Prompt the user for locale selection
echo "Available locales (search for your desired one):"
grep -oP "^#?\s*[a-zA-Z_]+\.UTF-8" /etc/locale.gen | sed 's/#\s*//' | sort
read -p "Enter your locale (e.g., en_US.UTF-8): " locale

# Configure system locale
sed -i "/$locale/s/^#//g" /etc/locale.gen
echo "LANG=$locale" > /etc/locale.conf
locale-gen
echo "$hostname" > /etc/hostname

# Set root password
echo "Enter root password"
passwd

# Create user and set password
useradd -m -g users -G wheel,storage,power -s /bin/bash "$username"
echo "Enter password for user '$username'"
passwd "$username"

# Configure sudoers for wheel group with root password requirement
echo "Defaults rootpw" | EDITOR='tee -a' visudo > /dev/null
echo "%wheel ALL=(ALL) ALL" | EDITOR='tee -a' visudo > /dev/null

# Ask if user wants to install GRUB with the Catppuccin theme
read -p "Install GRUB? (y/n): " install_grub

if [[ "$install_grub" == "y" ]]; then
    # Install and configure GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB installed."
else
    # Install systemd-boot if GRUB is not selected
    bootctl install

    # Create bootloader entry for systemd-boot
    cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${ddisk}3) rw
EOF
fi

# Enable NetworkManager service
systemctl enable NetworkManager.service

# Completion message
echo "Setup complete! Press Ctrl+D to exit chroot, then run 'umount -R /mnt;reboot'."
