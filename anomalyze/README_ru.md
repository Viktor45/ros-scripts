# 🛡️ Скрипт обнаружения и блокировки аномальных соединений MikroTik

English version: [README.md](README.md) | Русская версия: [README_ru.md](README_ru.md)

[![MikroTik](https://img.shields.io/badge/MikroTik-RouterOS%207.20+-blue.svg)](https://mikrotik.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](../LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/viktor45/mikrotik-connection-monitor/graphs/commit-activity)
[![Status](https://img.shields.io/badge/status-experimental-orange.svg)](https://github.com/viktor45/mikrotik-connection-monitor)

Надежный, настраиваемый скрипт MikroTik RouterOS, который автоматически обнаруживает и блокирует подозрительные сетевые соединения на основе асимметричных паттернов пакетов. Идеально подходит для предотвращения сканирования портов, тайм-аутов TLS handshake и других сетевых аномалий.

> **⚠️ ПРЕДУПРЕЖДЕНИЕ ОБ ЭКСПЕРИМЕНТАЛЬНОМ СТАТУСЕ**
> Этот скрипт находится в **экспериментальной стадии**. Несмотря на то, что он протестирован и работает как задумано, его следует развертывать с осторожностью:
> - **Сначала тестируйте в непродакшен-среде**
> - **Внимательно мониторьте логи** после первоначального развертывания
> - **Регулярно проверяйте заблокированные IP** на отсутствие ложных срабатываний
> - **Поддерживайте allowlist в актуальном состоянии** с вашими доверенными IP и сервисами
> - **Будьте готовы настроить пороги** в соответствии с поведением вашей сети
> - **Сделайте резервную копию конфигурации** перед внедрением
>
> Используйте на свой страх и риск. Авторы не несут ответственности за любые перебои в работе сети или непреднамеренную блокировку.

## 📋 Содержание

- [Возможности](#-возможности)
- [Принцип работы](#-принцип-работы)
- [Требования](#-требования)
- [Установка](#-установка)
- [Конфигурация](#-конфигурация)
- [Использование](#-использование)
- [Правила фаервола](#-правила-фаервола)
- [Мониторинг и логи](#-мониторинг-и-логи)
- [Диагностика](#-диагностика)
- [Производительность](#-производительность)
- [Вклад в проект](#-вклад-в-проект)
- [Лицензия](#-лицензия)

## ✨ Возможности

- **🎯 Умное обнаружение**: Идентифицирует соединения с асимметричным количеством пакетов (много исходящих, мало/нет входящих)
- **⚙️ Высокая настраиваемость**: Все параметры регулируются через глобальные переменные
- **🚫 Автоблокировка**: Автоматически добавляет подозрительные IP в address-list фаервола
- **✅ Поддержка allowlist**: Защита доверенных IP от блокировки
- **🔒 Защита локальных IP**: Предотвращает блокировку адресов вашего роутера
- **📊 Мультипротокольность**: Поддержка TCP, UDP и других протоколов
- **🎚️ Гранулярное логирование**: Настраиваемые уровни логов (debug, info, warning, error)
- **⚡ Оптимизация производительности**: Ограничение частоты и эффективная обработка соединений
- **🔄 Самовосстановление**: Автоматическое восстановление после ошибок с подробным логированием
- **📝 Подробные комментарии**: Отслеживание причин блокировки с информацией об источнике

## 🔍 Принцип работы

Скрипт мониторит активные соединения и выявляет подозрительные паттерны:

1. **Анализ соединений**: Сканирует соединения фаервола на асимметричное количество пакетов
2. **Обнаружение паттернов**: Помечает соединения с >3 исходящими пакетами, но ≤2 входящими
3. **Валидация**: Проверяет по allowlist, локальным адресам и отслеживаемым портам
4. **Автоблокировка**: Добавляет найденные IP в address-list с настраиваемым тайм-аутом
5. **Очистка**: Опционально удаляет TCP-соединения для освобождения ресурсов

**Типичные сценарии использования:**
- Обнаружение неудачных TLS handshake (таймауты порта 443)
- Выявление попыток сканирования портов
- Блокировка источников DoS/DDoS
- Противодействие атакам flood соединений

## 📦 Требования

- **MikroTik RouterOS**: Версия 7.20 или выше
- **Разрешения**: Доступ с политикой admin или script
- **Ресурсы**: Минимальные накладные расходы CPU/памяти (настраиваемо)

## 🚀 Установка

### Метод 1: Веб-интерфейс (WinBox/WebFig)

1. Откройте интерфейс вашего MikroTik роутера
2. Перейдите в **System → Scripts**
3. Нажмите **Add New** (+)
4. Установите следующие параметры:
   - **Name**: `connection-monitor`
   - **Policy**: `read, write, policy, test`
   - **Source**: Вставьте код скрипта
5. Нажмите **OK**

### Метод 2: Терминал/SSH

```bash
# Подключитесь к вашему роутеру
ssh admin@192.168.88.1

# Создайте скрипт (вставьте весь скрипт, затем Ctrl+D)
/system script add name=connection-monitor policy=read,write,policy,test source={
# Вставьте скрипт сюда
}

# Запустите скрипт
/system script run connection-monitor
```

### Метод 3: Планировщик (автозапуск)

Для автоматического запуска скрипта при старте роутера:

```routeros
/system scheduler add \
    name=connection-monitor-startup \
    on-event="/system script run connection-monitor" \
    start-time=startup \
    interval=0
```

## ⚙️ Конфигурация

Вся конфигурация выполняется через глобальные переменные в начале скрипта:

### Основные настройки

```routeros
:global cfgEnabled true                          # Включить/выключить скрипт
:global cfgMonitoredPorts {443; 80; 8443}       # Порты для мониторинга
:global cfgProtocols {"tcp"; "udp"}             # Протоколы для проверки
```

### Пороги обнаружения

```routeros
:global cfgMinOrigPackets 3                      # Мин. исходящих пакетов для срабатывания
:global cfgMaxReplPackets 2                      # Макс. допустимое количество входящих
```

### Блокировка и производительность

```routeros
:global cfgBlockTimeout "1d"                     # Длительность блокировки IP (1d, 12h, 30m)
:global cfgLoopDelay 2                           # Секунд между проверками
:global cfgMaxConnPerCycle 50                    # Макс. соединений за цикл
```

### Дополнительные опции

```routeros
:global cfgAddressList "tls_block"               # Имя blocking address-list
:global cfgAllowlistName "allowlist"             # Имя allowlist
:global cfgLogLevel "warning"                    # Уровень логирования: debug/info/warning/error
:global cfgRemoveTCPConn true                    # Удалять заблокированные TCP-соединения
:global cfgCheckLocalAddr true                   # Пропускать локальные IP роутера
```

### Примеры конфигурации

**Пример 1: Мониторинг HTTPS и SSH**
```routeros
:global cfgMonitoredPorts {443; 22; 8443}
:global cfgBlockTimeout "2d"
```

**Пример 2: Агрессивная блокировка**
```routeros
:global cfgMinOrigPackets 2
:global cfgMaxReplPackets 1
:global cfgBlockTimeout "7d"
```

**Пример 3: Режим отладки**
```routeros
:global cfgLogLevel "debug"
:global cfgLoopDelay 5
```

## 📖 Использование

### Запуск скрипта

```routeros
/system script run connection-monitor
```

### Остановка скрипта

```routeros
# Найти процесс скрипта
/system script job print

# Убить задачу (замените X на номер задачи)
/system script job remove X
```

### Создание allowlist

Предотвратите блокировку доверенных IP:

```routeros
/ip firewall address-list add list=allowlist address=8.8.8.8 comment="Google DNS"
/ip firewall address-list add list=allowlist address=1.1.1.1 comment="Cloudflare DNS"
/ip firewall address-list add list=allowlist address=192.168.1.100 comment="Доверенный сервер"
```

### Просмотр заблокированных IP

```routeros
/ip firewall address-list print where list=tls_block
```

### Ручное удаление заблокированного IP

```routeros
/ip firewall address-list remove [find where address=1.2.3.4 and list=tls_block]
```

### Очистка всех блокировок

```routeros
/ip firewall address-list remove [find where list=tls_block]
```

## 🔥 Правила фаервола

Скрипт только добавляет IP в address-list. Для фактической блокировки трафика нужны правила фаервола:

### Рекомендуемые правила

**Блокировка в Forward Chain** (для трафика через роутер):
```routeros
/ip firewall filter add \
    chain=forward \
    action=drop \
    src-address-list=tls_block \
    comment="Блокировка обнаруженных аномальных соединений" \
    place-before=0
```

**Блокировка в Input Chain** (для самого роутера):
```routeros
/ip firewall filter add \
    chain=input \
    action=drop \
    src-address-list=tls_block \
    comment="Блокировка атак на роутер" \
    place-before=0
```

**Логирование перед дропом** (опционально):
```routeros
/ip firewall filter add \
    chain=forward \
    action=log \
    src-address-list=tls_block \
    log-prefix="BLOCKED-ANOMALY" \
    place-before=0

/ip firewall filter add \
    chain=forward \
    action=drop \
    src-address-list=tls_block \
    place-before=1
```

## 📊 Мониторинг и логи

### Просмотр логов

```routeros
/log print where message~"ConnectionMonitor"
```

### Мониторинг логов в реальном времени

```routeros
/log print follow where message~"ConnectionMonitor"
```

### Пример вывода логов

```
warning: [ConnectionMonitor] Обнаружено асимметричное tcp соединение: 192.168.1.50:54321 -> 203.0.113.45:443 (orig>3, repl<=2)
info: [ConnectionMonitor] Добавлен 203.0.113.45 в tls_block (таймаут: 1d)
info: [ConnectionMonitor] Обработано 5 подозрительных соединений
```

### Статистика

Проверить количество заблокированных IP:

```routeros
:put [/ip firewall address-list print count-only where list=tls_block]
```

## 🔧 Диагностика

### Скрипт не запускается

**Проверьте существование скрипта:**
```routeros
/system script print
```

**Проверьте синтаксические ошибки:**
```routeros
/system script run connection-monitor
# Обратите внимание на сообщения об ошибках
```

**Проверьте планировщик (если используете автозапуск):**
```routeros
/system scheduler print
```

### IP не блокируются

**Проверьте уровень логирования:**
```routeros
:global cfgLogLevel "debug"
# Затем проверьте логи на наличие сообщений "Skipping"
```

**Проверьте отслеживаемые порты:**
```routeros
# Убедитесь, что трафик идет на порты из cfgMonitoredPorts
/ip firewall connection print where dst-port=443
```

**Проверьте пороги:**
```routeros
# Понизьте пороги для более чувствительного обнаружения
:global cfgMinOrigPackets 2
:global cfgMaxReplPackets 1
```

### Высокое использование CPU

**Увеличьте задержку цикла:**
```routeros
:global cfgLoopDelay 5
```

**Уменьшите макс. соединений:**
```routeros
:global cfgMaxConnPerCycle 20
```

**Измените уровень логирования:**
```routeros
:global cfgLogLevel "error"
```

### Блокировка легитимного трафика

**Добавьте в allowlist:**
```routeros
/ip firewall address-list add list=allowlist address=X.X.X.X
```

**Настройте пороги:**
```routeros
:global cfgMinOrigPackets 5
:global cfgMaxReplPackets 3
```

**Увеличьте тайм-аут блокировки:**
```routeros
:global cfgBlockTimeout "1h"  # Более короткий таймаут для тестирования
```

## ⚡ Производительность

### Влияние на ресурсы

| Соединения | Задержка цикла | Влияние на CPU        |
|------------|----------------|-----------------------|
| < 1000     | 2s             | Минимальное (~1-2%)   |
| 1000-5000  | 3s             | Низкое (~3-5%)        |
| 5000-10000 | 5s             | Среднее (~5-10%)      |
| > 10000    | 10s            | Требуется оптимизация |

### Советы по оптимизации

1. **Настройте задержку цикла**: Увеличьте `cfgLoopDelay` для загруженных роутеров
2. **Ограничьте мониторинг портов**: Мониторьте только критические порты
3. **Уменьшите макс. соединений**: Установите `cfgMaxConnPerCycle` в 20-30
4. **Используйте Warning/Error логи**: Избегайте debug логирования в продакшене
5. **Очищайте старые блокировки**: Более короткий `cfgBlockTimeout` уменьшает размер address-list

### Использование памяти

- **Базовый скрипт**: ~10-20 КБ
- **На заблокированный IP**: ~200 байт
- **1000 заблокированных IP**: ~200 КБ дополнительно

## 🤝 Вклад в проект

Вклад приветствуется! Не стесняйтесь отправлять Pull Request.

### Настройка разработки

1. Fork репозитория
2. Создайте ветку (`git checkout -b feature/amazing-feature`)
3. Тестируйте на MikroTik RouterOS 7.20+
4. Закоммитьте изменения (`git commit -m 'Add amazing feature'`)
5. Отправьте в ветку (`git push origin feature/amazing-feature`)
6. Откройте Pull Request

### Сообщение о проблемах

Пожалуйста, укажите:
- Версию RouterOS
- Конфигурацию скрипта (без чувствительных данных)
- Вывод логов
- Шаги для воспроизведения

## 📄 Лицензия

Этот проект лицензирован по лицензии MIT — подробности в файле [LICENSE](../LICENSE).

## 🙏 Благодарности

- MikroTik за возможности скриптинга RouterOS
- Участникам сообщества, тестировавшим и предоставившим обратную связь
- Оригинальное вдохновение от скриптов обнаружения TLS timeout

## 📞 Поддержка

- **Проблемы**: [GitHub Issues](https://github.com/viktor45/ros-scripts/issues)
- **Форум MikroTik**: [forum.mikrotik.com](https://forum.mikrotik.com)

---

**⭐ Если этот скрипт помогает защитить вашу сеть, пожалуйста, добавьте звезду этому репозиторию!**

Сделано с ❤️ для сообщества MikroTik
