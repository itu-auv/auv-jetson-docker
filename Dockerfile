# Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
# This dockerfile is retrieved from https://github.com/dusty-nv/jetson-containers.git

#
# this dockerfile roughly follows the 'Installing from source' from:
#   http://wiki.ros.org/melodic/Installation/Source
#
# ARG BASE_IMAGE=nvcr.io/nvidia/l4t-base:r32.5.0
ARG BASE_IMAGE=nvcr.io/nvidia/l4t-ml:r32.6.1-py3
FROM ${BASE_IMAGE}

ARG ROS_PKG=ros_base
ENV ROS_DISTRO=melodic
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
ENV ROS_PYTHON_VERSION=3

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /workspace


#
# add the ROS deb repo to the apt sources list
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          git \
		cmake \
		build-essential \
		curl \
		wget \
		gnupg2 \
		lsb-release \
		ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -


#
# install bootstrap dependencies
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
          libpython3-dev \
          python3-rosdep \
          python3-rosinstall-generator \
          python3-vcstool \
          build-essential && \
    rosdep init && \
    rosdep update && \
    rm -rf /var/lib/apt/lists/*


#
# create workspace
#
RUN mkdir ros_catkin_ws && \
    cd ros_catkin_ws

#
# copy rosinstall file
#
COPY ./melodic-desktop_full.rosinstall ./melodic-desktop_full.rosinstall

#
# rosinstall_generator ${ROS_PKG} vision_msgs --rosdistro ${ROS_DISTRO} --deps --tar > ${ROS_DISTRO}-${ROS_PKG}.rosinstall && \
#

#
# download ros source
#
RUN mkdir src && \
    vcs import --input ${ROS_DISTRO}-${ROS_PKG}.rosinstall ./src && \
    apt-get update

#
# replacing python37 with python3 to fix 
#
RUN find ./src/vision_opencv -type f -name "CMakeLists.txt" -exec sed -i -e "s/find_package(Boost REQUIRED python37)/find_package(Boost REQUIRED python3)/g" {} && \
    find ./src/vision_opencv -type f -name "CMakeLists.txt" -exec sed -i -e "s/find_package(Boost REQUIRED python)/find_package(Boost REQUIRED python3)/g" {} && \ 
    find ./src/vision_opencv -name "module.hpp" -exec sed -i -e "s/static void \* do_numpy_import( )/static void do_numpy_import( )/g" {} && \
    find ./src/vision_opencv -name "module.hpp" -exec sed -i -e "s/return nullptr;/return;/g" {}

#
# rosdep install
#
RUN rosdep install --from-paths ./src --ignore-packages-from-source --rosdistro ${ROS_DISTRO} --skip-keys python3-pykdl --skip-keys=libopencv-dev --skip-keys=cv_bridge -y

#
# build ROS source
#
RUN python3 ./src/catkin/bin/catkin_make_isolated --install --install-space ${ROS_ROOT} -DCMAKE_BUILD_TYPE=Release

#
# setup entrypoint
#
COPY ./entrypoint.sh /entrypoint.sh
RUN echo 'source /opt/ros/${ROS_DISTRO}/setup.bash' >> /root/.bashrc
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
WORKDIR /
