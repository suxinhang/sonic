#!/bin/bash

# Sonic Agent 启动脚本
# 需先启动 Server（start-sonic.sh），Agent 连接 Gateway 注册设备

cd "$(dirname "$0")"

export SONIC_SERVER_HOST="${SONIC_SERVER_HOST:-127.0.0.1}"
export SONIC_SERVER_PORT="${SONIC_SERVER_PORT:-3000}"

AGENT_DIR="sonic-agent"
LOGS_DIR="logs"
mkdir -p "$LOGS_DIR"
PID_FILE=".pids/agent.pid"
mkdir -p .pids

# 检测当前平台并编译（可选）
detect_platform() {
  case "$(uname -s)" in
    Darwin)
      case "$(uname -m)" in
        arm64) echo "macosx-arm64" ;;
        x86_64) echo "macosx-x86_64" ;;
        *) echo "macosx-x86_64" ;;
      esac ;;
    Linux)
      case "$(uname -m)" in
        aarch64|arm64) echo "linux-arm64" ;;
        x86_64) echo "linux-x86_64" ;;
        i686) echo "linux-x86" ;;
        *) echo "linux-x86_64" ;;
      esac ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "windows-x86_64" ;;
    *)
      echo "linux-x86_64" ;;
  esac
}

# 查找已存在的 agent jar（任意平台）
find_agent_jar() {
  find "$AGENT_DIR/target" -maxdepth 1 -name 'sonic-agent-*.jar' -type f 2>/dev/null | head -1
}

do_build=false
if [[ "${1:-}" == "--build" ]]; then
  do_build=true
fi

if [[ -n "$(find_agent_jar)" ]]; then
  AGENT_JAR="$(find_agent_jar)"
  echo ">>> 使用已编译包: $AGENT_JAR"
elif [[ "$do_build" == true ]]; then
  echo ">>> 编译 Sonic Agent（平台: $(detect_platform)）..."
  (cd "$AGENT_DIR" && mvn package -DskipTests -q -Dplatform="$(detect_platform)")
  AGENT_JAR="$(find_agent_jar)"
  if [[ -z "$AGENT_JAR" ]]; then
    echo ">>> 编译后未找到 jar，请检查 $AGENT_DIR/target/"
    exit 1
  fi
else
  echo ">>> 未找到 sonic-agent-*.jar，请先执行: cd sonic-agent && mvn package -Dplatform=\$(uname -m | sed 's/aarch64/arm64/')"
  echo "    或运行本脚本并加参数: $0 --build"
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo ">>> Agent 已在运行 (PID $OLD_PID)"
    echo "    停止: kill $OLD_PID  或  ./stop-agent.sh"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

# 使用项目根下 config，便于覆盖 server 地址
CONFIG_OPTS=""
if [[ -d "$AGENT_DIR/config" ]]; then
  CONFIG_OPTS="--spring.config.additional-location=file:$(pwd)/$AGENT_DIR/config/"
fi

echo ">>> 启动 Sonic Agent（Server: $SONIC_SERVER_HOST:$SONIC_SERVER_PORT）..."
nohup java -jar "$AGENT_JAR" \
  $CONFIG_OPTS \
  -Dsonic.server.host="$SONIC_SERVER_HOST" \
  -Dsonic.server.port="$SONIC_SERVER_PORT" \
  >> "$LOGS_DIR/agent.log" 2>&1 &
echo $! > "$PID_FILE"
echo ">>> Agent PID: $(cat "$PID_FILE")"
echo "    日志: tail -f $LOGS_DIR/agent.log"
echo "    停止: ./stop-agent.sh 或 kill $(cat "$PID_FILE")"
echo "=========================================="
