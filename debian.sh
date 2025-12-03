#!/bin/bash

pushd ./external/debian/
	wget https://distro.libre.computer/ci/debian/12/debian-12-base-arm64%2Baml-s905x-cc.img.xz
	unxz debian-12-base-arm64+aml-s905x-cc.img.xz

	# Flash to SD card
	#sudo dd if=debian-12-base-arm64+aml-s905x-cc.img of=/dev/sdX bs=4M status=progress conv=fsync

	# Wait for it to complete, then sync
	sync

popd

