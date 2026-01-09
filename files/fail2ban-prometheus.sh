#!/bin/bash
# Скрипт для экспорта метрик fail2ban в формате Prometheus
# Использование: ./fail2ban-prometheus.sh > /var/lib/prometheus/node-exporter/fail2ban.prom

METRICS_FILE="${1:-/var/lib/prometheus/node-exporter/fail2ban.prom}"

# Создаем директорию если не существует
mkdir -p "$(dirname "$METRICS_FILE")"

{
    echo "# HELP fail2ban_jail_active Whether jail is active (1) or not (0)"
    echo "# TYPE fail2ban_jail_active gauge"
    
    echo "# HELP fail2ban_jail_banned_current Current number of banned IPs"
    echo "# TYPE fail2ban_jail_banned_current gauge"
    
    echo "# HELP fail2ban_jail_banned_total Total number of banned IPs"
    echo "# TYPE fail2ban_jail_banned_total counter"
    
    echo "# HELP fail2ban_jail_failed_current Current number of failed attempts"
    echo "# TYPE fail2ban_jail_failed_current gauge"
    
    echo "# HELP fail2ban_jail_failed_total Total number of failed attempts"
    echo "# TYPE fail2ban_jail_failed_total counter"
    
    # Получаем список jail
    JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list" | sed 's/.*Jail list:\s*//' | tr ',' ' ')
    
    for jail in $JAILS; do
        jail=$(echo "$jail" | xargs)  # trim whitespace
        if [ -n "$jail" ]; then
            STATUS=$(fail2ban-client status "$jail" 2>/dev/null)
            
            # Проверяем активность
            if echo "$STATUS" | grep -q "File list"; then
                echo "fail2ban_jail_active{jail=\"$jail\"} 1"
            else
                echo "fail2ban_jail_active{jail=\"$jail\"} 0"
                continue
            fi
            
            # Текущие забаненные IP
            BANNED_CURRENT=$(echo "$STATUS" | grep "Currently banned" | grep -oE '[0-9]+' | head -1)
            echo "fail2ban_jail_banned_current{jail=\"$jail\"} ${BANNED_CURRENT:-0}"
            
            # Всего забанено
            BANNED_TOTAL=$(echo "$STATUS" | grep "Total banned" | grep -oE '[0-9]+' | head -1)
            echo "fail2ban_jail_banned_total{jail=\"$jail\"} ${BANNED_TOTAL:-0}"
            
            # Текущие неудачные попытки
            FAILED_CURRENT=$(echo "$STATUS" | grep "Currently failed" | grep -oE '[0-9]+' | head -1)
            echo "fail2ban_jail_failed_current{jail=\"$jail\"} ${FAILED_CURRENT:-0}"
            
            # Всего неудачных попыток
            FAILED_TOTAL=$(echo "$STATUS" | grep "Total failed" | grep -oE '[0-9]+' | head -1)
            echo "fail2ban_jail_failed_total{jail=\"$jail\"} ${FAILED_TOTAL:-0}"
        fi
    done
    
} > "$METRICS_FILE"

# Устанавливаем правильные права
chmod 644 "$METRICS_FILE"
chown root:root "$METRICS_FILE"

echo "Metrics exported to $METRICS_FILE"
