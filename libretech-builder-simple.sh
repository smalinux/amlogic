#!/bin/bash

pushd ./external/libretech-builder-simple/

	#install pre-requisites via apt or yum
	sudo ./setup.sh

	# ./build.sh BOARD_TARGET
	# all-h3-cc-h3
	# all-h3-cc-h5
	# aml-s805x-ac
	# aml-s905x-cc
	# aml-s905x-cc-v2
	# aml-s905d-pc
	# roc-rk3328-cc
	# roc-rk3399-pc
	./build.sh aml-s905d3-cc | tee build.log


	sudo /home/smalinux/.local/bin/boot-g12.py ./out/aml-s905d3-cc.usb.tpl



popd


