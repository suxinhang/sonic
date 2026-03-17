#!/bin/bash

# Sonic 云真机平台启动脚本
# 使用 10.60.19.54 的 MySQL 服务

export MYSQL_HOST=10.60.19.54
export MYSQL_PORT=3306
export MYSQL_DATABASE=sonic
export MYSQL_USERNAME=root
export MYSQL_PASSWORD='Sonic!@#123'

export SONIC_EUREKA_HOST=127.0.0.1
export SONIC_EUREKA_PORT=8761
export SONIC_EUREKA_USERNAME=sonic
export SONIC_EUREKA_PASSWORD=sonic
# 使用无认证 URL，避免 Eureka 客户端 AuthScheme is null 导致无法注册
export SONIC_EUREKA_SERVICE_URL="http://127.0.0.1:8761/eureka/"

export SONIC_SERVER_HOST=127.0.0.1
export SONIC_SERVER_PORT=3000

export SECRET_KEY=sonic
export EXPIRE_DAY=7
export REGISTER_ENABLE=true
export NORMAL_USER_ENABLE=true
export LDAP_USER_ENABLE=false

# 本地无 MySQL 时设为 1，使用 H2 内存库；有 MySQL 时设为 0
export SONIC_USE_H2="${SONIC_USE_H2:-1}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/sonic-server"
mkdir -p "$ROOT/logs"

# 检查是否已编译
for jar in sonic-server-eureka/target/sonic-server-eureka.jar \
           sonic-server-gateway/target/sonic-server-gateway.jar \
           sonic-server-controller/target/sonic-server-controller.jar \
           sonic-server-folder/target/sonic-server-folder.jar; do
  if [[ ! -f "$jar" ]]; then
    echo ">>> 未找到 $jar，请先编译: cd sonic-server && mvn package -DskipTests"
    exit 1
  fi
done

echo "启动 Sonic Eureka 服务注册中心..."
java -jar sonic-server-eureka/target/sonic-server-eureka.jar > "$ROOT/logs/eureka.log" 2>&1 &
EUREKA_PID=$!
echo "Eureka PID: $EUREKA_PID"
sleep 10

echo "启动 Sonic Gateway 网关..."
java -jar sonic-server-gateway/target/sonic-server-gateway.jar > "$ROOT/logs/gateway.log" 2>&1 &
GATEWAY_PID=$!
echo "Gateway PID: $GATEWAY_PID"
sleep 5

echo "启动 Sonic Controller 控制器..."
if [[ "$SONIC_USE_H2" == "1" ]]; then
  echo "    (使用 H2 内存库，无需 MySQL)"
  java -Dspring.profiles.active=sonic-server-controller,eureka,jdbc-local,feign,logging,user,ocr -jar sonic-server-controller/target/sonic-server-controller.jar > "$ROOT/logs/controller.log" 2>&1 &
else
  java -jar sonic-server-controller/target/sonic-server-controller.jar > "$ROOT/logs/controller.log" 2>&1 &
fi
CONTROLLER_PID=$!
echo "Controller PID: $CONTROLLER_PID"
sleep 5

echo "启动 Sonic Folder 文件服务..."
java -jar sonic-server-folder/target/sonic-server-folder.jar > "$ROOT/logs/folder.log" 2>&1 &
FOLDER_PID=$!
echo "Folder PID: $FOLDER_PID"

echo ""
echo "=========================================="
echo "Sonic 服务启动完成！"
echo "=========================================="
echo "Eureka:   http://127.0.0.1:8761"
echo "Gateway:  http://127.0.0.1:3000"
echo "Controller PID: $CONTROLLER_PID"
echo "Folder PID: $FOLDER_PID"
echo ""
echo "查看日志: tail -f logs/*.log"
echo "停止服务: kill $EUREKA_PID $GATEWAY_PID $CONTROLLER_PID $FOLDER_PID"
echo "=========================================="

