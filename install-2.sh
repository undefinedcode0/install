#! /bin/bash

ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
sudo pacman -S nano bash-completion
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo undefinedcode > /etc/hostname
passwd
useradd -m -g users -G wheel,storage,power -s /bin/bash undefinedcode
passwd undefinedcode
EDITOR=nano visudo
nano /etc/pacman.conf
bootctl install
echo title Arch Linux > /boot/loader/entries/arch.conf
echo linux /vmlinuz-linux >> /boot/loader/entries/arch.conf
echo initrd /initramfs-linux.img >> /boot/loader/entries/arch.conf
sudo pacman -S networkmanager
sudo systemctl enable NetworkManager.service
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda3) rw" >> /boot/loader/entries/arch.conf
echo Done! Ctrl-D Run "umount -R /mnt;reboot"
