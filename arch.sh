read -sp "Please enter a root password: " pass

read -p "Enter hostname: " hstname

read -p "Enter partition sizes in Gb: " partition_size

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

yes | mkfs.ext4 /dev/sda1
yes | mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt

mkdir -p /mnt/boot /mnt/home

mount /dev/sda1 /mnt/boot

pacstrap /mnt base base-devel linux linux-firmware dhcpcd

genfstab -U /mnt >> /mnt/etc/fstab


hstname > /mnt/etc/hostname

arch-chroot /mnt

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
