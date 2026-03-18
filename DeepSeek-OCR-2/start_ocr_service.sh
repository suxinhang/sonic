#!/bin/bash

# 启动 DeepSeek-OCR-2 API 服务（使用当前目录虚拟环境）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== 启动 DeepSeek-OCR-2 API 服务 ==="
echo ""

# 检查端口是否被占用
if lsof -i :8888 > /dev/null 2>&1; then
    echo "⚠️  端口 8888 已被占用，请先停止现有服务"
    lsof -i :8888
    exit 1
fi

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "❌ 错误: 虚拟环境不存在，请先创建: python3 -m venv venv && source venv/bin/activate && pip install -r requirements_api.txt"
    exit 1
fi

# 设置环境变量
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export OCR_SERVER_HOST=${OCR_SERVER_HOST:-127.0.0.1}
export OCR_SERVER_PORT=${OCR_SERVER_PORT:-8888}
export OCR_OUTPUT_PATH=${OCR_OUTPUT_PATH:-${SCRIPT_DIR}/logs/ocr_output}

mkdir -p "$OCR_OUTPUT_PATH"

echo "配置信息:"
echo "  地址: http://${OCR_SERVER_HOST}:${OCR_SERVER_PORT}"
echo "  输出目录: $OCR_OUTPUT_PATH"
echo ""

echo "激活虚拟环境并启动服务..."
echo "按 Ctrl+C 停止服务"
echo ""

source venv/bin/activate
python3 ocr_api_server.py
