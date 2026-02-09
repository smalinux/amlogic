#!/bin/bash

pushd ./external/uboot/

	sudo uhubctl -l 1-1 -p 4 -a off; sleep 1; sudo uhubctl -l 1-1 -p 4 -a on
	sleep 3
	sudo /home/smalinux/.local/bin/boot-g12.py ./out/aml-s905d3-cc.usb.tpl
popd

