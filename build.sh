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
  echo "构建ubuntu24_minimal-armbian..." 
  FILE_NAME="Armbian_26.8.3_Uefi-x86_resolute_current_6.18.45_minimal.img.xz"
else 
  echo "构建standard-armbian..."
  FILE_NAME="Armbian_26.8.3_Uefi-x86_trixie_current_6.18.45_minimal.img.xz"
fi

OUTPUT_PATH="armbian/armbian.img.xz"

echo "正在从归档页面查找文件：$FILE_NAME"
# 解析目录页面，提取目标文件的相对链接
REL_URL=$(curl -s "$BASE_URL" | grep -oP "(?<=href=\")${FILE_NAME}(?=\")" | head -n1)

if [[ -z "$REL_URL" ]]; then
  echo "错误：归档页中未找到文件 $FILE_NAME"
  exit 1
fi
DOWNLOAD_URL="${BASE_URL}${REL_URL}"

echo "下载地址: $DOWNLOAD_URL"
echo "下载文件: $FILE_NAME -> $OUTPUT_PATH"
curl -L --fail -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

echo "下载armbian成功!"
file "$OUTPUT_PATH"

echo "正在解压为: armbian/armbian.img"
xz -d -k "$OUTPUT_PATH"  # -k 保留xz压缩包，不需要就删掉-k
ls -lh armbian/

echo "准备合成 armbian 安装器"
mkdir -p output

docker run --privileged --rm \
        -v "$(pwd)/output:/output" \
        -v "$(pwd)/supportFiles:/supportFiles:ro" \
        -v "$(pwd)/armbian/armbian.img:/mnt/armbian.img" \
        debian:buster \
        /supportFiles/build.sh
