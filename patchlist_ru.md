# Список патчей Patchgram

Здесь простым языком описано, какие патчи есть в Patchgram и что они делают.

## Типы патчей

| Тип | Что это значит | Когда используется |
| --- | --- | --- |
| `dylib` | Patchgram ставит локальную runtime-библиотеку в Telegram Desktop и меняет поведение во время работы клиента. | Визуальные патчи, настраиваемые значения и функции, которые удобнее обновлять без постоянной перезаписи большого количества байтов в клиенте. |
| `binary` | Patchgram меняет найденные byte-паттерны прямо в исполняемом файле Telegram Desktop. | Патчи запросов, constructor id и локальных проверок, которые проще и стабильнее менять напрямую в бинаре. |

> Большинство патчей работают только локально на клиенте. Они меняют то, что Telegram Desktop отправляет, блокирует или показывает у тебя. Они не меняют серверные данные аккаунта Telegram.

## Патчи

| Патч | Тип | Что делает |
| --- | --- | --- |
| Always offline | `dylib` | Держит аккаунт оффлайн локально, принудительно меняя значение offline в `account.updateStatus`. |
| Block typing activity | `dylib` | Не даёт Telegram Desktop отправлять статус "печатает". |
| Block read messages | `dylib` | Блокирует запросы прочтения истории, чтобы сообщения не отмечались прочитанными через пропатченный путь. |
| Message settings | `dylib` | Общий патч приватности для статуса печати, прочтений, локальных черновиков и scheduled send. |
| Open links without warning | `dylib` | Открывает скрытые/внешние ссылки без дополнительного предупреждения Telegram. |
| Don't share phone when adding contacts | `dylib` | Не даёт Telegram Desktop отправлять флаг исключения приватности номера при добавлении контакта. |
| 999 accounts | `binary` | Поднимает локальный лимит аккаунтов в Telegram Desktop до 999. |
| Show bot callback-data on hover | `dylib` | Показывает callback-data inline-кнопок бота при наведении/копировании текста кнопки. |
| Disable Premium, Stars, TON & Gifts | `binary` | Отключает выбранные monetization-разделы и запросы: Premium, Stars, TON, Gifts, boosts, paid reactions, emoji statuses и части app config. |
| Custom account settings | `dylib` | Общий патч локальной кастомизации аккаунта: балансы, бейджи, Premium, верификация, номер, userID, канал в профиле и Fragment phone. |
| Disable premium effects | `dylib` | Отключает локальный запуск Premium-эффектов и анимаций стикеров. |
| Disable media spoilers | `dylib` | Показывает фото/видео со спойлером сразу, без локального блюра. |
| Sensitive blur | `dylib` | Отключает локальный блюр sensitive-контента. |
| Hide stories | `dylib` | Скрывает stories локально и блокирует известные запросы получения/прочтения/просмотра stories. |
| Disable ads | `dylib` | Отключает Telegram Ads и промо от proxy sponsor. |

## Подпатчи Message Settings

| Подпатч | Что делает |
| --- | --- |
| Typing activity | Не отправляет индикатор "печатает". |
| Read receipts | Не отправляет запросы прочтения через пропатченные пути. |
| Local drafts | Оставляет черновики локальными, блокируя синхронизацию drafts. |
| Scheduled send | Включает runtime-флаг Patchgram для локальной отложенной отправки. |

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
| Custom Stars | Визуально меняет баланс Stars в My Stars и пунктах монетизации. |
| Custom TON | Визуально меняет баланс TON в My TON и пунктах монетизации. |
| Custom level rating | Визуально меняет level/rating Stars для выбранных пользователей. |
| Visual peer badge | Визуально добавляет локальный бейдж Verified, Scam или Fake выбранным юзерам/каналам. |
| Bot verification | Визуально добавляет локальную bot verification. Можно выбрать, где показывать и какой preset использовать. |
| Local Telegram Premium | Локально включает Premium-доступность для UI-проверок Telegram Desktop. |
| Custom phone number | Визуально заменяет твой номер телефона локально. Пустая строка означает оригинальный номер. |
| Custom userID | Визуально заменяет отображаемый userID локально. Пустая строка означает оригинальный ID. |
| Local attached channel | Визуально прикрепляет другой канал по channel ID. Чтобы он корректно отображался у тебя в клиенте, сначала нужно открыть/прогрузить этот канал в Telegram Desktop. |
| Fragment phone | Локально делает отображаемый номер коллекционным и позволяет задать свои значения `fragment.collectibleInfo`. |

## Подпатчи Disable Ads

| Подпатч | Что делает |
| --- | --- |
| Telegram Ads | Блокирует пути запросов sponsored messages. |
| Proxy sponsor | Блокирует промо от proxy sponsor в запросах/интерфейсе. |
