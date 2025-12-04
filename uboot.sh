#!/bin/bash

pushd ./external/uboot/

	# power off -> on the device
	sudo uhubctl -l 1-3.4 -p 4 -a off; sleep 1; sudo uhubctl -l 1-3.4 -p 4 -a on

	#install pre-requisites via apt or yum
	sudo ./setup.sh

	# ./build.sh BOARD_TARGET
	# all-h3-cc-h3
	# all-h3-cc-h5
	# aml-s805x-ac
	# aml-s905x-cc
	# aml-s905d3-cc <------------------------
	# aml-s905x-cc-v2
	# aml-s905d-pc
	# roc-rk3328-cc
	# roc-rk3399-pc
	./build.sh aml-s905d3-cc | tee build.log

	# Deploy: put the device in usb mode by pressing the push button and then
	# power the device
	sudo /home/smalinux/.local/bin/boot-g12.py ./out/aml-s905d3-cc.usb.tpl
popd
