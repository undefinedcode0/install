#!/bin/bash

# Run the commands in order
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
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt sudo pacman -S nano bash-completion
arch-chroot /mnt echo LANG=en_US.UTF-8 > /etc/locale.conf
arch-chroot /mnt echo undefinedcode > /etc/hostname
arch-chroot /mnt passwd
arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash undefinedcode
arch-chroot /mnt EDITOR=nano visudo
arch-chroot /mnt nano /etc/pacman.conf
arch-chroot /mnt bootctl install
arch-chroot /mnt echo title Arch Linux > /boot/loader/entries/arch.conf
arch-chroot /mnt echo linux /vmlinuz-linux >> /boot/loader/entries/arch.conf
arch-chroot /mnt echo initrd /initramfs-linux.img >> /boot/loader/entries/arch.conf
arch-chroot /mnt sudo pacman -S networkmanager
arch-chroot /mnt sudo systemctl enable NetworkManager.service
arch-chroot /mnt echo "options=root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda3) rw" >> /boot/loader/entries/arch.conf
echo Done! Run umount -R /mnt;reboot
