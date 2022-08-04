#!/bin/bash

IMAGE=$1

if [ $IMAGE == "noetic-base" ]; then
  BASE_IMAGE=nvcr.io/nvidia/l4t-ml:r32.6.1-py3
  IMAGE_TAG=ghcr.io/itu-auv/auv-jetson-docker:noetic-base
  DOCKERFILE=Dockerfile.ros.noetic-base
  sudo docker build -t $IMAGE_TAG -f $DOCKERFILE --build-arg ROS_PKG=ros_base --build-arg BASE_IMAGE=$BASE_IMAGE .
elif [ $IMAGE == "noetic" ]; then
  BASE_IMAGE=ghcr.io/itu-auv/auv-jetson-docker:noetic-base
  IMAGE_TAG=ghcr.io/itu-auv/auv-jetson-docker:noetic
  DOCKERFILE=Dockerfile.ros.noetic
  sudo docker build -t $IMAGE_TAG -f $DOCKERFILE  --build-arg ROS_PKG=desktop_full --build-arg BASE_IMAGE=$BASE_IMAGE .
elif [ $IMAGE == "noetic-auv" ]; then
  BASE_IMAGE=ghcr.io/itu-auv/auv-jetson-docker:noetic
  IMAGE_TAG=ghcr.io/itu-auv/auv-jetson-docker:noetic-auv
  DOCKERFILE=Dockerfile.ros.noetic-auv
  sudo docker build -t $IMAGE_TAG -f $DOCKERFILE  --build-arg ROS_PKG=desktop_full --build-arg BASE_IMAGE=$BASE_IMAGE .
fi
