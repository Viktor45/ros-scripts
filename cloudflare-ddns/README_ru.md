# Скрипт Cloudflare DDNS для MikroTik

English version: [README.md](README.md) | Русская версия: [README_ru.md](README_ru.md)

Автоматическое обновление записей DNS Cloudflare при изменении публичного IP-адреса вашего роутера MikroTik. Поддержка как IPv4, так и IPv6.

## Возможности

- ✅ Поддержка IPv4 и IPv6
- ✅ Несколько доменов/поддоменов
- ✅ Переключатель прокси Cloudflare (оранжевое/серое облако)
- ✅ Эффективное обнаружение изменений IP
- ✅ Автоматические обновления API
- ✅ Совместимость с RouterOS 7.20+

## Предварительные требования

1. **Роутер MikroTik** с RouterOS 7.20 или новее
2. **Аккаунт Cloudflare** с:
   - Доменами, добавленными в Cloudflare
   - API-токеном с разрешениями на редактирование DNS
3. **Служба IP Cloud**, включенная на MikroTik

## Установка

### Шаг 1: Включите IP Cloud

```bash
/ip cloud set ddns-enabled=yes
```

### Шаг 2: Получите учетные данные API Cloudflare

1. Войдите в [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Перейдите в **My Profile** → **API Tokens**
3. Нажмите **Create Token**
4. Используйте шаблон **Edit zone DNS** или создайте пользовательский токен с:
   - Разрешениями: `Zone → DNS → Edit`
   - Ресурсами зоны: `Include → Specific zone → [Ваш домен]`
5. Скопируйте сгенерированный токен

### Шаг 3: Получите Zone ID и Record ID

#### Получение Zone ID:
1. Перейдите к вашему домену в Cloudflare Dashboard
2. Прокрутите вниз на странице **Overview**
3. Найдите **Zone ID** в правой боковой панели

#### Получение Record ID:
Используйте API Cloudflare или эту curl-команду:

```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

Найдите запись вашего домена в ответе и скопируйте её `id`.

### Шаг 4: Настройте скрипт

1. Откройте файл скрипта
2. Замените `CF_AUTH_TOKEN` на ваш фактический API-токен Cloudflare
3. Настройте ваши домены в массиве:

```routeros
:local domains {
    "example.com,zone_id,record_id,true,v4";
    "ipv6.example.com,zone_id,record_id,false,v6";
    "subdomain.example.com,zone_id,record_id,true,v4"
}
```

**Формат массива:** `"domain,zone_id,record_id,proxied,ip_version"`

- `domain`: Ваш домен/поддомен
- `zone_id`: Zone ID Cloudflare
- `record_id`: ID DNS-записи
- `proxied`: `true` (оранжевое облако) или `false` (серое облако)
- `ip_version`: `v4` для IPv4 или `v6` для IPv6

### Шаг 5: Добавьте скрипт в MikroTik

1. Скопируйте весь скрипт
2. В терминале MikroTik или WebFig/WinBox:
   - Перейдите в **System → Scripts**
   - Нажмите **Add New**
   - Имя: `cloudflare-ddns`
   - Вставьте скрипт
   - Нажмите **OK**

### Шаг 6: Создайте планировщик

```bash
/system scheduler add \
  name=cloudflare-ddns-update \
  on-event=cloudflare-ddns \
  interval=5m \
  start-time=startup
```

Это запускает скрипт каждые 5 минут и при запуске роутера.

## Примеры конфигурации

### Только IPv4
```routeros
:local domains {
    "home.example.com,abc123zone,xyz789record,true,v4"
}
```

### Только IPv6
```routeros
:local domains {
    "ipv6.example.com,abc123zone,xyz789record,false,v6"
}
```

### Несколько доменов (IPv4 и IPv6)
```routeros
:local domains {
    "example.com,abc123zone,rec1id,true,v4";
    "www.example.com,abc123zone,rec2id,true,v4";
    "ipv6.example.com,abc123zone,rec3id,false,v6";
    "*.example.com,abc123zone,rec4id,true,v4"
}
```

### Один домен — двойной стек (записи A + AAAA)
```routeros
:local domains {
    "example.com,abc123zone,ipv4_record_id,true,v4";
    "example.com,abc123zone,ipv6_record_id,true,v6"
}
```

## Проверка

### Проверка логов скрипта
```bash
/log print where topics~"script"
```

Вы должны увидеть сообщения типа:
```
✅ Updated example.com (A) → 203.0.113.45
✅ Updated ipv6.example.com (AAAA) → 2001:db8::1
```

### Ручной тестовый запуск
```bash
/system script run cloudflare-ddns
```

### Проверка глобальных переменных
```bash
/system script environment print
```

Ищите `lastCloudflareIPv4` и `lastCloudflareIPv6`.

## Диагностика

### Скрипт не запускается
- Проверьте, что планировщик включен: `/system scheduler print`
- Проверьте, работает ли IP Cloud: `/ip cloud print`

### Ошибки API
- Проверьте, что API-токен имеет правильные разрешения
- Проверьте, что Zone ID и Record ID верны
- Убедитесь, что токен не истек

### IPv6 не работает
- Проверьте, что IPv6 настроен на вашем роутере
- Проверьте, что IP Cloud имеет IPv6-адрес: `/ip cloud print`
- Убедитесь, что ваш провайдер предоставляет публичный IPv6

### Обновления не происходят
- IP мог не измениться
- Проверьте логи: `/log print where topics~"script"`
- Проверьте, что формат массива domains правильный

## Примечания по безопасности

⚠️ **Важно:** Ваш API-токен имеет разрешения на редактирование DNS. Храните его в безопасности!

- Не делитесь вашим скриптом с включенным токеном
- Используйте переменные окружения или отдельную конфигурацию при совместном использовании
- Регулярно обновляйте API-токены
- Используйте минимальные разрешения (только редактирование DNS для конкретных зон)

## Настройка

### Изменение интервала обновления
Измените интервал планировщика:
```bash
/system scheduler set cloudflare-ddns-update interval=10m
```

### Изменение TTL
Отредактируйте значение `ttl` в скрипте (по умолчанию 300 секунд):
```routeros
:local json ("{\"type\":\"" . $recordType . "\",\"name\":\"" . $domain . \
            "\",\"content\":\"" . $currentIP . \
            "\",\"ttl\":120,\"proxied\":" . $proxied . "}")
```

### Отключение задержки ограничения частоты
Удалите или настройте задержку между обновлениями:
```routeros
:delay 1s
```

## Удаление

```bash
/system scheduler remove cloudflare-ddns-update
/system script remove cloudflare-ddns
/system script environment remove lastCloudflareIPv4
/system script environment remove lastCloudflareIPv6
```

## Лицензия

Лицензия MIT — не стесняйтесь изменять и распространять

## Вклад в проект

Проблемы и pull request приветствуются!

## Благодарности

Создано для MikroTik RouterOS 7.20+ с интеграцией DNS Cloudflare
