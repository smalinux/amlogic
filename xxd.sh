#!/bin/bash

# Navigate to build directory
cd /src/amlogic/external/uboot

# Source configuration files
. configs/build
. lib/gcc.sh
. lib/git.sh
. lib/atf.sh
. lib/crust.sh
. lib/edk2.sh
. lib/optee.sh
. lib/u-boot.sh

# Set target board
export LBS_TARGET=aml-s905d3-cc

# Source board configuration
. configs/aml-s905d3-cc

# Download toolchains
mkdir -p gcc
cd gcc

## Download aarch64-elf toolchain
#wget https://releases.linaro.org/components/toolchain/binaries/latest-7/aarch64-elf/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz
#tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf.tar.xz

## Download arm-none-eabi toolchain
#wget --content-disposition 'https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2018q2/gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2?revision=bc2c96c0-14b5-4bb4-9f18-bceb4050fee7?product=GNU%20Arm%20Embedded%20Toolchain,64-bit,,Linux,7-2018-q2-update'
#tar -xf gcc-arm-none-eabi-7-2018-q2-update-linux.tar.bz2

## Download aarch64-linux-gnu toolchain
#wget https://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
#tar -xf gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz

cd ..

# Export toolchain paths
export PATH=$PWD/gcc/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf/bin:$PATH
export PATH=$PWD/gcc/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin:$PATH
export PATH=$PWD/gcc/gcc-arm-none-eabi-7-2018-q2-update/bin:$PATH

TOOLCHAIN=/src/amlogic/external/uboot/gcc/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-elf/bin/aarch64-elf
$TOOLCHAIN-objdump -t /tftpboot/barebox-dt-2nd.img

TOOLCHAIN=/src/amlogic/external/uboot/gcc/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu
$TOOLCHAIN-objdump -t /tftpboot/barebox-dt-2nd.img

TOOLCHAIN=/src/amlogic/external/uboot/gcc/gcc-arm-none-eabi-7-2018-q2-update/bin/arm-none-eabi
$TOOLCHAIN-objdump -t /tftpboot/barebox-dt-2nd.img

TOOLCHAIN=/usr/bin/aarch64-linux-gnu
#$TOOLCHAIN-strings /src/barebox/build/images/barebox-dt-2nd.img
$TOOLCHAIN-strings /src/barebox/build/barebox.bin
