#!/bin/bash

# Sonic Agent 停止脚本

cd "$(dirname "$0")"
PID_FILE=".pids/agent.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo ">>> 未找到 .pids/agent.pid，可能未通过 start-agent.sh 启动"
  exit 0
fi

PID=$(cat "$PID_FILE")
if kill -0 "$PID" 2>/dev/null; then
  echo ">>> 停止 Sonic Agent (PID $PID)"
  kill "$PID" 2>/dev/null || true
  sleep 2
  if kill -0 "$PID" 2>/dev/null; then
    kill -9 "$PID" 2>/dev/null || true
  fi
else
  echo ">>> Agent 进程 $PID 已不存在"
fi
rm -f "$PID_FILE"
echo ">>> Sonic Agent 已停止"
