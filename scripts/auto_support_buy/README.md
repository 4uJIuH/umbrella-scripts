# Auto Support Buy

покупает по 1 смоку и варду при полном запасе в лавке / buys one smoke or ward each time the shop stock is full

<!-- releases:start -->
Скачать: [auto_support_buy.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/auto-support-buy-v1.1.0/auto_support_buy.lua) — `auto-support-buy-v1.1.0`, 2026-10-20

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`auto-support-buy-v1.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/auto-support-buy-v1.1.0) | 2026-10-20 | [auto_support_buy.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/auto-support-buy-v1.1.0/auto_support_buy.lua) | 79 |
| [`auto-support-buy-v1.0.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/auto-support-buy-v1.0.1) | 2026-10-19 | [auto_support_buy.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/auto-support-buy-v1.0.1/auto_support_buy.lua) | 10 |
| [`auto-support-buy-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/auto-support-buy-v1.0.0) | 2026-10-19 | [auto_support_buy.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/auto-support-buy-v1.0.0/auto_support_buy.lua) | 1 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=auto-support-buy&expanded=true)
<!-- releases:end -->

## Что умеет

Auto Support Buy покупает Smoke of Deceit, Observer Ward и Sentry Ward, по 1 штуке каждый раз, когда их запас в лавке полный, и выкладывает купленное из тайника на землю у фонтана.

- Покупает 1 штуку, когда запас полный: Smoke 3, Observer 4, Sentry 8
- Переключатели предметов, минута начала и порог золота на руках (не нетворс)
- Выкладывает купленное из тайника; режим «Оставлять на базе» для покупок у лавки

## Установка

1. Нажмите «Установить» в Script Manager или поместите auto_support_buy.lua в umbrella\scripts.
2. Перезагрузите Lua-скрипты.
3. Откройте Scripts → Scripts → Auto Support Buy.

## Что нового

# Обновление 1.1.0

- При полном запасе покупается 1 предмет, а не весь запас. Когда запас снова станет полным, скрипт купит еще 1.

# Обновление 1.0.1

- Исправлен приказ покупки: предмет передается и как цель, как в других скриптах с покупкой.

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Auto Support Buy (English)

## What it does

Auto Support Buy purchases Smoke of Deceit, Observer Ward and Sentry Ward one at a time whenever their shop stock is full and drops them from the stash onto the ground at the fountain.

- Buys one item each time the stock is full: Smoke 3, Observer 4, Sentry 8
- Item switches, a start minute and a gold-on-hand threshold (not net worth)
- Drops purchases from the stash; "Leave at base" mode for items bought at the shop

## Install

1. Click Install in Script Manager or place auto_support_buy.lua in umbrella\scripts.
2. Reload Lua scripts.
3. Open Scripts → Scripts → Auto Support Buy.

## Changelog

# Update 1.1.0

- A full stock now buys 1 item instead of the whole stock. When the stock is full again, the script buys 1 more.

# Update 1.0.1

- Fixed the purchase order: the item is also passed as the order target, like in other buying scripts.

# Release v1.0.0

- Release version: the first publication of the script.
