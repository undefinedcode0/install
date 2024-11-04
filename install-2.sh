#!/bin/bash

# Prompt the user for their desired username, hostname, and disk name
read -p "Enter your username: " username
read -p "Enter your hostname: " hostname
read -p "Enter your disk name (e.g., sda): " ddisk

# Set timezone and sync hardware clock
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Install necessary packages in a single command
pacman -S --noconfirm nano bash-completion git grub networkmanager

# Enable multilib repository in pacman configuration
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf

# Configure system locale
sed -i '/en_US.UTF-8/s/^#//g' /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

# Set hostname
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
read -p "Install GRUB with Catppuccin theme? (y/n): " install_grub

if [[ "$install_grub" == "y" ]]; then
    # Install and configure GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

    # Apply the Catppuccin theme
    git clone https://github.com/catppuccin/grub.git
    cp -r grub/src/* /usr/share/grub/themes/
    echo 'GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt"' >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB with the Catppuccin theme installed."
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
