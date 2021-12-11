read -sp "Please enter a root password: " pass
echo "\n"
read -p "Enter hostname: " hstname
echo "\n"
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

pacstrap /mnt base base-devel linux linux-firmware dhcpcd

genfstab -U /mnt >> /mnt/etc/fstab

echo $hstname > /mnt/etc/hostname

arch-chroot /mnt

# Inside the Arch installation

passwd

mkinitcpio -p linux

pacman --noconfirm --needed -S grub && grub-install --target=i386-pc /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen

locale-gen

ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime

pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager

curl -O "https://raw.githubusercontent.com/Vagos/vars/main/install.sh" && bash install.sh
