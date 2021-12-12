read -sp "Please enter a root password: " pass
echo
read -p "Enter hostname: " hstname
echo
read -p "Enter partition sizes in Gb (swap & root): " partition_size

echo $partition_size > psize

IFS=' ' read -ra SIZE <<< $(cat psize)

rm psize

timedatectl set-ntp true

cat <<EOF | fdisk /dev/sda
o
n
p


+512M
n
p


+${SIZE[0]}G
n
p


+${SIZE[1]}G
n
p


w
EOF

partprobe # Inform the OS of partition table changes.

yes | mkfs.ext4 /dev/sda4
yes | mkfs.ext4 /dev/sda3
yes | mkfs.ext4 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda3 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir -p /mnt/home
mount /dev/sda4 /mnt/home

lsblk

read -p "Press ENTER to continue..."

pacstrap /mnt base base-devel linux linux-firmware dhcpcd

genfstab -U /mnt >> /mnt/etc/fstab

echo $hstname > /mnt/etc/hostname

# Create the chroot script

cat >/mnt/chroot.sh << EOF
# Inside the Arch installation

mkinitcpio -p linux && exit 1

passwd

pacman --noconfirm --needed -S grub && grub-install --target=i386-pc /dev/sda && grub-mkconfig -o boot/grub/grub.cfg

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen

locale-gen

ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime

EOF

arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh

arch-chroot /mnt echo "root:$pass" | chpasswd

pacman -Sy

pacman --noconfirm --needed -S networkmanager
# systemctl enable NetworkManager
# systemctl start NetworkManager

umount /mnt/boot

curl -O "https://raw.githubusercontent.com/Vagos/vars/main/install.sh" && bash install.sh
