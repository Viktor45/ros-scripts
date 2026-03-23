# 🛠️ ros-scripts

Набор полезных скриптов для MikroTik RouterOS.

English version: [README.md](README.md) | Русская версия: [README_ru.md](README_ru.md)

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![MikroTik](https://img.shields.io/badge/MikroTik-RouterOS%207.10+-blue.svg)](https://mikrotik.com)

---

## 📚 Содержание

- [Скрипты](#-скрипты)
- [Требования](#-требования)
- [Установка](#-установка)
- [Вклад в проект](#-вклад-в-проект)
- [Лицензия](#-лицензия)

---

## 📦 Скрипты

| Скрипт                                              | Описание                                       | Мин. версия ROS |
|-----------------------------------------------------|------------------------------------------------|-----------------|
| [**anomalyze**](#anomalyze)                         | Обнаружение и блокировка аномальных соединений | 7.20+           |
| [**asn-to-address-list**](#asn-to-address-list)     | Автообновление списков адресов по ASN          | 7.10+           |
| [**cloudflare-ddns**](#cloudflare-ddns)             | Динамическое обновление DNS Cloudflare         | 7.20+           |
| [**resolve-address-lists**](#resolve-address-lists) | DNS-резолвинг IP-адресов в комментариях        | 7.20+           |
| [**warp-finder**](#warp-finder)                     | Автоподбор рабочих эндпоинтов Cloudflare WARP  | 7.20+           |

---

### 🔍 anomalyze

**Обнаружение аномальных соединений и автоматическая блокировка**

Скрипт мониторит активные соединения и выявляет подозрительные паттерны: асимметричное количество пакетов (много исходящих, мало входящих). Полезно для защиты от сканирования портов, DoS-атак и тайм-аутов TLS handshake.

**Возможности:**
- 🎯 Умное обнаружение асимметричных соединений
- 🚫 Автоматическая блокировка по IP
- ✅ Поддержка allowlist для доверенных IP
- 🔒 Защита локальных адресов роутера
- 📊 Гибкое логирование (debug/info/warning/error)
- ⚡ Настройка порогов срабатывания

**Файлы:**
- [`anomalyze.rsc`](anomalyze/anomalyze.rsc) — основной скрипт
- [`README.md`](anomalyze/README.md) — подробная документация

**Быстрый старт:**
```routeros
# Скопировать скрипт в System → Scripts
# Запустить
/system script run connection-monitor
```

**Конфигурация:**
```routeros
:global cfgMonitoredPorts {443; 80; 8443}
:global cfgMinOrigPackets 3
:global cfgMaxReplPackets 2
:global cfgBlockTimeout "1d"
```

📖 [Полная документация →](anomalyze/README.md)

---

### 🌐 asn-to-address-list

**Автоматическое обновление списков адресов по номеру ASN**

Загружает актуальные списки IPv4/IPv6 префиксов для любого ASN с [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks) и добавляет их в firewall address-list.

**Возможности:**
- ✅ Автообновление из GitHub ipverse
- 🌐 Поддержка IPv4 и IPv6
- 🔢 Обработка нескольких ASN за один запуск
- 🔄 Умная очистка старых записей
- 💾 Гибкое хранилище (USB/disk/tmpfs)

**Файлы:**
- [`update-asn-prefixes.rsc`](asn-to-address-list/update-asn-prefixes.rsc) — основной скрипт
- [`update-asn-cleaner.rsc`](asn-to-address-list/update-asn-cleaner.rsc) — очистка списков
- [`update-asn-runner-example.rsc`](asn-to-address-list/update-asn-runner-example.rsc) — пример пакетного обновления
- [`README.md`](asn-to-address-list/README.md) — подробная документация

**Быстрый старт:**
```routeros
# Обновить Cloudflare IPv4
:global UAPASN "13335"
:global UAPLIST "cloudflare-v4"
/system script run update-asn-prefixes

# Несколько ASN за раз
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes
```

**Популярные ASN:**
| Компания | ASN | Описание |
|----------|-----|----------|
| Cloudflare | 13335 | CDN и безопасность |
| Google | 15169 | Инфраструктура Google |
| Amazon | 16509 | AWS |
| Microsoft | 8075 | Azure |
| Meta | 32934 | Facebook, Instagram |

📖 [Полная документация →](asn-to-address-list/README.md)

---

### ☁️ cloudflare-ddns

**Динамическое обновление DNS записей Cloudflare**

Автоматически обновляет A/AAAA записи в Cloudflare при изменении публичного IP вашего роутера. Поддержка IPv4 и IPv6.

**Возможности:**
- ✅ IPv4 и IPv6 поддержка
- 🌐 Несколько доменов одновременно
- 🔶 Переключатель Cloudflare Proxy (orange/gray cloud)
- ⚡ Проверка изменений IP перед обновлением
- 🔄 Автоматизация по расписанию

**Файлы:**
- [`cloudflare-ddns.rsc`](cloudflare-ddns/cloudflare-ddns.rsc) — основной скрипт
- [`README.md`](cloudflare-ddns/README.md) — подробная документация

**Быстрый старт:**
```routeros
# 1. Включить IP Cloud
/ip cloud set ddns-enabled=yes

# 2. Настроить скрипт (указать токен, Zone ID, Record ID)
# 3. Создать планировщик
/system scheduler add \
  name=cloudflare-ddns-update \
  on-event=cloudflare-ddns \
  interval=5m \
  start-time=startup
```

**Конфигурация доменов:**
```routeros
:local domains {
    "example.com,ZONE_ID,RECORD_ID,true,v4";
    "ipv6.example.com,ZONE_ID,RECORD_ID,false,v6"
}
```

📖 [Полная документация →](cloudflare-ddns/README.md)

---

### 🔄 resolve-address-lists

**DNS-резолвинг IP-адресов в firewall address-list**

Автоматически резолвит IP-адреса в указанных списках адресов и сохраняет hostname в комментариях для удобной идентификации.

**Возможности:**
- 🌐 Поддержка IPv4 и IPv6
- 🔧 Выбор DNS сервера (Cloudflare, Google, Quad9)
- 📝 Обновление только пустых комментариев
- ⚙️ Гибкая настройка списков для обработки

**Файлы:**
- [`resolve-address-lists.rsc`](resolve-address-lists/resolve-address-lists.rsc) — основной скрипт
- [`README.md`](resolve-address-lists/README.md) — подробная документация

**Быстрый старт:**
```routeros
# Настроить списки для резолвинга
:local dnsServer "1.1.1.1"
:local ipVersion "both"

:local ipv4ListsToResolve {
    "Trap";
    "MYDNS";
}

:local ipv6ListsToResolve {
    "Trap-v6";
    "MYDNS-v6";
}

# Запустить
/system script run resolve-address-lists
```

📖 [Полная документация →](resolve-address-lists/README.md)

---

### 📡 warp-finder

**Автоподбор рабочих эндпоинтов Cloudflare WARP**

Автоматически тестирует различные IP:port комбинации из инфраструктуры Cloudflare для нахождения рабочего WireGuard эндпоинта.

**Возможности:**
- 🔄 Автоматический перебор эндпоинтов
- 🎯 Случайная генерация IP:port
- 🏥 Проверка связи через ping
- 📊 Подробное логирование
- 🛡️ Безопасная работа с откатом

**Файлы:**
- [`warp-finder.rsc`](warp-finder/warp-finder.rsc) — основной скрипт
- [`warp-finder-mini.rsc`](warp-finder/warp-finder-mini.rsc) — облегченная версия
- [`README.md`](warp-finder/README.md) — подробная документация
- [`QUICKSTART.md`](warp-finder/QUICKSTART.md) — быстрый старт
- [`FAQ.md`](warp-finder/FAQ.md) — часто задаваемые вопросы
- [`CHANGELOG.md`](warp-finder/CHANGELOG.md) — история изменений

**Быстрый старт:**
```routeros
# Настроить интерфейс
:local wgInterface "cloudflare-interface"
:local maxAttempts 10

# Запустить
/import warp-finder.rsc
```

**Планировщик для автозапуска:**
```routeros
/system scheduler add \
  name="warp-finder" \
  interval=6h \
  on-event="/import warp-finder.rsc"
```

📖 [Полная документация →](warp-finder/README.md)

---

## 📋 Требования

| Скрипт                | Минимальная версия RouterOS |
|-----------------------|-----------------------------|
| anomalyze             | 7.20+                       |
| asn-to-address-list   | 7.10+                       |
| cloudflare-ddns       | 7.20+                       |
| resolve-address-lists | 7.20+                       |
| warp-finder           | 7.20+                       |

**Общие требования:**
- Административный доступ к роутеру
- Подключение к интернету
- Включенный пакет `system`

---

## 🚀 Установка

### Метод 1: Через WebFig/WinBox (рекомендуется)

1. Откройте **System → Scripts**
2. Нажмите **+** (Add New)
3. Укажите имя скрипта
4. Скопируйте содержимое `.rsc` файла в поле **Source**
5. Нажмите **OK**

### Метод 2: Через терминал/SSH

```bash
# Подключиться к роутеру
ssh admin@192.168.88.1

# Импортировать скрипт
/import имя-скрипта.rsc
```

### Метод 3: Загрузка файла

```bash
# Загрузить скрипт на роутер
scp скрипт.rsc admin@192.168.88.1:/

# Импортировать
ssh admin@192.168.88.1
/import скрипт.rsc
```

---

## 🤝 Вклад в проект

Приветствуются:
- 🐛 Отчеты об ошибках
- 💡 Предложения по улучшению
- 🔧 Pull Request'ы с исправлениями
- 📖 Улучшение документации

### Как внести вклад

1. Fork репозитория
2. Создайте ветку (`git checkout -b feature/улучшение`)
3. Внесите изменения
4. Протестируйте на RouterOS
5. Создайте Pull Request

---

## 📄 Лицензия

MIT License — подробности в файле [LICENSE](LICENSE)

---

## ⚠️ Отказ от ответственности

Скрипты предоставляются «как есть», без каких-либо гарантий. Используйте на свой страх и риск. Рекомендуется тестирование в непродакшен-среде перед развертыванием.

---

## 🔗 Полезные ссылки

- [MikroTik Wiki](https://wiki.mikrotik.com/)
- [MikroTik Forum](https://forum.mikrotik.com/)
- [RouterOS Scripting](https://help.mikrotik.com/docs/display/ROS/Scripting)
- [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- [Cloudflare API](https://api.cloudflare.com/)

---

<div align="center">

**Сделано с ❤️ для сообщества MikroTik**

[GitHub Issues](https://github.com/viktor45/ros-scripts/issues) • [Pull Requests](https://github.com/viktor45/ros-scripts/pulls)

</div>
