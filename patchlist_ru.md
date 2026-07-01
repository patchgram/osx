# Список патчей Patchgram

Здесь простым языком описано, какие патчи есть в Patchgram и что они делают.

## Типы патчей

| Тип | Что это значит | Когда используется |
| --- | --- | --- |
| `dylib` | Patchgram ставит локальную runtime-библиотеку в Telegram Desktop и меняет поведение во время работы клиента. | Визуальные патчи, настраиваемые значения и функции, которые удобнее обновлять без постоянной перезаписи большого количества байтов в клиенте. |
| `binary` | Patchgram меняет найденные byte-паттерны прямо в исполняемом файле Telegram Desktop. | Патчи запросов, constructor id и локальных проверок, которые проще и стабильнее менять напрямую в бинаре. |

> Большинство патчей работают только локально на клиенте. Они меняют то, что Telegram Desktop отправляет, блокирует или показывает у тебя. Они не меняют серверные данные аккаунта Telegram.

## Патчи

Главный экран Patchgram группирует патчи по пяти разделам — **Accounts**, **Messages**, **Optimizations**, **Gifts** и **Misc**. Каждый патч ниже указан в том разделе, в котором он находится.

### Accounts

| Патч | Тип | Что делает |
| --- | --- | --- |
| Always offline | `dylib` | Держит аккаунт оффлайн, принудительно отправляя запрос `account.updateStatus` как offline. |
| 999 accounts | `binary` | Поднимает локальный лимит аккаунтов с 6 до 999. |
| Custom account settings | `dylib` | Общий патч локальной кастомизации аккаунта (баланс, бейдж, верификация, идентичность, привязанный канал, Fragment phone, кастомные юзернеймы, заморозка аккаунта). |
| Block typing activity | `dylib` | Не даёт Telegram Desktop отправлять статус "печатает". |
| Don't share phone when adding contacts | `dylib` | Не отправляет исключение приватности номера при добавлении контакта. |

### Messages

| Патч | Тип | Что делает |
| --- | --- | --- |
| Message settings | `dylib` | Группирует подпатчи приватности сообщений: печать, прочтения, локальные черновики, scheduled send, кастомный Fact Check, защита копирования/сохранения и TTL. |
| Hide blocked users' messages | `dylib` | Скрывает сообщения от людей из твоего чёрного списка (заблокированных). Срабатывает сразу, как только ты кого-то блокируешь/разблокируешь. |
| Show bot callback-data on hover | `dylib` | Показывает callback-data inline-кнопок бота локально при наведении/копировании. |
| Sensitive blur | `dylib` | Отключает локальный блюр sensitive-контента. |
| Open links without warning | `dylib` | Открывает скрытые/внешние ссылки напрямую, без предупреждения Telegram. |
| Disable media spoilers | `dylib` | Показывает фото и видео со спойлером как обычно. |
| Block read messages | `dylib` | Блокирует запросы прочтения истории, чтобы сообщения не отмечались прочитанными через пропатченный путь. |
| More recent stickers | `dylib` | Поднимает лимит панели недавних стикеров с 20 до 200. |

### Optimizations

| Патч | Тип | Что делает |
| --- | --- | --- |
| Disable Premium, Stars, TON & Gifts | `dylib` | Отключает Premium, Stars, TON, Gifts, boosts и связанные с монетизацией UI/запросы во время работы. |
| Disable premium effects | `dylib` | Останавливает Premium-анимации стикеров/эффектов локально. |
| Hide stories | `dylib` | Скрывает stories локально и блокирует запросы получения/прочтения/просмотра stories. |
| Disable ads | `dylib` | Отключает Telegram Ads и промо от proxy sponsor. |

### Gifts

