#!/bin/bash
# Скрипт для проверки статуса fail2ban
# Использование: ./fail2ban-status.sh [jail_name]

JAIL="${1:-}"

if [ -z "$JAIL" ]; then
    # Общий статус
    echo "=== Fail2ban Status ==="
    fail2ban-client status
    echo ""
    echo "=== Active Jails ==="
    fail2ban-client status | grep "Jail list" | sed 's/.*Jail list:\s*//' | tr ',' '\n' | sed 's/^[ \t]*//'
else
    # Статус конкретного jail
    echo "=== Jail: $JAIL ==="
    fail2ban-client status "$JAIL"
    echo ""
    echo "=== Banned IPs ==="
    fail2ban-client status "$JAIL" | grep "Banned IP list" | sed 's/.*Banned IP list:\s*//'
fi
