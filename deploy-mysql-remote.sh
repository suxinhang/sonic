#!/bin/bash
# 在远端服务器 10.60.19.54 上执行此脚本
# 启动MySQL服务在3307端口

echo "=== 在远端服务器启动MySQL (3307端口) ==="

# 1. 使用Docker启动MySQL (推荐)
docker run -d \
  --name sonic-mysql-3307 \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=sonic \
  -p 3307:3306 \
  --restart=always \
  mysql:5.7

# 等待MySQL启动
echo "等待MySQL启动..."
sleep 10

# 2. 创建sonic数据库（如果不存在）
docker exec sonic-mysql-3307 mysql -uroot -ppassword -e "CREATE DATABASE IF NOT EXISTS sonic CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 3. 验证数据库创建
docker exec sonic-mysql-3307 mysql -uroot -ppassword -e "SHOW DATABASES LIKE 'sonic';"

echo ""
echo "✅ MySQL已启动在3307端口"
echo "连接信息:"
echo "  主机: 10.60.19.54"
echo "  端口: 3307"
echo "  用户: root"
echo "  密码: password"
echo "  数据库: sonic"

