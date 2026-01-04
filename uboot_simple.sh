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

# Clone U-Boot
git clone --single-branch --depth 1 -b v2025.07/lc-master \
    https://github.com/libre-computer-project/libretech-u-boot.git u-boot

# Build U-Boot
export CROSS_COMPILE=aarch64-elf-
make -C u-boot distclean
make -C u-boot -j$(nproc) aml-s905d3-cc_defconfig
make -C u-boot -j$(nproc)

# Create output directory
mkdir -p out

# Clone Amlogic BLx firmware
git clone --depth=1 --single-branch \
    https://github.com/libre-computer-project/libretech-amlogic-blx.git vendor/amlogic/blx

###############################################################################
#                Sign and encrypt bootloader components
###############################################################################
#   ┌──────────────────────────────────────────────────────────────────────┐
#   │                  aml_encrypt_g12a Tool                               │
#   │                  (Amlogic G12A Secure Boot)                          │
#   └──────────────────────────────────────────────────────────────────────┘
#
#   Step 1: BL30 (Two-stage encryption)
#     bl30_new.bin
#       │
#       └─► --bl30sig ──► bl30_new.bin.g12.enc  (G12A encryption)
#
#   Step 2: BL30 (Two-stage encryption)
#     bl30_new.bin.g12.enc
#       │
#       └─► --bl3sig  ──► bl30_new.bin.enc      (Final signature, type=bl30)
#
#   Step 3: BL31 (Single-stage encryption)
#     bl31.img
#       │
#       └─► --bl3sig  ──► bl31.img.enc          (Signature, type=bl31)
#
#   Step 4: BL33 / U-Boot (Compressed + encrypted)
#     u-boot.bin
#       │
#       └─► --bl3sig  ──► u-boot.bin.enc        (LZ4 compress + sign, type=bl33)
#           --compress lz4
#
#   Step 5: BL2 (Bootloader signature)
#     bl2_new.bin
#       │
#       └─► --bl2sig  ──► bl2.n.bin.sig         (BL2 signature)
#
#   Step 6: Final Assembly
#     --bootmk ──► u-boot-amlogic.bin (Complete bootable image)
#       ├─ BL2:     bl2.n.bin.sig ............. blob
#       ├─ BL30:    bl30_new.bin.enc .......... blob
#       ├─ BL31:    bl31.img.enc .............. blob
#       ├─ BL33:    u-boot.bin.enc
#       ├─ DDRFW1:  piei.fw                     blob
#       ├─ DDRFW2:  lpddr4_1d.fw                blob
#       ├─ DDRFW3:  lpddr4_2d.fw                blob
#       └─ DDRFW4:  aml_ddr.fw                  blob
#
#
#
#
# Step 1: BL30 first-stage encryption (G12A-specific format)
#
# Input: bl30_new.bin blob: Raw BL30 SCP firmware (Cortex-M power management firmware)
# Output: G12A encrypted format (.g12.enc)
#
# bl30_new.bin blob ──► bl30_new.bin.g12.enc
#
vendor/amlogic/blx/aml_encrypt_g12a --bl30sig --input vendor/amlogic/blx/aml-s905d3-cc/bl30_new.bin \
    --output vendor/amlogic/blx/aml-s905d3-cc/bl30_new.bin.g12.enc --level v3

# Step 2: BL30 second-stage signing (standard BL3x signature)
# Input: G12A encrypted BL30 from step 1
# Output: Fully signed BL30 ready for boot chain
#
# bl30_new.bin.g12.enc ──► bl30_new.bin.enc
#
vendor/amlogic/blx/aml_encrypt_g12a --bl3sig --input vendor/amlogic/blx/aml-s905d3-cc/bl30_new.bin.g12.enc \
    --output vendor/amlogic/blx/aml-s905d3-cc/bl30_new.bin.enc --level v3 --type bl30

# Step 3: BL31 signing (ARM Trusted Firmware - EL3 secure monitor)
# Input: Raw BL31 binary (runs at highest privilege, handles SMC/PSCI)
# Output: Signed BL31 for secure boot chain
#
# bl31.img blob ──► bl31.img.enc
#
vendor/amlogic/blx/aml_encrypt_g12a --bl3sig --input vendor/amlogic/blx/aml-s905d3-cc/bl31.img \
    --output vendor/amlogic/blx/aml-s905d3-cc/bl31.img.enc --level v3 --type bl31

# Step 4: BL33 signing + compression (U-Boot bootloader)
# Input: Compiled U-Boot binary
# Output: LZ4 compressed + signed U-Boot (saves flash space)
#
# u-boot.bin ──► u-boot.bin.enc
#
vendor/amlogic/blx/aml_encrypt_g12a --bl3sig --input u-boot/u-boot.bin --compress lz4 \
    --output u-boot/u-boot.bin.enc --level v3 --type bl33

# Step 5: BL2 signing (second-stage bootloader, DRAM initialization)
# Input: Raw BL2 binary (first code executed after ROM)
# Output: Signed BL2 with secure boot signature
#
# bl2_new.bin blob ──► bl2.n.bin.sig
#
vendor/amlogic/blx/aml_encrypt_g12a --bl2sig --input vendor/amlogic/blx/aml-s905d3-cc/bl2_new.bin \
    --output vendor/amlogic/blx/aml-s905d3-cc/bl2.n.bin.sig

# Step 6: Assemble final bootable image
# Combines all signed boot components + DDR training firmware
# Creates complete boot image ready to flash to eMMC/SD card
vendor/amlogic/blx/aml_encrypt_g12a --bootmk --output u-boot/u-boot-amlogic.bin \
    --bl2 vendor/amlogic/blx/aml-s905d3-cc/bl2.n.bin.sig \
    --bl30 vendor/amlogic/blx/aml-s905d3-cc/bl30_new.bin.enc \
    --bl31 vendor/amlogic/blx/aml-s905d3-cc/bl31.img.enc \
    --bl33 u-boot/u-boot.bin.enc \
    --ddrfw1 vendor/amlogic/blx/init/g12a/piei.fw \
    --ddrfw2 vendor/amlogic/blx/init/g12a/lpddr4_1d.fw \
    --ddrfw3 vendor/amlogic/blx/init/g12a/lpddr4_2d.fw \
    --ddrfw4 vendor/amlogic/blx/init/g12a/aml_ddr.fw \
    --level v3

# Extract USB boot components
dd if=u-boot/u-boot-amlogic.bin of=out/aml-s905d3-cc.usb.bl2 bs=49152 count=1
dd if=u-boot/u-boot-amlogic.bin of=out/aml-s905d3-cc.usb.tpl bs=1

# Copy final binary
cp u-boot/u-boot-amlogic.bin out/aml-s905d3-cc

# Copy config and device tree
cp u-boot/.config out/aml-s905d3-cc.config
cp u-boot/u-boot.dtb out/aml-s905d3-cc.dtb
dtc -I dtb -O dts u-boot/u-boot.dtb -o out/aml-s905d3-cc.dts

