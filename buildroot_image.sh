#!/bin/bash

# https://github.com/libre-computer-project/libretech-buildroot
pushd ./external/buildroot/
	# fixup
	mkdir -p ./board/librecomputer/overlay/efi-btrfs

	make librecomputer/aml-s905x-cc/efi-btrfs_defconfig
	make

	# Flash SD card
	sudo dd if=./output/images/sdcard.img of=/dev/sda bs=4M status=progress conv=fsync
	sync
popd

