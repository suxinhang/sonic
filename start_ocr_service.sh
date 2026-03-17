#!/bin/bash

# 启动OCR服务的便捷脚本（使用虚拟环境）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCR_DIR="${SCRIPT_DIR}/DeepSeek-OCR-2"

echo "=== 启动DeepSeek-OCR-2 API服务 ==="
echo ""

# 检查端口是否被占用
if lsof -i :8888 > /dev/null 2>&1; then
    echo "⚠️  端口8888已被占用，请先停止现有服务"
    lsof -i :8888
    exit 1
fi

# 检查虚拟环境
if [ ! -d "$OCR_DIR/venv" ]; then
    echo "❌ 错误: 虚拟环境不存在，请先运行安装脚本"
    exit 1
fi

# 设置环境变量
export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}
export OCR_SERVER_HOST=${OCR_SERVER_HOST:-127.0.0.1}
export OCR_SERVER_PORT=${OCR_SERVER_PORT:-8888}
export OCR_OUTPUT_PATH=${OCR_OUTPUT_PATH:-${SCRIPT_DIR}/logs/ocr_output}

# 创建输出目录
mkdir -p "$OCR_OUTPUT_PATH"

echo "配置信息:"
echo "  地址: http://${OCR_SERVER_HOST}:${OCR_SERVER_PORT}"
echo "  输出目录: $OCR_OUTPUT_PATH"
echo ""

# 切换到OCR目录并启动服务
cd "$OCR_DIR"
echo "激活虚拟环境并启动服务..."
echo "按 Ctrl+C 停止服务"
echo ""

source venv/bin/activate
python3 ocr_api_server.py
