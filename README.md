# Ansible Role: Fail2ban

Роль для установки и настройки fail2ban для защиты от брутфорса на Debian/Ubuntu системах.

## Описание

Эта роль устанавливает и настраивает fail2ban для защиты серверов от атак брутфорса:
- Установка fail2ban с обработкой ошибок
- Валидация всех переменных перед применением
- Автоматический бэкап существующей конфигурации
- Проверка зависимостей (ufw, iptables)
- Проверка синтаксиса конфигурации перед перезапуском
- Настройка jail для различных сервисов (SSH, HTTP, etc.)
- Настройка белого списка IP адресов
- Настройка email уведомлений (опционально)
- Создание пользовательских фильтров и действий
- Поддержка systemd backend
- Поддержка rate limiting
- Поддержка IPv6

## Требования

- Debian 11+ или Ubuntu 20.04+
- Доступ root/sudo
- Ansible >= 2.9
- Firewall (ufw) установлен (если используется banaction ufw)

## Переменные роли

См. `defaults/main.yml` для всех доступных переменных.

### Основные переменные

```yaml
# Включить fail2ban
fail2ban_enabled: true

# Настройки бана
fail2ban_config:
  bantime: 3600    # Время бана (секунды)
  findtime: 600    # Окно времени (секунды)
  maxretry: 5      # Количество попыток до бана
  backend: "auto"  # Backend: auto, systemd, pyinotify
  banaction: "ufw" # Действие: ufw, iptables, iptables-multiport, etc.
  chain: "INPUT"   # Цепочка iptables (если используется)
  rate_limit: 10   # Rate limiting (опционально)
  ipv6_enabled: true # Поддержка IPv6

# Включенные jail
fail2ban_jails:
  - name: "sshd"
    enabled: true
    port: "ssh"
    filter: "sshd"
    logpath: "/var/log/auth.log"
    maxretry: 5

# Белый список IP
fail2ban_whitelist_ips:
  - "127.0.0.1/8"
  - "10.0.0.0/8"
```

## Использование

### Базовая настройка

```yaml
- hosts: all
  become: true
  roles:
    - fail2ban
```

### С настройкой SSH jail

```yaml
- hosts: all
  become: true
  vars:
    fail2ban_jails:
      - name: "sshd"
        enabled: true
        port: "ssh"
        filter: "sshd"
        logpath: "/var/log/auth.log"
        maxretry: 3
        bantime: 7200
  roles:
    - fail2ban
```

### С белым списком

```yaml
- hosts: all
  become: true
  vars:
    fail2ban_whitelist_ips:
      - "127.0.0.1/8"
      - "10.0.0.0/8"
      - "192.168.0.0/16"
  roles:
    - fail2ban
```

### С email уведомлениями

```yaml
- hosts: all
  become: true
  vars:
    fail2ban_config:
      destemail: "admin@example.com"
    fail2ban_send_email: true
  roles:
    - fail2ban
```

### С логированием действий и метриками

```yaml
- hosts: all
  become: true
  vars:
    fail2ban_log_actions: true
    fail2ban_collect_metrics: true
    fail2ban_create_log_dirs: true
  roles:
    - fail2ban
```

### С дополнительными jail

```yaml
- hosts: all
  become: true
  vars:
    fail2ban_jails:
      - name: "sshd"
        enabled: true
        port: "ssh"
        filter: "sshd"
        logpath: "/var/log/auth.log"
      - name: "nginx-http-auth"
        enabled: true
        port: "http,https"
        filter: "nginx-http-auth"
        logpath: "/var/log/nginx/error.log"
        maxretry: 3
  roles:
    - fail2ban
```

## Теги

- `fail2ban` - все задачи fail2ban
- `validation` - валидация переменных
- `packages` - установка пакетов
- `dependencies` - проверка зависимостей
- `backup` - создание бэкапа конфигурации
- `logs-check` - проверка лог-файлов
- `config` - настройка конфигурации
- `filters` - создание фильтров
- `actions` - создание действий
- `service` - управление сервисом
- `check` - проверка статуса и синтаксиса
- `logging` - логирование действий роли
- `metrics` - сбор метрик и статистики
- `monitoring` - настройка мониторинга
- `prometheus` - настройка Prometheus экспорта
- `reports` - настройка отчетов

## Примеры использования тегов

```bash
# Только проверка статуса
ansible-playbook playbook.yml --tags check

# Настройка без перезапуска
ansible-playbook playbook.yml --tags config --skip-tags service

# Проверка конкретного jail
fail2ban-client status sshd
```

## Проверка работы

```bash
# Статус fail2ban
fail2ban-client status

# Статус конкретного jail
fail2ban-client status sshd

# Список забаненных IP
fail2ban-client status sshd | grep "Banned IP list"

# Разбан IP
fail2ban-client set sshd unbanip 1.2.3.4

# Бан IP вручную
fail2ban-client set sshd banip 1.2.3.4

# Логи fail2ban
tail -f /var/log/fail2ban.log
```

## Мониторинг

