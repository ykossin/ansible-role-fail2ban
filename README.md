# Ansible Role: Fail2ban

Роль для установки и настройки fail2ban для защиты от брутфорса на Debian/Ubuntu системах.

## Описание

Эта роль устанавливает и настраивает fail2ban для защиты серверов от атак брутфорса:
- Установка fail2ban
- Настройка jail для различных сервисов (SSH, HTTP, etc.)
- Настройка белого списка IP адресов
- Настройка email уведомлений (опционально)
- Создание пользовательских фильтров и действий

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

## Теги

- `fail2ban` - все задачи fail2ban
- `packages` - установка пакетов
- `config` - настройка конфигурации
- `filters` - создание фильтров
- `actions` - создание действий
- `service` - управление сервисом
- `check` - проверка статуса

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
