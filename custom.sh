#!/bin/bash
set -euo pipefail

# 校验参数是否存在
if [ -z "$1" ]; then
  echo "❌ 错误：未提供下载地址！"
  exit 1
fi

mkdir -p imm
DOWNLOAD_URL="$1"
filename=$(basename "$DOWNLOAD_URL")  # 从 URL 提取文件名
OUTPUT_PATH="imm/$filename"

echo "当前工作目录: $(pwd)"
echo "下载地址: $DOWNLOAD_URL"
echo "保存路径: $OUTPUT_PATH"

# 下载文件
if ! curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"; then
  echo "❌ 下载失败！"
  exit 1
fi

echo "✅ 下载成功!"
file "$OUTPUT_PATH"

# 根据扩展名解压
extension="${filename##*.}"  # 获取文件扩展名
case $extension in
  gz)
    echo "gz 正在解压 $OUTPUT_PATH"
    gunzip -f "$OUTPUT_PATH"
    final_name=$(find imm -maxdepth 1 -name '*.img' -print -quit)
    ;;
  zip)
    echo "zip 正在解压 $OUTPUT_PATH"
    unzip -j -o "$OUTPUT_PATH" -d imm/  # -j 忽略目录结构
    final_name=$(find imm -maxdepth 1 -name '*.img' -print -quit)
    ;;
  xz)
    echo "xz 正在解压 $OUTPUT_PATH"
    xz -d --keep "$OUTPUT_PATH"  # 保留原文件
    final_name="${OUTPUT_PATH%.*}"
    ;;
  *)
    echo "❌ 不支持的压缩格式: $extension"
    exit 1
    ;;
esac

# 检查解压出来的img
if [ -z "$final_name" ] || [ ! -f "$final_name" ]; then
  echo "❌ 错误：解压后没有找到 *.img 文件"
  ls -lh imm/
  exit 1
fi

mv "$final_name" "imm/custom.img"

if [ -f "imm/custom.img" ]; then
  echo "✅ 解压成功，重命名为 custom.img"
  ls -lh imm/
  echo "✅ 准备合成 自定义安装器"
else
  echo "❌ 错误：最终文件 imm/custom.img 不存在"
  exit 1
fi

mkdir -p output
echo "👉 启动docker打包，挂载："
echo "  $(pwd)/output  -> /output"
echo "  $(pwd)/imm/custom.img -> /mnt/custom.img"

docker run --privileged --rm \
    -v "$(pwd)/output:/output" \
    -v "$(pwd)/supportFiles:/supportFiles:ro" \
    -v "$(pwd)/imm/custom.img:/mnt/custom.img" \
    debian:buster \
    /supportFiles/custom/build.sh

# ========== 新增！打包完立刻检查ISO ==========
echo "✅ docker 执行完毕，检查 output 目录产物："
ls -lh output/

ISO_FILE=$(find output -maxdepth 1 -name "*.iso" -print -quit)
if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
  echo "❌ 严重错误：build.sh 运行完成，但 output 目录没有生成 iso 文件！"
  exit 1
fi

echo "✅ ISO 生成成功：$ISO_FILE"
