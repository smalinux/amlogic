#!/bin/bash
set -x
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
OUTPUT=${PWD}/output
mkdir -p ${OUTPUT}
UBOOT=${PWD}/external/uboot  # Fixed: was pointing to wrong location
mkdir -p ./external/uboot

pushd ./external/uboot/
	# Check for .git in the CURRENT directory
	if [ ! -d ".git" ]; then
		echo "Cloning u-boot..."
		git clone https://github.com/libre-computer-project/libretech-u-boot .
	else
		echo "u-boot already exists — skipping clone"
		git pull
	fi
	# Build U-boot
	make aml-s905d3-cc_defconfig
	make -j$(nproc)
	echo "U-Boot binary: ${PWD}/u-boot.bin"
popd

pushd ./external/
	# Check for amlogic-boot-fip
	if [ ! -d "amlogic-boot-fip/.git" ]; then
		echo "Cloning amlogic-boot-fip..."
		git clone https://github.com/LibreELEC/amlogic-boot-fip --depth=1
	else
		echo "amlogic-boot-fip already exists — skipping clone"
		cd amlogic-boot-fip
		git pull
		cd ..
	fi

	cd amlogic-boot-fip
	# Use correct path to u-boot.bin
	./build-fip.sh aml-s905d3-cc ${UBOOT}/u-boot.bin ${OUTPUT}
	echo "Output directory: ${OUTPUT}"
popd

echo "Build complete!"
echo "Bootloader image: ${OUTPUT}/u-boot.bin"
