#!/bin/bash

# 启动DeepSeek-OCR-2 API服务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCR_DIR="${SCRIPT_DIR}/DeepSeek-OCR-2"

echo "=== 启动DeepSeek-OCR-2 API服务 ==="
echo ""

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到python3，请先安装Python 3.12+"
    exit 1
fi

# 检查OCR目录
if [ ! -d "$OCR_DIR" ]; then
    echo "❌ 错误: OCR目录不存在: $OCR_DIR"
    exit 1
fi

# 检查依赖
echo "检查Python依赖..."
cd "$OCR_DIR"
if [ ! -f "requirements_api.txt" ]; then
    echo "❌ 错误: requirements_api.txt不存在"
    exit 1
fi

# 安装依赖（如果需要）
if ! python3 -c "import flask" 2>/dev/null; then
    echo "安装Python依赖..."
    pip3 install -r requirements_api.txt
fi

# 设置环境变量
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export OCR_SERVER_HOST=${OCR_SERVER_HOST:-127.0.0.1}
export OCR_SERVER_PORT=${OCR_SERVER_PORT:-8888}
export OCR_OUTPUT_PATH=${OCR_OUTPUT_PATH:-${SCRIPT_DIR}/logs/ocr_output}

# 创建输出目录
mkdir -p "$OCR_OUTPUT_PATH"

# 启动服务
echo "启动OCR API服务..."
echo "  地址: http://${OCR_SERVER_HOST}:${OCR_SERVER_PORT}"
echo "  输出目录: $OCR_OUTPUT_PATH"
echo ""

cd "$OCR_DIR"
python3 ocr_api_server.py

