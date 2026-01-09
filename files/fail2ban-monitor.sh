#!/bin/bash
# Интерактивный мониторинг fail2ban
# Использование: fail2ban-monitor.sh

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Проверка поддержки цветов
if [ ! -t 1 ]; then
    # Если вывод не в терминал, отключаем цвета
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
    BOLD=''
fi

# Функция для очистки экрана
clear_screen() {
    clear
}

# Функция для получения списка jail
get_jails() {
    fail2ban-client status 2>/dev/null | grep "Jail list" | sed 's/.*Jail list:\s*//' | tr ',' ' ' | xargs
}

# Функция для отображения статуса jail
show_jail_status() {
    local jail="$1"
    echo -e "${BOLD}${CYAN}Jail: ${YELLOW}$jail${NC}"
    
    local status=$(fail2ban-client status "$jail" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка получения статуса для jail: $jail${NC}"
        return 1
    fi
    
    # Текущие неудачные попытки
    local failed=$(echo "$status" | grep "Currently failed" | grep -oE '[0-9]+' | head -1)
    local total_failed=$(echo "$status" | grep "Total failed" | grep -oE '[0-9]+' | head -1)
    
    # Забаненные IP
    local banned_current=$(echo "$status" | grep "Currently banned" | grep -oE '[0-9]+' | head -1)
    local banned_total=$(echo "$status" | grep "Total banned" | grep -oE '[0-9]+' | head -1)
    
    # Список забаненных IP
    local banned_ips=$(echo "$status" | grep "Banned IP list" | sed 's/.*Banned IP list:\s*//' | xargs)
    
    echo -e "  Неудачных попыток: ${BOLD}${failed:-0}${NC} (всего: ${total_failed:-0})"
    echo -e "  Забанено IP: ${BOLD}${RED}${banned_current:-0}${NC} (всего: ${banned_total:-0})"
    
    if [ -n "$banned_ips" ] && [ "$banned_ips" != " " ]; then
        echo -e "  ${RED}Забаненные IP:${NC}"
        for ip in $banned_ips; do
            echo -e "    - ${BOLD}$ip${NC}"
        done
    else
        echo -e "  ${GREEN}Нет забаненных IP${NC}"
    fi
    
    # Получаем время бана из конфигурации
    local bantime=$(fail2ban-client get "$jail" bantime 2>/dev/null | grep -oE '[0-9]+' | head -1)
    if [ -n "$bantime" ] && [ "$bantime" -gt 0 ]; then
        local hours=$((bantime / 3600))
        local minutes=$(((bantime % 3600) / 60))
        local seconds=$((bantime % 60))
        if [ $hours -gt 0 ]; then
            echo -e "  ${YELLOW}Время бана:${NC} ${hours}ч ${minutes}м (${bantime} сек)"
        elif [ $minutes -gt 0 ]; then
            echo -e "  ${YELLOW}Время бана:${NC} ${minutes}м ${seconds}с (${bantime} сек)"
        else
            echo -e "  ${YELLOW}Время бана:${NC} ${seconds}с (${bantime} сек)"
        fi
    fi
}

# Функция для отображения всех jail
show_all_jails() {
    clear_screen
    echo -e "${BOLD}${CYAN}Статус всех jail${NC}"
    echo ""
    
    local jails=$(get_jails)
    if [ -z "$jails" ]; then
        echo -e "${RED}Нет активных jail${NC}"
        return 1
    fi
    
    for jail in $jails; do
        jail=$(echo "$jail" | xargs)
        if [ -n "$jail" ]; then
            show_jail_status "$jail"
            echo ""
        fi
    done
}

# Функция для разбана IP
unban_ip() {
    local jail="$1"
    local ip="$2"
    
    if [ -z "$jail" ] || [ -z "$ip" ]; then
        echo -e "${RED}Ошибка: не указан jail или IP${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Разбаниваю IP: $ip в jail: $jail${NC}"
    local result=$(fail2ban-client set "$jail" unbanip "$ip" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ IP $ip успешно разбанен${NC}"
        return 0
    else
        echo -e "${RED}✗ Ошибка при разбане: $result${NC}"
        return 1
    fi
}

# Функция для бана IP
ban_ip() {
    local jail="$1"
    local ip="$2"
    
    if [ -z "$jail" ] || [ -z "$ip" ]; then
        echo -e "${RED}Ошибка: не указан jail или IP${NC}"
        return 1
    fi
    
    # Проверка формата IP
    if ! [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}✗ Неверный формат IP адреса${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Баню IP: $ip в jail: $jail${NC}"
    local result=$(fail2ban-client set "$jail" banip "$ip" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ IP $ip успешно забанен${NC}"
        return 0
    else
        echo -e "${RED}✗ Ошибка при бане: $result${NC}"
        return 1
    fi
}

# Функция для интерактивного меню управления IP
manage_ip_menu() {
    local jail="$1"
    
    while true; do
        clear_screen
        echo -e "${BOLD}${CYAN}Управление IP - Jail: ${YELLOW}$jail${NC}"
        echo ""
        
        show_jail_status "$jail"
        echo ""
        echo -e "${BOLD}${CYAN}Действия:${NC}"
        echo -e "  ${GREEN}1${NC}) Разбанить IP"
        echo -e "  ${RED}2${NC}) Забанить IP"
        echo -e "  ${YELLOW}3${NC}) Обновить статус"
        echo -e "  ${BLUE}0${NC}) Назад"
        echo ""
        echo -ne "${CYAN}Выберите действие:${NC} "
        read action
        
        case $action in
            1)
                echo ""
                read -p "Введите IP адрес для разбана: " ip
                if [ -n "$ip" ]; then
                    unban_ip "$jail" "$ip"
                    echo ""
                    read -p "Нажмите Enter для продолжения..."
                fi
                ;;
            2)
                echo ""
                read -p "Введите IP адрес для бана: " ip
                if [ -n "$ip" ]; then
                    echo -e "${YELLOW}Вы уверены, что хотите забанить $ip? (y/N):${NC} "
                    read -n 1 confirm
                    echo ""
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        ban_ip "$jail" "$ip"
                    fi
                    echo ""
                    read -p "Нажмите Enter для продолжения..."
                fi
                ;;
            3)
                # Просто обновим экран
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Неверный выбор${NC}"
                sleep 1
                ;;
        esac
    done
}

# Функция для вычисления видимой длины строки (без ANSI кодов)
visible_length() {
    local str="$1"
    # Удаляем ANSI коды
    str=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g')
    # Используем Python для правильного подсчета Unicode символов
    python3 -c "import sys; s=sys.stdin.read().rstrip(); print(len(s))" <<< "$str" 2>/dev/null || echo -n "$str" | wc -c | tr -d ' '
}

# Главное меню
main_menu() {
    while true; do
        clear_screen
        echo -e "${BOLD}${CYAN}FAIL2BAN Interactive Monitor${NC}"
        echo -e "${CYAN}Управление блокировками и мониторинг${NC}"
        echo ""
        
        # Проверка доступности fail2ban
        if ! command -v fail2ban-client &> /dev/null; then
            echo -e "${RED}Ошибка: fail2ban-client не найден${NC}"
            exit 1
        fi
        
        # Проверка статуса fail2ban
        local status=$(fail2ban-client status 2>&1)
        if [ $? -ne 0 ]; then
            echo -e "${RED}Ошибка: fail2ban не запущен или недоступен${NC}"
            echo -e "${YELLOW}Попробуйте: systemctl status fail2ban${NC}"
            exit 1
        fi
        
        # Общая информация
        local total_jails=$(echo "$status" | grep "Number of jail" | grep -oE '[0-9]+')
        echo -e "${BOLD}${CYAN}Активных jail:${NC} ${BOLD}${GREEN}${total_jails}${NC}"
        echo ""
        
        # Список jail
        local jails=$(get_jails)
        if [ -z "$jails" ]; then
            echo -e "${RED}Нет активных jail${NC}"
            echo ""
            echo -e "${YELLOW}0${NC}) Выход"
            echo -ne "${CYAN}Выберите действие:${NC} "
            read choice
            case $choice in
                0|q|Q) exit 0 ;;
                *) ;;
            esac
            continue
        fi
        
        echo -e "${BOLD}${CYAN}Доступные jail:${NC}"
        local i=1
        for jail in $jails; do
            jail=$(echo "$jail" | xargs)
            if [ -n "$jail" ]; then
                # Получаем количество забаненных IP
                local banned=$(fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned" | grep -oE '[0-9]+' | head -1)
                if [ -z "$banned" ]; then
                    banned=0
                fi
                if [ "$banned" -gt 0 ]; then
                    echo -e "  ${GREEN}$i${NC}) ${BOLD}$jail${NC} ${RED}(забанено: $banned)${NC}"
                else
                    echo -e "  ${GREEN}$i${NC}) ${BOLD}$jail${NC} ${GREEN}(нет блокировок)${NC}"
                fi
                i=$((i+1))
            fi
        done
        echo ""
        echo -e "${BOLD}${CYAN}Действия:${NC}"
        echo -e "  ${BLUE}a${NC}) Показать статус всех jail"
        echo -e "  ${YELLOW}r${NC}) Обновить"
        echo -e "  ${RED}q${NC}) Выход"
        echo ""
        echo -ne "${CYAN}Выберите jail или действие:${NC} "
        read choice
        
        case $choice in
            a|A)
                show_all_jails
                echo ""
                read -p "Нажмите Enter для продолжения..."
                ;;
            r|R)
                # Просто обновим экран
                ;;
            q|Q|0)
                echo -e "${GREEN}Выход...${NC}"
                exit 0
                ;;
            *)
                # Проверяем, является ли выбор числом
                if [[ $choice =~ ^[0-9]+$ ]]; then
                    local jail_array=($jails)
                    local jail_index=$((choice-1))
                    if [ $jail_index -ge 0 ] && [ $jail_index -lt ${#jail_array[@]} ]; then
                        local selected_jail=$(echo "${jail_array[$jail_index]}" | xargs)
                        manage_ip_menu "$selected_jail"
                    else
                        echo -e "${RED}Неверный номер jail${NC}"
                        sleep 1
                    fi
                else
                    echo -e "${RED}Неверный выбор${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

# Запуск главного меню
main_menu
