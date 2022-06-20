#!/bin/bash

HOSTNAME=jetson
HOST_BAGDIR=/home/nvidia/bags
DOCKER_BAGDIR=/bags
AUV_IMAGE=ghcr.io/itu-auv/auv-jetson-docker:noetic-auv
CONTAINER_ID=$(sudo docker container list | grep ghcr.io/itu-auv/auv-jetson-docker:noetic-auv | awk '{print $1}')

function check_usb () {
  if [ ! -z $1 ]; then
    _USB_ACT_PATH_=$(readlink -f $1)
    if [ $_USB_ACT_PATH_ != $1 ]; then
      echo $1;
    # else
      # echo 0;
    fi
  # else
    # echo 0;
  fi
}


ACTIVE_DEVICES=()


ACTIVE_DEVICES+=($(check_usb /dev/auv_mainboard))
ACTIVE_DEVICES+=($(check_usb /dev/auv_dvl))
ACTIVE_DEVICES+=($(check_usb /dev/auv_mainboard_debug))
ACTIVE_DEVICES+=($(check_usb /dev/auv_imu))
ACTIVE_DEVICES+=($(check_usb /dev/auv_cam_front))
ACTIVE_DEVICES+=($(check_usb /dev/auv_cam_bottom))
ACTIVE_DEVICES+=($(check_usb /dev/auv_quaduart_0))
ACTIVE_DEVICES+=($(check_usb /dev/auv_quaduart_1))
ACTIVE_DEVICES+=($(check_usb /dev/auv_quaduart_2))
ACTIVE_DEVICES+=($(check_usb /dev/auv_quaduart_3))

DOCKER_DEVICE_ARGS=""

for value in "${ACTIVE_DEVICES[@]}"
do
    DOCKER_DEVICE_ARGS="$DOCKER_DEVICE_ARGS --device $value" 
done

if [ ! -z $1 ]; then
  if [ $1 == "shell" ]; then
    sudo docker exec -it $CONTAINER_ID bash 
  fi
fi

# sudo docker run -h $HOSTNAME -it -p 11311:11311 $DOCKER_DEVICE_ARGS --mount src=$HOST_BAGDIR,target=$DOCKER_BAGDIR,type=bind $AUV_IMAGE
sudo docker run -h $HOSTNAME -it --network host -p 11311:11311 $DOCKER_DEVICE_ARGS --device /dev/i2c-1 --mount src=$HOST_BAGDIR,target=$DOCKER_BAGDIR,type=bind --mount src=/home/nvidia/auv-jetson-docker-noetic/auv-software,target=/auv_ws/src/auv_software,type=bind $AUV_IMAGE


