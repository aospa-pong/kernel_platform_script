#!/bin/bash

if [[ -z "${1}" ]]; then
    echo "No device specified."
    exit
fi

export TARGET_BOARD_PLATFORM=taro
export TARGET_BUILD_VARIANT=user

export ANDROID_BUILD_TOP=$(pwd)
export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${TARGET_BOARD_PLATFORM}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-kernel-${TARGET_BOARD_PLATFORM}

export EXT_MODULES="
  ../vendor/qcom/opensource/mmrm-driver
  ../vendor/qcom/opensource/audio-kernel
  ../vendor/qcom/opensource/camera-kernel
  ../vendor/qcom/opensource/dataipa/drivers/platform/msm
  ../vendor/qcom/opensource/datarmnet/core
  ../vendor/qcom/opensource/datarmnet-ext/offload
  ../vendor/qcom/opensource/datarmnet-ext/perf_tether
  ../vendor/qcom/opensource/datarmnet-ext/shs
  ../vendor/qcom/opensource/datarmnet-ext/wlan
  ../vendor/qcom/opensource/display-drivers/msm
  ../vendor/qcom/opensource/eva-kernel
  ../vendor/qcom/opensource/video-driver
  ../vendor/qcom/opensource/wlan/qcacld-3.0/.qca6490
"

export LTO=full

RECOMPILE_KERNEL=1 ./kernel_platform/build/android/prepare_vendor.sh ${TARGET_BOARD_PLATFORM} gki