| Патч | Тип | Что делает |
| --- | --- | --- |
| Spoof profile gifts | `dylib` | Переписывает звёздные подарки в профиле — отправитель, дата, id подарка, цена в Stars и другое. |
| Show hidden gifts | `dylib` | Локально добавляет дополнительные звёздные подарки в меню покупки. |
| Spoof profile unique gifts | `dylib` | Показывает подарок в профиле как улучшенный (уникальный) с выбранными названием, номером, моделью, символом и фоном. |
| Fake transfer | `dylib` | Делает подменённый подарок передаваемым и фейкает передачу локальным сервисным сообщением. Требует Spoof profile unique gifts. |

### Misc

| Патч | Тип | Что делает |
| --- | --- | --- |
| Dylib injection | `dylib` | Инжектит Patchgram.dylib в Telegram через лаунчер `DYLD_INSERT_LIBRARIES` — базовый хук, через который грузятся все runtime-патчи. |
| Profile rain overlay | `dylib` | «Дождём» роняет выбранную картинку или анимированный стикер поверх открытого профиля, рисуется нативно самой dylib. |
| MTProto request/response logger | `dylib` | Логирует каждый MTProto-запрос и ответ (полностью декоднутый TL, с отметкой времени) в лог-файлы рядом с Telegram. |

## Подпатчи Message Settings

| Подпатч | Что делает |
| --- | --- |
| Typing activity | Не отправляет индикатор "печатает". |
| Read receipts | Не отправляет запросы прочтения через пропатченные пути. |
| Local drafts | Оставляет черновики локальными, блокируя синхронизацию drafts. |
| Scheduled send | Включает runtime-флаг Patchgram для локальной отложенной отправки. |
| Custom Fact Check | Подменяет ответы `messages.getFactCheck` на твой текст Fact Check. |
| Copy/save protect content | Локально сбрасывает `noforwards`, чтобы копировать текст и сохранять медиа из чатов с запретом сохранения. |
| Disable TTL | Локально обнуляет таймеры самоуничтожения и автоудаления. |

## Подпатчи Disable Premium, Stars, TON & Gifts

| Подпатч | Что делает |
| --- | --- |
| App config | Блокирует запрос monetization app config. |
| Premium UI | Локально скрывает или отключает Premium-разделы в интерфейсе. |
| Gifts | Локально скрывает или блокирует действия, связанные с подарками. |
| Paid reactions | Локально блокирует paid reactions: доступность, отправку и обработку. |
| Emoji statuses and effects | Локально скрывает или блокирует emoji statuses и связанные Premium-эффекты. |
| Stars, TON and collectibles | Локально скрывает или блокирует Stars, TON и collectible-разделы монетизации. |
| Boosts | Локально скрывает или отключает boost-действия. |
| Read receipts fix | Сохраняет корректное поведение меню "кто прочитал" вместе с monetization-патчем. |

## Подпатчи Custom Account Settings

| Подпатч | Что делает |
| --- | --- |
| Custom Stars | Локально переопределяет отображаемый баланс Stars. |
| Custom TON | Локально переопределяет отображаемый баланс TON. |
| Custom level rating | Переопределяет локальный level/rating Stars для выбранных пользователей. |
| Visual peer badge | Добавляет локальный бейдж Verified, Scam или Fake выбранным пирам. |
| Bot verification | Добавляет локальную bot verification выбранным пирам. |
| Local Telegram Premium | Заставляет клиент считать Premium локально доступным для UI-проверок. |
| Custom phone number | Локально заменяет твой номер телефона. |
| Custom userID | Локально заменяет твой отображаемый userID. |
| Local attached channel | Локально прикрепляет канал к твоему профилю по id. |
| Fragment phone | Делает твой номер коллекционным (Fragment) с локальными значениями `collectibleInfo`. |
| Custom list usernames | Заменяет список юзернеймов в твоём профиле с локальной Fragment collectible info. |

## Подпатчи Disable Ads

| Подпатч | Что делает |
| --- | --- |
| Telegram Ads | Блокирует пути запросов sponsored messages. |
| Proxy sponsor | Блокирует промо от proxy sponsor в запросах/интерфейсе. |
