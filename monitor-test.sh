#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"
STATE_FILE="/var/run/monitor-test.lastpid"

# Получить PID процесса
PID=$(pgrep -x "$PROCESS_NAME")

# Если процесс не найден — выходим
if [[ -z "$PID" ]]; then
    exit 0
fi

# Проверка: перезапущен ли процесс
RESTARTED=false
if [[ -f "$STATE_FILE" ]]; then
    LAST_PID=$(cat "$STATE_FILE")
    if [[ "$LAST_PID" != "$PID" ]]; then
        RESTARTED=true
    fi
else
    RESTARTED=true
fi

# Сохраняем текущий PID
echo "$PID" > "$STATE_FILE"

# Стучимся на URL
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$URL")

if [[ "$HTTP_CODE" -ne 200 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Ошибка: Сервер мониторинга недоступен (код $HTTP_CODE)" >> "$LOG_FILE"
fi

if $RESTARTED; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Процесс $PROCESS_NAME был перезапущен (PID: $PID)" >> "$LOG_FILE"
fi

exit 0