### Простые скрипты

Роль устанавливает несколько полезных скриптов:

```bash
# Интерактивный мониторинг (рекомендуется)
/usr/local/bin/fail2ban-monitor.sh
# Показывает меню с возможностью:
# - Просмотра статуса всех jail
# - Просмотра забаненных IP
# - Разбана IP
# - Бана IP вручную

# Быстрая проверка статуса
/usr/local/bin/fail2ban-status.sh
/usr/local/bin/fail2ban-status.sh sshd  # для конкретного jail

# Генерация отчета
/usr/local/bin/fail2ban-report.sh
/usr/local/bin/fail2ban-report.sh admin@example.com  # с отправкой на email

# Экспорт метрик для Prometheus
/usr/local/bin/fail2ban-prometheus.sh
```

### Prometheus мониторинг

Для включения экспорта метрик в Prometheus:

```yaml
fail2ban_prometheus_enabled: true
fail2ban_prometheus_metrics_dir: "/var/lib/prometheus/node-exporter"
```

Метрики будут обновляться каждую минуту через cron и доступны через node_exporter textfile collector.

**Доступные метрики:**
- `fail2ban_jail_active` - активность jail (0/1)
- `fail2ban_jail_banned_current` - текущее количество забаненных IP
- `fail2ban_jail_banned_total` - всего забанено (counter)
- `fail2ban_jail_failed_current` - текущие неудачные попытки
- `fail2ban_jail_failed_total` - всего неудачных попыток (counter)

### Ежедневные отчеты

Для включения ежедневных отчетов:

```yaml
fail2ban_report_enabled: true
fail2ban_report_email: "admin@example.com"  # опционально
```

Отчеты будут отправляться каждый день в 8:00 утра.

### Email уведомления

Для мгновенных уведомлений при бане:

```yaml
fail2ban_config:
  destemail: "admin@example.com"
fail2ban_send_email: true
```

### Логирование

Все события fail2ban логируются в:
- `/var/log/fail2ban.log` - основной лог
- `journalctl -u fail2ban` - systemd журнал

## Возможности роли

Роль включает следующие возможности:

**Безопасность и надежность:**
- Валидация переменных перед применением изменений
- Автоматическое создание резервных копий конфигурации
- Проверка синтаксиса конфигурации перед перезапуском сервиса
- Проверка наличия необходимых зависимостей (ufw/iptables)
- Детальная обработка ошибок при установке
- Валидация существования и прав доступа к лог-файлам
- Логирование действий роли в отдельный файл
- Сбор метрик и статистики работы fail2ban
- Автоматическое тестирование через Molecule

**Дополнительные настройки:**
- Поддержка различных backend (systemd, pyinotify, auto)
- Rate limiting для ограничения частоты действий
- Поддержка IPv6
- Настройка цепочек iptables

**Структура роли:**
Роль организована в виде модулей:
- `validation.yml` - валидация переменных
- `installation.yml` - установка и проверка зависимостей
- `backup.yml` - создание бэкапов
- `logs-check.yml` - проверка лог-файлов
- `config.yml` - настройка конфигурации
- `service.yml` - управление сервисом
- `check.yml` - проверка статуса и синтаксиса
- `logging.yml` - логирование действий роли
- `metrics.yml` - сбор метрик и статистики

## Troubleshooting

### Проблема: IP забанен, но нужно разбанить

```bash
# Проверка забаненных IP
fail2ban-client status sshd

# Разбан IP
fail2ban-client set sshd unbanip IP_ADDRESS
```

### Проблема: fail2ban не блокирует атаки

1. Проверьте логи: `tail -f /var/log/fail2ban.log`
2. Проверьте логи сервиса: `tail -f /var/log/auth.log`
3. Проверьте фильтр: `fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf`
4. Убедитесь, что firewall работает: `ufw status`
5. Проверьте синтаксис конфигурации: `fail2ban-client -t`
6. Проверьте наличие зависимостей (ufw/iptables): `which ufw` или `which iptables`

### Проблема: Ошибка валидации переменных

Роль автоматически проверяет все переменные. Если возникает ошибка:
1. Проверьте значения в `defaults/main.yml` или в вашем playbook
2. Убедитесь, что все числовые значения > 0
3. Проверьте, что loglevel соответствует допустимым значениям
4. Проверьте, что banaction поддерживается

### Проблема: Конфигурация не применяется

1. Проверьте бэкапы в `/etc/fail2ban/backups/`
2. Проверьте синтаксис: `fail2ban-client -t`
3. Проверьте права доступа к файлам конфигурации
4. Проверьте логи fail2ban: `journalctl -u fail2ban -f`

### Проблема: Слишком много ложных срабатываний

Добавьте IP в белый список:
```yaml
fail2ban_whitelist_ips:
  - "1.2.3.4"
```

Или увеличьте `maxretry` и `findtime`:
```yaml
fail2ban_config:
  maxretry: 10
  findtime: 1200
```

## Лицензия

ISC License

---

**Последнее обновление:** январь 2026
