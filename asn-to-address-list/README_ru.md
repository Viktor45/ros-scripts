# Обновление префиксов ASN для MikroTik

English version: [README.md](README.md) | Русская версия: [README_ru.md](README_ru.md)

Надежный набор скриптов RouterOS, который автоматически загружает и обновляет списки адресов фаервола префиксами IPv4/IPv6 для любого номера автономной системы (ASN). Идеально подходит для блокировки, маршрутизации или мониторинга трафика от определенных сетей.

<!-- TOC -->
* [Обновление префиксов ASN для MikroTik](#обновление-префиксов-asn-для-mikrotik)
  * [Входящие скрипты](#входящие-скрипты)
  * [Возможности](#возможности)
  * [Требования](#требования)
  * [Установка](#установка)
    * [Основной скрипт](#основной-скрипт)
    * [Вспомогательные скрипты (опционально)](#вспомогательные-скрипты-опционально)
    * [Настройка хранилища](#настройка-хранилища)
  * [Конфигурация — основной скрипт (update-asn-prefixes)](#конфигурация--основной-скрипт-update-asn-prefixes)
  * [Использование](#использование)
    * [Основной скрипт — базовые примеры](#основной-скрипт--базовые-примеры)
    * [Базовый пример IPv4](#базовый-пример-ipv4)
    * [Пример IPv6](#пример-ipv6)
    * [Пользовательский путь хранилища](#пользовательский-путь-хранилища)
    * [Несколько ASN (новое в v2.0)](#несколько-asn-новое-в-v20)
    * [Скрипт очистки — примеры использования](#скрипт-очистки--примеры-использования)
    * [Runner-скрипт — пакетные обновления](#runner-скрипт--пакетные-обновления)
    * [Запланированные обновления](#запланированные-обновления)
  * [Сценарии использования](#сценарии-использования)
    * [Блокировка трафика от конкретного ASN](#блокировка-трафика-от-конкретного-asn)
    * [Разрешение трафика только от конкретного ASN](#разрешение-трафика-только-от-конкретного-asn)
    * [Мониторинг трафика в сети CDN](#мониторинг-трафика-в-сети-cdn)
    * [Приоритизация трафика для конкретных сетей](#приоритизация-трафика-для-конкретных-сетей)
  * [Примеры полного рабочего процесса](#примеры-полного-рабочего-процесса)
    * [Пример 1: Управление IP хостинг-провайдеров](#пример-1-управление-ip-хостинг-провайдеров)
    * [Пример 2: Ротация списков ASN](#пример-2-ротация-списков-asn)
    * [Пример 3: Временная блокировка ASN](#пример-3-временная-блокировка-asn)
  * [Популярные номера ASN](#популярные-номера-asn)
  * [Пример вывода](#пример-вывода)
  * [Диагностика](#диагностика)
    * [Ошибка "Processing failed"](#ошибка-processing-failed)
    * [Скрипт не обновляется](#скрипт-не-обновляется)
    * [Проблемы с разрешениями временных файлов](#проблемы-с-разрешениями-временных-файлов)
    * [Проблемы со скриптом очистки](#проблемы-со-скриптом-очистки)
  * [Расширенная конфигурация](#расширенная-конфигурация)
    * [Использование RAM-диска (tmpfs) для лучшей производительности](#использование-ram-диска-tmpfs-для-лучшей-производительности)
    * [Несколько ASN в одном списке](#несколько-asn-в-одном-списке)
    * [Очистка старых временных файлов](#очистка-старых-временных-файлов)
    * [Просмотр текущих записей ASN](#просмотр-текущих-записей-asn)
    * [Аварийная очистка](#аварийная-очистка)
  * [Лицензия](#лицензия)
  * [Благодарности](#благодарности)
  * [Вклад в проект](#вклад-в-проект)
  * [Журнал изменений](#журнал-изменений)
    * [Версия 2.0.1 (2026-01-18)](#версия-201-2026-01-18)
    * [Версия 1.4.0 (2026-01-18)](#версия-140-2026-01-18)
    * [Версия 1.3.1 (2026-01-18)](#версия-131-2026-01-18)
    * [Версия 1.2.0 (2026-01-18)](#версия-120-2026-01-18)
    * [Версия 1.0.0 (2026-01-18)](#версия-100-2026-01-18)
<!-- TOC -->

## Входящие скрипты

- **update-asn-prefixes.rsc** — основной скрипт для загрузки и обновления префиксов ASN
- **update-asn-cleaner.rsc** — утилита для удаления записей ASN из списков адресов
- **update-asn-runner-example.rsc** — пример обертки для пакетного обновления (хостинг-провайдеры)

## Возможности

- ✅ **Автоматические обновления** — загрузка актуальных списков префиксов из [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- 🌐 **Поддержка IPv4 и IPv6** — обработка обеих версий протокола
- 🔢 **Несколько ASN** — обработка нескольких ASN за один запуск (через запятую)
- 🔄 **Умное обновление** — удаление старых записей перед добавлением новых
- 💾 **Настраиваемое хранилище** — использование USB, диска или RAM-диска (tmpfs) для временных файлов
- 📝 **Чистое логирование** — минимальный информативный вывод с прогрессом по каждому ASN
- ⚡ **Быстро и надежно** — оптимизировано для RouterOS 7.10+

## Требования

- MikroTik RouterOS **7.10 или новее**
- Подключение к интернету
- Место для хранения временных файлов (рекомендуется USB/диск)

## Установка

### Основной скрипт

1. **Создайте основной скрипт** в System > Scripts
   - Имя: `update-asn-prefixes`
   - Скопируйте все содержимое скрипта из [update-asn-prefixes.rsc](./update-asn-prefixes.rsc)

### Вспомогательные скрипты (опционально)

1. **Создайте скрипт очистки** (опционально, но рекомендуется)
   - Имя: `update-asn-cleaner`
   - Скопируйте все содержимое скрипта из [update-asn-cleaner.rsc](./update-asn-cleaner.rsc)

2. **Создайте пример runner-скрипта** (опционально — для пакетных обновлений)
   - Имя: `update-asn-runner-example`
   - Скопируйте все содержимое скрипта из [update-asn-runner-example.rsc](./update-asn-runner-example.rsc)
   - Настройте список ASN под ваши нужды

### Настройка хранилища

1. **Настройте временное хранилище** (выберите один вариант):

   **Вариант A: Использование USB/диска (рекомендуется для запланированных обновлений)**
   ```routeros
   # Проверьте, что ваш USB/диск смонтирован
   /file print
   # Ищите usb1, disk1 и т.д.
   ```

   **Вариант B: Использование RAM-диска (tmpfs) для временных файлов**

   RAM-диск быстрее и уменьшает износ USB/диска, идеально для частых обновлений:

   ```routeros
   # Создайте tmpfs RAM-диск (подставьте доступный размер RAM)
   /disk add slot=tmpfs type=tmpfs tmpfs-max-size=10M

   # Проверьте создание
   /disk print

   # tmpfs диск появится как "tmpfs1"
   # Используйте его в конфигурации скрипта:
   :global UAPTMPPATH "tmpfs1/"
   ```

   **Примечание:** Содержимое RAM-диска теряется при перезагрузке, но временные файлы автоматически очищаются скриптом.

2. **Настройте глобальные переменные** (см. Конфигурацию ниже)

3. **Запустите вручную или запланируйте** (см. Использование ниже)

---

## Конфигурация — основной скрипт (update-asn-prefixes)

Скрипт использует глобальные переменные для конфигурации:

| Переменная   | Обязательна | Описание                                              | Пример                    |
|--------------|-------------|-------------------------------------------------------|---------------------------|
| `UAPASN`     | ✅ Да        | Номер ASN (с префиксом "AS" или без)                  | `"13335"` или `"AS13335"` |
| `UAPLIST`    | ✅ Да        | Имя списка адресов фаервола                           | `"cloudflare-ips"`        |
| `UAPTYPE`    | ❌ Нет       | Версия IP: `"v4"` или `"v6"` (по умолчанию: `"v4"`)   | `"v4"`                    |
| `UAPTMPPATH` | ❌ Нет       | Путь к временным файлам (по умолчанию: `"usb1/tmp/"`) | `"disk1/tmp/"`            |

## Использование

### Основной скрипт — базовые примеры

### Базовый пример IPv4

```routeros
:global UAPASN "13335"
:global UAPLIST "cloudflare-v4"
/system script run update-asn-prefixes
```

### Пример IPv6

```routeros
:global UAPASN "13335"
:global UAPLIST "cloudflare-v6"
:global UAPTYPE "v6"
/system script run update-asn-prefixes
```

### Пользовательский путь хранилища

**Использование дискового хранилища:**
```routeros
:global UAPASN "15169"
:global UAPLIST "google-ips"
:global UAPTMPPATH "disk1/temp/"
/system script run update-asn-prefixes
```

**Использование RAM-диска (tmpfs):**
```routeros
:global UAPASN "15169"
:global UAPLIST "google-ips"
:global UAPTMPPATH "tmpfs1/"
/system script run update-asn-prefixes
```

### Несколько ASN (новое в v2.0)

**Обработка нескольких ASN за один запуск:**
```routeros
:global UAPASN "174,8560,13335"
:global UAPLIST "multiple-providers"
/system script run update-asn-prefixes
```

**С пробелами (также поддерживается):**
```routeros
:global UAPASN "13335, 16509, 15169"
:global UAPLIST "major-cdn-networks"
/system script run update-asn-prefixes
```

**Смешанный формат (префикс AS опционален):**
```routeros
:global UAPASN "AS174,8560,AS13335"
:global UAPLIST "transit-providers"
/system script run update-asn-prefixes
```

---

### Скрипт очистки — примеры использования

**Очистка конкретного ASN из конкретного списка:**
```routeros
:global UAPASN "13335"
:global UAPLIST "cloudflare-ips"
/system script run update-asn-cleaner
```

**Очистка нескольких ASN из конкретного списка:**
```routeros
:global UAPASN "174,8560,13335"
:global UAPLIST "hosters"
/system script run update-asn-cleaner
```

**Очистка конкретных ASN из ВСЕХ списков:**
```routeros
:global UAPASN "13335,16509"
# Не устанавливайте UAPLIST
/system script run update-asn-cleaner
```

**Очистка ВСЕХ записей ASN из конкретного списка:**
```routeros
# Не устанавливайте UAPASN
:global UAPLIST "hosters"
/system script run update-asn-cleaner
```

**Очистка ВСЕХ записей ASN из ВСЕХ списков:**
```routeros
# Не устанавливайте ни одну переменную
/system script run update-asn-cleaner
```

---

### Runner-скрипт — пакетные обновления

Пример runner-скрипта (`update-asn-runner-example.rsc`) демонстрирует пакетное обновление для хостинг-провайдеров:

**Запуск примера (обновляет 47 ASN хостинг-провайдеров):**
```routeros
/system script run update-asn-runner-example
```

**Настройка под ваши нужды:**
Отредактируйте скрипт и измените список ASN:
```routeros
# Пример: Обновлять только основных CDN-провайдеров
:local hosterASNs "13335,16509,15169"
```

**Запланировать пакетные обновления:**
```routeros
/system scheduler add \
    name=update-hosters-daily \
    start-time=02:00:00 \
    interval=1d \
    on-event="/system script run update-asn-runner-example" \
    comment="Ежедневное обновление IP хостинг-провайдеров"
```

---

### Запланированные обновления

Обновлять IP Cloudflare ежедневно в 3 утра:

```routeros
/system scheduler add \
    name=update-cloudflare-ips \
    start-time=03:00:00 \
    interval=1d \
    on-event="/system script run update-asn-prefixes" \
    comment="Ежедневное обновление IP Cloudflare"
```

**Примечание:** Установите глобальные переменные перед добавлением планировщика или включите их в `on-event` планировщика:

```routeros
/system scheduler add \
    name=update-cloudflare-ips \
    start-time=03:00:00 \
    interval=1d \
    on-event=":global UAPASN \"13335\"; :global UAPLIST \"cloudflare-v4\"; /system script run update-asn-prefixes" \
    comment="Ежедневное обновление IPv4 Cloudflare"
```

---

## Сценарии использования

### Блокировка трафика от конкретного ASN

```routeros
# Обновить список
:global UAPASN "12345"
:global UAPLIST "blocked-asn"
/system script run update-asn-prefixes

# Добавить правило фаервола для блокировки
/ip firewall filter add \
    chain=input \
    src-address-list=blocked-asn \
    action=drop \
    comment="Блокировка ASN 12345"
```

### Разрешение трафика только от конкретного ASN

```routeros
# Обновить список
:global UAPASN "13335"
:global UAPLIST "allowed-asn"
/system script run update-asn-prefixes

# Добавить правило фаервола для разрешения
/ip firewall filter add \
    chain=forward \
    src-address-list=allowed-asn \
    action=accept \
    comment="Разрешить ASN 13335"
```

### Мониторинг трафика в сети CDN

**Использование нескольких ASN в одном списке (рекомендуется):**
```routeros
# Обновить все сети CDN за раз
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes

# Добавить mangle-правило для маркировки трафика
/ip firewall mangle add \
    chain=forward \
    dst-address-list=cdn-networks \
    action=mark-connection \
    new-connection-mark=cdn-traffic \
    comment="Маркировка трафика CDN"
```

**Или использование отдельных списков:**
```routeros
# Обновить списки для отдельных CDN
:global UAPASN "13335"; :global UAPLIST "cdn-cloudflare"; /system script run update-asn-prefixes
:global UAPASN "16509"; :global UAPLIST "cdn-amazon"; /system script run update-asn-prefixes
:global UAPASN "15169"; :global UAPLIST "cdn-google"; /system script run update-asn-prefixes
```

### Приоритизация трафика для конкретных сетей

```routeros
# Обновить список
:global UAPASN "13335"
:global UAPLIST "priority-network"
/system script run update-asn-prefixes

# Маркировать пакеты для QoS
/ip firewall mangle add \
    chain=forward \
    dst-address-list=priority-network \
    action=mark-packet \
    new-packet-mark=priority \
    comment="Приоритетный трафик для ASN 13335"

# Применить очередь с приоритетом
/queue simple add \
    name=priority-queue \
    packet-marks=priority \
    priority=1/1 \
    comment="Приоритетная очередь для маркированного трафика"
```

---

## Примеры полного рабочего процесса

### Пример 1: Управление IP хостинг-провайдеров

**Шаг 1 — Начальная настройка:**
```routeros
# Запустить пример скрипта для заполнения списка
/system script run update-asn-runner-example
```

**Шаг 2 — Блокировка хостинг-провайдеров:**
```routeros
/ip firewall filter add \
    chain=input \
    src-address-list=hosters \
    action=drop \
    comment="Блокировка хостинг-провайдеров"
```

**Шаг 3 — Запланировать еженедельные обновления:**
```routeros
/system scheduler add \
    name=update-hosters-weekly \
    start-time=03:00:00 \
    interval=7d \
    on-event="/system script run update-asn-runner-example"
```

**Шаг 4 — Очистка при необходимости:**
```routeros
# Удалить конкретный ASN
:global UAPASN "13335"
:global UAPLIST "hosters"
/system script run update-asn-cleaner

# Или удалить все хостинг-провайдеры
:global UAPLIST "hosters"
/system script run update-asn-cleaner
```

### Пример 2: Ротация списков ASN

**Заменить старые ASN на новые:**
```routeros
# Очистить старый список
:global UAPLIST "cdn-networks"
/system script run update-asn-cleaner

# Обновить новыми ASN
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes
```

### Пример 3: Временная блокировка ASN

**Добавить временную блокировку:**
```routeros
# Добавить ASN в список блокировки
:global UAPASN "12345"
:global UAPLIST "temp-block"
/system script run update-asn-prefixes

# Создать правило фаервола
/ip firewall filter add \
    chain=input \
    src-address-list=temp-block \
    action=drop \
    comment="Временная блокировка"
```

**Удалить, когда больше не нужно:**
```routeros
# Очистить ASN
:global UAPASN "12345"
:global UAPLIST "temp-block"
/system script run update-asn-cleaner

# Удалить правило фаервола
/ip firewall filter remove [find comment="Временная блокировка"]
```

---

## Популярные номера ASN

| Компания        | ASN   | Описание                          |
|-----------------|-------|-----------------------------------|
| Cloudflare      | 13335 | CDN и сервисы безопасности        |
| Google          | 15169 | Сервисы и инфраструктура Google   |
| Amazon          | 16509 | AWS и сервисы Amazon              |
| Microsoft       | 8075  | Azure и сервисы Microsoft         |
| Facebook/Meta   | 32934 | Facebook, Instagram, WhatsApp     |
| Akamai          | 20940 | CDN и облачные сервисы            |
| Netflix         | 2906  | Стриминговые сервисы              |

Больше ASN можно найти на [bgp.he.net](https://bgp.he.net/)

## Пример вывода

**Один ASN:**
```
update-asn-prefixes: Processing 1 ASN(s)
update-asn-prefixes: AS13335 - Added 777 v4 prefixes
update-asn-prefixes: SUCCESS - Total 777 v4 prefixes added for 1 ASN(s)
```

**Несколько ASN:**
```
update-asn-prefixes: Processing 3 ASN(s)
update-asn-prefixes: AS13335 - Added 777 v4 prefixes
update-asn-prefixes: AS16509 - Added 1234 v4 prefixes
update-asn-prefixes: AS15169 - Added 892 v4 prefixes
update-asn-prefixes: SUCCESS - Total 2903 v4 prefixes added for 3 ASN(s)
```

**Вывод очистителя:**
```
clean-asns: Removing entries for 1 ASN(s)
clean-asns: AS13335 - Removed 777 entries
clean-asns: SUCCESS - Removed 777 total entries
```

**Вывод runner:**
```
update-hoster-asns: Starting update for hosting providers
update-asn-prefixes: Processing 47 ASN(s)
update-asn-prefixes: AS174 - Added 234 v4 prefixes
update-asn-prefixes: AS8560 - Added 156 v4 prefixes
[... продолжается для всех 47 ASN ...]
update-asn-prefixes: SUCCESS - Total 12543 v4 prefixes added for 47 ASN(s)
update-hoster-asns: Update completed
```

---

## Диагностика

### Ошибка "Processing failed"

- **Проверьте подключение к интернету**: Убедитесь, что роутер может достичь `raw.githubusercontent.com`
- **Проверьте существование ASN**: Посетите `https://github.com/ipverse/as-ip-blocks/tree/master/as/[ВАШ_ASN]`
- **Проверьте путь хранилища**: Убедитесь, что временный путь существует и доступен для записи

### Скрипт не обновляется

- **Проверьте установку глобальных переменных**: `/system script environment print`
- **Проверьте логи**: `/log print where topics~"script"`
- **Протестируйте вручную**: Запустите скрипт из терминала для немедленного вывода

### Проблемы с разрешениями временных файлов

- **Измените место хранения**: Используйте `UAPTMPPATH` для указания доступного для записи места
- **Используйте RAM-диск**: Создайте tmpfs для надежного временного хранения: `/disk add slot=tmpfs type=tmpfs tmpfs-max-size=10M`
- **Создайте директорию**: `/file print` для проверки существования пути
- **Проверьте место на диске**: Убедитесь, что доступно достаточно места на вашем устройстве хранения

### Проблемы со скриптом очистки

**"No entries found" для существующего ASN:**
- **Проверьте формат комментария**: Проверьте, имеют ли записи формат комментария "ASN AS####"
- **Проверьте имя списка**: Убедитесь, что `UAPLIST` совпадает со списком, содержащим записи
- **Просмотрите существующие записи**: `/ip firewall address-list print where comment~"ASN"`

**Случайное удаление:**
- Скрипт очистки не запрашивает подтверждение — будьте осторожны!
- Всегда проверяйте с установленным `UAPASN` перед запуском без него

---

## Расширенная конфигурация

### Использование RAM-диска (tmpfs) для лучшей производительности

Для роутеров с достаточным объемом RAM использование tmpfs обеспечивает более быстрые файловые операции и уменьшает износ физического хранилища:

```routeros
# Создать tmpfs подходящего размера (настройте по вашим нуждам)
# 10МБ обычно достаточно для нескольких списков ASN
/disk add slot=tmpfs type=tmpfs tmpfs-max-size=10M

# Проверить создание
/disk print

# Установить как путь по умолчанию
:global UAPTMPPATH "tmpfs1/"

# Теперь запускайте обновления как обычно
:global UAPASN "13335"
:global UAPLIST "cloudflare-v4"
/system script run update-asn-prefixes
```

**Преимущества:**
- ✅ Более быстрые операции чтения/записи
- ✅ Износ USB/диска отсутствует
- ✅ Автоматическая очистка при перезагрузке
- ✅ Подходит для частых запланированных обновлений

**Недостатки:**
- ❌ Использует RAM роутера (убедитесь в достаточном объеме свободной памяти)
- ❌ Содержимое теряется при перезагрузке (не проблема для временных файлов)

### Несколько ASN в одном списке

**Теперь встроено! Просто используйте ASN через запятую:**

```routeros
# Одна команда для нескольких ASN
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes
```

Каждый ASN получит собственный тег комментария (например, "ASN AS13335", "ASN AS16509"), что позволит удалять отдельные ASN позже при необходимости.

**Устаревший метод (все еще работает):**
```routeros
# Создать обертку-скрипт
:global UAPLIST "cdn-networks"

:global UAPASN "13335"
/system script run update-asn-prefixes

:global UAPASN "16509"
/system script run update-asn-prefixes

:global UAPASN "15169"
/system script run update-asn-prefixes
```

### Очистка старых временных файлов

```routeros
/file remove [find name~"^asn-.*\\.txt\$"]
```

### Просмотр текущих записей ASN

**Список всех записей ASN:**
```routeros
/ip firewall address-list print where comment~"^ASN AS"
```

**Подсчет записей на ASN:**
```routeros
# IPv4
:foreach entry in=[/ip firewall address-list find comment~"^ASN AS"] do={
    :local comment [/ip firewall address-list get $entry comment]
    :put $comment
}

# IPv6
:foreach entry in=[/ipv6 firewall address-list find comment~"^ASN AS"] do={
    :local comment [/ipv6 firewall address-list get $entry comment]
    :put $comment
}
```

### Аварийная очистка

**Удалить ВСЕ записи ASN немедленно:**
```routeros
/system script run update-asn-cleaner
```

**Удалить все временные файлы:**
```routeros
/file remove [find name~"asn-"]
```

---

## Лицензия

Лицензия MIT — не стесняйтесь использовать и изменять

## Благодарности

- Данные ASN предоставлены [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- Поддерживается для сообщества MikroTik RouterOS

## Вклад в проект

Проблемы, улучшения и pull request приветствуются!

## Журнал изменений

### Версия 2.0.1 (2026-01-18)
- **Основной скрипт**: Добавлена поддержка нескольких ASN за один запуск (через запятую)
- **Основной скрипт**: Улучшено логирование с отслеживанием прогресса по каждому ASN
- **Основной скрипт**: Добавлена задержка ограничения частоты между обработкой ASN
- **Основной скрипт**: Улучшена обработка ошибок для невалидных ASN
- **Основной скрипт**: Каждый ASN получает индивидуальный тег комментария для удобного управления
- **Новое**: Добавлен скрипт очистки (update-asn-cleaner.rsc)
- **Новое**: Добавлен пример runner-скрипта (update-asn-runner-example.rsc)

### Версия 1.4.0 (2026-01-18)
- Добавлена поддержка IPv6 через переменную `UAPTYPE`
- Улучшен именование временных файлов с суффиксом типа IP
- Улучшены сообщения об успехе

### Версия 1.3.1 (2026-01-18)
- Удален ненужный отладочный вывод
- Более чистые сообщения логов

### Версия 1.2.0 (2026-01-18)
- Переключено на ручной парсинг строк для лучшей совместимости
- Исправлены проблемы десериализации со строками комментариев

### Версия 1.0.0 (2026-01-18)
- Первоначальный релиз
- Поддержка IPv4
- Настраиваемый путь хранилища
