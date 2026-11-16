#!/bin/bash
set -euo pipefail

mkdir -p armbian

# 读取环境变量 (带默认值)
VERSION_TYPE="${VERSION_TYPE:-standard}"
BASE_URL="https://armbian.lv.auroradev.org/dl/uefi-x86/archive/"

if [ "$VERSION_TYPE" = "debian13_minimal" ]; then
    echo "构建debian13_minimal-armbian..."
    FILE_NAME="Armbian_26.8.3_Uefi-x86_trixie_current_6.18.45_minimal.img.xz"
elif [ "$VERSION_TYPE" = "ubuntu24_minimal" ]; then
    echo "构建ubuntu26_minimal-armbian..."
    FILE_NAME="Armbian_26.8.3_Uefi-x86_resolute_current_6.18.45_minimal.img.xz"
else
    echo "构建standard-armbian..."
    FILE_NAME="Armbian_26.8.3_Uefi-x86_trixie_current_6.18.45_minimal.img.xz"
fi

OUTPUT_PATH="armbian/armbian.img.xz"
# 直接拼接，不再抓网页解析，稳定
DOWNLOAD_URL="${BASE_URL}${FILE_NAME}"

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
curl -L --fail -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

echo "下载armbian成功!"
file "$OUTPUT_PATH"

echo "正在解压为: armbian/armbian.img"
xz -d "$OUTPUT_PATH"
ls -lh armbian/

echo "准备合成 armbian 安装器"
mkdir -p output

docker run --privileged --rm \
        -v "$(pwd)/output:/output" \
        -v "$(pwd)/supportFiles:/supportFiles:ro" \
        -v "$(pwd)/armbian/armbian.img:/mnt/armbian.img" \
        debian:buster \
        /supportFiles/build.sh
