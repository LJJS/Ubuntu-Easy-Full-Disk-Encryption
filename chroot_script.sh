#!/bin/bash
set -e

#$1 is $encrypt_boot
mount -a
if [[ $1 == "TRUE" ]]
	then
		echo "Do you wish to save keyfiles to the encrypted /boot partition so you don't have to type in the passphrase twice?"
		echo "Bear in mind, that the keyfiles are only protected by the /boot encryption."
		echo "If this encryption is weak, so is also the encryption of /root partition weak."
		echo ""
		while true
		do
			read -r -p "Do you want to save key files to the encrypted the /boot partition? [y/N] " input
			case $input in
				[yY][eE][sS]|[yY])
				echo "Keyfiles will be generated"
				keyfile_to_boot="TRUE"
				break
				;;
				[nN][oO]|[nN]|"")
				echo "No keyfiles are generated"
				keyfile_to_boot="FALSE"
				break
				;;
				*)
				echo "Invalid input..."
				;;
			esac
		done
fi

if [[ $keyfile_to_boot == "TRUE" ]]
	then
		echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
		echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf
		mkdir /etc/luks
		dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=512 count=8
		chmod u=rx,go-rwx /etc/luks
		chmod u=r,go-rwx /etc/luks/boot_os.keyfile

		cryptsetup luksAddKey ${DEV}p1 /etc/luks/boot_os.keyfile
		cryptsetup luksAddKey ${DEV}p5 /etc/luks/boot_os.keyfile

		echo "LUKS_BOOT UUID=$(blkid -s UUID -o value /dev/${DM}1) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab
		echo "${DM}5_crypt UUID=$(blkid -s UUID -o value /dev/${DM}5) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab
	else
		echo "LUKS_BOOT UUID=$(blkid -s UUID -o value /dev/${DM}1) none luks,discard" >> /etc/crypttab
		echo "${DM}5_crypt UUID=$(blkid -s UUID -o value /dev/${DM}5) none luks,discard" >> /etc/crypttab
fi

update-initramfs -u -k all
update-grub
read -p "Press enter to exit chroot"
exit
