#!/bin/bash
# 检查 Sonic 使用的数据库能否连接（与 start-sonic.sh 使用相同配置）

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# 与 start-sonic.sh 保持一致
export MYSQL_HOST="${MYSQL_HOST:-10.60.19.54}"
export MYSQL_PORT="${MYSQL_PORT:-3306}"
export MYSQL_DATABASE="${MYSQL_DATABASE:-sonic}"
export MYSQL_USERNAME="${MYSQL_USERNAME:-root}"
export MYSQL_PASSWORD="${MYSQL_PASSWORD:-Sonic!@#123}"
export SONIC_USE_H2="${SONIC_USE_H2:-1}"

echo "=========================================="
echo "Sonic 数据库连接检查"
echo "=========================================="
echo "SONIC_USE_H2=$SONIC_USE_H2 (1=H2 内存库, 0=MySQL)"
echo ""

if [[ "$SONIC_USE_H2" == "1" ]]; then
  echo "[H2] 当前使用内存库，数据在 Controller 进程内，无独立端口。"
  echo "     无需单独测连；启动 Controller 后登录成功即表示 DB 正常。"
  echo "=========================================="
  exit 0
fi

# MySQL 连接测试
echo "[MySQL] 主机=$MYSQL_HOST 端口=$MYSQL_PORT 库=$MYSQL_DATABASE 用户=$MYSQL_USERNAME"
echo ""

if ! command -v mysql &>/dev/null; then
  echo "未检测到 mysql 客户端。可先测试端口是否可达："
  echo "  nc -zv $MYSQL_HOST $MYSQL_PORT"
  echo "或安装 MySQL 客户端后重新运行本脚本。"
  exit 1
fi

echo "正在连接 MySQL..."
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1 AS ok;" 2>/dev/null; then
  echo ""
  echo "MySQL 连接成功。"
  echo "表列表："
  mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES;" 2>/dev/null || true
else
  echo "MySQL 连接失败。请检查："
  echo "  - 网络/端口: nc -zv $MYSQL_HOST $MYSQL_PORT"
  echo "  - 用户名、密码是否与 start-sonic.sh 中一致"
  exit 1
fi

echo ""
echo "=========================================="
echo "检查结束"
echo "=========================================="
