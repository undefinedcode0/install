#!/bin/bash
set -e  # Stop script if any command fails

# Ask for the disk name
echo "This script will automatically partition your disk with the following layout: boot, swap, and root."
read -p "Enter your disk name in '/dev' (e.g., 'sda' or 'nvme0n1'): " ddisk
[[ -b "/dev/$ddisk" ]] || { echo "Error: Disk /dev/$ddisk not found." >&2; exit 1; }

# Confirm before proceeding
read -p "WARNING: This will format and destroy all data on /dev/$ddisk. Are you sure? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborting."
    exit 1
fi

# Get system RAM size in MiB
ram_size=$(free -m | awk '/^Mem:/{print $2}')

# Get total disk size in MiB
disk_size=$(lsblk -b -d -n -o SIZE "/dev/$ddisk" | awk '{print int($1 / 1024 / 1024)}')
[[ "$disk_size" -ge 8192 ]] || { echo "Error: Disk size is too small. Minimum size is 8 GiB." >&2; exit 1; }

# Swap size calculation
if [[ $((2 * ram_size)) -le $((disk_size / 4)) ]]; then
    swap_size=$((2 * ram_size)) # If disk can handle 2x RAM size, use it
else
    swap_size=$ram_size # Fallback to at least the size of RAM
fi

# Partition size calculations
boot_size=512                                              # Boot partition: 512 MiB
root_size=$((disk_size - boot_size - swap_size))          # Root: All remaining space

# Partition layout summary
echo "Partition layout for /dev/$ddisk:"
echo " - Boot: ${boot_size} MiB"
echo " - Swap: ${swap_size} MiB (based on RAM: ${ram_size} MiB)"
echo " - Root: ${root_size} MiB"

# Proceed with partitioning
echo "Creating partitions..."
parted -s "/dev/$ddisk" mklabel gpt \
    mkpart boot fat32 1MiB ${boot_size}MiB \
    set 1 boot on \
    mkpart swap linux-swap ${boot_size}MiB $((boot_size + swap_size))MiB \
    mkpart root ext4 $((boot_size + swap_size))MiB -- -1s

# Wait for kernel to recognize partitions
sleep 2

# Determine partition naming scheme
if [[ "$ddisk" =~ ^nvme ]]; then
    p="p"  # NVMe uses nvme0n1p1 format
else
    p=""   # SATA/IDE uses sda1 format
fi

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F 32 "/dev/${ddisk}${p}1"    # Boot
mkswap "/dev/${ddisk}${p}2"            # Swap
swapon "/dev/${ddisk}${p}2"
mkfs.ext4 "/dev/${ddisk}${p}3"         # Root

# Mounting partitions
mount "/dev/${ddisk}${p}3" /mnt
mount --mkdir "/dev/${ddisk}${p}1" /mnt/boot

echo "Partitioning and formatting complete."
echo " - Boot: /dev/${ddisk}${p}1"
echo " - Swap: /dev/${ddisk}${p}2"
echo " - Root: /dev/${ddisk}${p}3"

# Install necessary packages
echo "Updating mirror list..."
pacman -Sy --noconfirm pacman-contrib
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

# Install base system
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware base-devel

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Installation complete. You can now chroot with: arch-chroot /mnt"
