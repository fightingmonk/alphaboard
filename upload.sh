#!/bin/bash

PORT=/dev/cu.usbserial-142

/usr/local/bin/nodemcu-uploader -p $PORT upload init.lua spi-lights.lua animations.lua
