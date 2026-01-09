#!/bin/bash
# Скрипт для генерации отчета о работе fail2ban
# Использование: ./fail2ban-report.sh [email]

REPORT_FILE="/tmp/fail2ban-report-$(date +%Y%m%d-%H%M%S).txt"
EMAIL="${1:-}"

{
    echo "=== Fail2ban Report ==="
    echo "Date: $(date)"
    echo ""
    
    echo "=== Service Status ==="
    systemctl is-active fail2ban && echo "Active: YES" || echo "Active: NO"
    systemctl is-enabled fail2ban && echo "Enabled: YES" || echo "Enabled: NO"
    echo ""
    
    echo "=== Overall Status ==="
    fail2ban-client status
    echo ""
    
    echo "=== Jail Statistics ==="
    JAILS=$(fail2ban-client status | grep "Jail list" | sed 's/.*Jail list:\s*//' | tr ',' ' ')
    
    for jail in $JAILS; do
        jail=$(echo "$jail" | xargs)  # trim whitespace
        if [ -n "$jail" ]; then
            echo ""
            echo "--- Jail: $jail ---"
            fail2ban-client status "$jail" | grep -E "(Currently failed|Total failed|Currently banned|Total banned|Banned IP list)"
        fi
    done
    
    echo ""
    echo "=== Recent Bans (last 24h) ==="
    if [ -f /var/log/fail2ban.log ]; then
        grep "Ban" /var/log/fail2ban.log | tail -20
    else
        echo "Log file not found"
    fi
    
} > "$REPORT_FILE"

cat "$REPORT_FILE"

if [ -n "$EMAIL" ]; then
    mail -s "Fail2ban Report $(date +%Y-%m-%d)" "$EMAIL" < "$REPORT_FILE"
    echo ""
    echo "Report sent to $EMAIL"
fi

rm -f "$REPORT_FILE"
