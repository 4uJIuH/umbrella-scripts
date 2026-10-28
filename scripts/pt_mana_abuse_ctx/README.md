# PT Mana Abuse (ctx)

автоматически переключает Power Treads на интеллект для каста / switches Power Treads to Intelligence when needed to cast

<!-- releases:start -->
Скачать: [pt_mana_abuse_ctx.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/pt-mana-abuse-ctx-v1.0.0/pt_mana_abuse_ctx.lua) — `pt-mana-abuse-ctx-v1.0.0`, 2026-10-19

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`pt-mana-abuse-ctx-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/pt-mana-abuse-ctx-v1.0.0) | 2026-10-19 | [pt_mana_abuse_ctx.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/pt-mana-abuse-ctx-v1.0.0/pt_mana_abuse_ctx.lua) | 13 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=pt-mana-abuse-ctx&expanded=true)
<!-- releases:end -->

## Что умеет

Если для способности не хватает маны, скрипт проверяет, хватит ли её с Power Treads на интеллекте, и при необходимости переключает тапок для применения. В интерфейсе также учитывается дополнительная мана от PT.

- Автоматически переключает Power Treads на интеллект, если это позволяет применить способность
- Учитывает ману с интеллекта при отображении иконок способностей
- Локализация интерфейса встроена в файл; отдельный `_qLocalizer.lua` не требуется

## Установка

1. Поместите `pt_mana_abuse_ctx.lua` в папку `umbrella\scripts` и перезагрузите Lua-скрипты.
2. Откройте `General → Main → PT Abuse → Settings → Основное`.

## Что нового

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# PT Mana Abuse (ctx) (English)

## What it does

When a spell lacks mana, the script checks whether Intelligence Power Treads provide enough and switches Treads to allow the cast. Ability icons also account for the extra mana from PT.

- Automatically switches Power Treads to Intelligence when that makes a spell castable
- Accounts for Intelligence Treads mana when displaying ability icons
- Localization is included in the file; no separate `_qLocalizer.lua` is required

## Install

1. Place `pt_mana_abuse_ctx.lua` in `umbrella\scripts` and reload the Lua scripts.
2. Open `General → Main → PT Abuse → Settings → Main`.

## Changelog

# Release v1.0.0

- Release version: the first publication of the script.
