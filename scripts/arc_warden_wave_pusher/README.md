# Arc Warden Wave Pusher

умный пуш крип-волн клоном Arc Warden / smart creep-wave pushing with Arc Warden's clone

<!-- releases:start -->
Скачать: [ArcWardenWavePusher.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/arc-warden-wave-pusher-v1.2.0/ArcWardenWavePusher.lua) — `arc-warden-wave-pusher-v1.2.0`, 2026-10-22

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`arc-warden-wave-pusher-v1.2.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/arc-warden-wave-pusher-v1.2.0) | 2026-10-22 | [ArcWardenWavePusher.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/arc-warden-wave-pusher-v1.2.0/ArcWardenWavePusher.lua) | 114 |
| [`arc-warden-wave-pusher-v1.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/arc-warden-wave-pusher-v1.1.0) | 2026-10-15 | [ArcWardenWavePusher.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/arc-warden-wave-pusher-v1.1.0/ArcWardenWavePusher.lua) | 54 |
| [`arc-warden-wave-pusher-v1.0.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/arc-warden-wave-pusher-v1.0.1) | 2026-10-15 | [ArcWardenWavePusher.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/arc-warden-wave-pusher-v1.0.1/ArcWardenWavePusher.lua) | 3 |
| [`arc-warden-wave-pusher-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/arc-warden-wave-pusher-v1.0.0) | 2026-10-15 | [ArcWardenWavePusher.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/arc-warden-wave-pusher-v1.0.0/ArcWardenWavePusher.lua) | 2 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=arc-warden-wave-pusher&expanded=true)
<!-- releases:end -->

## Что умеет

Дополнение для автоигры клона Arc Warden: помогает эффективнее забирать крипов волны, распределяя атаки и Spark Wraith по приоритетным целям. После дальников и знаменосца отдаёт зачистку мили-крипов и вышек базовому скрипту; может уступать комбо и приостанавливать пуш, если рядом вражеский герой. Названия настроек и подсказки поддерживают русский и английский языки.

- Рассчитывает урон Spark Wraith и планирует атаки по дальним крипам, чтобы не тратить лишние удары
- Приоритет целей: дальники, затем знаменосец, затем мили-крипы
- Выбирает позицию для атаки дальников и знаменосца и ставит Magnetic Field под клона
- Подсвечивает текущую цель кольцом: голубым для дальника, золотым для знаменосца
- Передаёт зачистку мили-крипов и вышек базовому скрипту и уступает ему во время комбо по герою
- Настройка позволяет уступать комбо и приостанавливать пуш при появлении вражеского героя рядом
- Названия настроек и подсказки переключаются между русским и английским языками

## Установка

1. Поместите `ArcWardenWavePusher.lua` в `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Heroes → Hero List → Arc Warden → Clone Settings → Auto Play Settings → Умный пуш пачек`.

## Что нового

# 1.2.0

- Умная установка Magnetic Field полностью переработана: купол накрывает максимум союзных крипов и отдельно приоритизирует катапульты.
- При пушке башня остаётся вне купола и продолжает атаковать защищаемых крипов.
- Клон входит в установленный купол и старается не выходить из него во время пушки.
- Добавлен купол у порога смерти: перед исчезновением клон рассчитывает место встречи союзной и вражеской волн и оставляет там Magnetic Field. Работает даже без башни.
- Если точка купола далеко, клон заранее подходит на дистанцию применения.
- Добавлено отображение будущей позиции купола с реальным радиусом и числом крипов внутри.
- В настройках отображения можно выбрать эффект, цвет радиуса, цвет и размер счётчика, а также дальность показа.
- Улучшена логика Spark Wraith: клон приоритизирует дарвов и знаменосцев, учитывает летящие атаки союзных крипов и не тратит способность впустую.
- После Spark клон добавляет лишнюю точку, когда это нужно для гарантированного добива, и не делает лишних атак.
- Обычные крипы по-прежнему обрабатывает стандартная автоигра, когда нет приоритетных целей.
- Обновлено отображение текущей цели пуша: более аккуратные эффекты, настройка цвета и размера.
- Удалена клавиша переключения умной пушки: подключаемый аддон управляет пушкой автоматически.
- Исправлен баг таймера Tempest Double, из-за которого купол у порога смерти не срабатывал.
- Добавлена русская и английская локализация, а также настройки отладки аддона.

# 1.1.0

- Добавлена настройка, позволяющая клону уступать управление комбо и не начинать пуш, когда рядом есть вражеский герой.
- Настройка доступна в русском и английском интерфейсах и включена по умолчанию.

## 1.0.1

- Добавлена русско-английская локализация настроек меню с учётом выбранного языка Umbrella.
- Логика автоигры и приоритеты целей не менялись.

---

# Arc Warden Wave Pusher (English)

## What it does

An add-on for Arc Warden clone auto-play that helps secure more lane creeps by prioritizing attacks and Spark Wraiths. After ranged creeps and the flagbearer are handled, it yields melee creeps and towers to the base script; it can also yield to combos and pause pushing when an enemy hero is nearby. Menu labels and tooltips support Russian and English.

- Accounts for Spark Wraith damage and plans attacks on ranged creeps to avoid wasted hits
- Target priority: ranged creeps, then the flagbearer, then melee creeps
- Positions to reach ranged creeps and the flagbearer, and places Magnetic Field under the clone
- Highlights the current target with a ring: cyan for ranged creeps and gold for the flagbearer
- Yields melee creep and tower cleanup to the base script and yields during hero combos
- An option yields to combos and pauses pushing when an enemy hero is nearby
- Menu labels and tooltips switch between Russian and English

## Install

1. Place `ArcWardenWavePusher.lua` in `umbrella\scripts`.
2. Reload the Lua scripts.
3. Open `Heroes → Hero List → Arc Warden → Clone Settings → Auto Play Settings → Умный пуш пачек`.

## Changelog

# 1.2.0

- The smart Magnetic Field placement is fully redesigned: the dome covers the most allied creeps and separately prioritizes catapults.
- During a push, the tower stays outside the dome and keeps attacking the protected creeps.
- The clone enters the placed dome and tries not to leave it during the push.
- Added near-death dome: before disappearing, the clone calculates where allied and enemy waves meet and leaves Magnetic Field there. Works even without a tower.
- If the dome point is far away, the clone moves into cast range in advance.
- Added a display of the future dome position with its real radius and the number of creeps inside.
- Display settings let you choose the effect, the radius colour, the counter colour and size, and the display range.
- Spark Wraith logic is improved: the clone prioritizes Dars and Standard Bearers, accounts for incoming allied creep attacks and does not waste the ability.
- After Spark, the clone adds an extra point when it is needed for a guaranteed kill, and makes no unnecessary attacks.
- Regular creeps are still handled by standard AutoPlay when there are no priority targets.
- Updated display of the current push target: cleaner effects, colour and size settings.
- Removed the smart gun toggle key: the included addon controls the gun automatically.
- Fixed a Tempest Double timer bug that stopped the near-death dome from triggering.
- Added Russian and English localization, plus addon debugging options in settings.

# 1.1.0

- Added an option for the clone to yield control to combos and pause pushing when an enemy hero is nearby.
- The option is available in Russian and English and is enabled by default.

## 1.0.1

- Added Russian and English menu localization based on the selected Umbrella language.
- Auto-play logic and target priorities are unchanged.
