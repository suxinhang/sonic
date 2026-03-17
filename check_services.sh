#!/bin/bash

# 检查所有服务状态的脚本

echo "=== Sonic OCR服务状态检查 ==="
echo ""

# 检查OCR服务
echo "1. OCR服务 (端口8888):"
if lsof -i :8888 > /dev/null 2>&1; then
    echo "   ✅ 运行中"
    curl -s http://127.0.0.1:8888/health 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "   ⚠️  服务运行但健康检查失败"
else
    echo "   ❌ 未运行"
    echo "   启动命令: ./start_ocr_service.sh"
fi
echo ""

# 检查Controller服务
echo "2. Controller服务 (端口3002):"
if lsof -i :3002 > /dev/null 2>&1; then
    echo "   ✅ 运行中"
    # 检查OCR端点
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3002/server/api/ocr/status 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo "   ✅ OCR端点可用"
    elif [ "$response" = "404" ]; then
        echo "   ⚠️  OCR端点返回404 - 需要重新编译Controller"
        echo "   编译命令: cd sonic-server/sonic-server-controller && mvn clean package -DskipTests"
    else
        echo "   ⚠️  OCR端点状态码: $response"
    fi
else
    echo "   ❌ 未运行"
fi
echo ""

# 检查OCR代码
echo "3. OCR代码文件:"
if [ -f "sonic-server/sonic-server-controller/src/main/java/org/cloud/sonic/controller/controller/OcrController.java" ]; then
    echo "   ✅ OcrController.java 存在"
else
    echo "   ❌ OcrController.java 不存在"
fi

if [ -f "sonic-server/sonic-server-controller/src/main/java/org/cloud/sonic/controller/services/impl/OcrServiceImpl.java" ]; then
    echo "   ✅ OcrServiceImpl.java 存在"
else
    echo "   ❌ OcrServiceImpl.java 不存在"
fi
echo ""

echo "=== 检查完成 ==="
