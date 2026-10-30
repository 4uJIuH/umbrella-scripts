# Dark Seer Illusion Control

управляет иллюзиями от Wall of Replica и Normal Punch / controls Wall of Replica and Normal Punch illusions

<!-- releases:start -->
Скачать: [dark_seer_illusions.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/dark-seer-illusions-v1.0.3/dark_seer_illusions.lua) — `dark-seer-illusions-v1.0.3`, 2026-10-22

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`dark-seer-illusions-v1.0.3`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/dark-seer-illusions-v1.0.3) | 2026-10-22 | [dark_seer_illusions.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/dark-seer-illusions-v1.0.3/dark_seer_illusions.lua) | 50 |
| [`dark-seer-illusions-v1.0.2`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/dark-seer-illusions-v1.0.2) | 2026-10-22 | [dark_seer_illusions.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/dark-seer-illusions-v1.0.2/dark_seer_illusions.lua) | 2 |
| [`dark-seer-illusions-v1.0.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/dark-seer-illusions-v1.0.1) | 2026-10-20 | [dark_seer_illusions.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/dark-seer-illusions-v1.0.1/dark_seer_illusions.lua) | 22 |
| [`dark-seer-illusions-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/dark-seer-illusions-v1.0.0) | 2026-10-20 | [dark_seer_illusions.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/dark-seer-illusions-v1.0.0/dark_seer_illusions.lua) | 3 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=dark-seer-illusions&expanded=true)
<!-- releases:end -->

## Что умеет

Иллюзии от Wall of Replica и Normal Punch сами бьют выбранных врагов по приоритету. Приоритет задаётся в небольшом окне: перетащите иконки героев, клик выключает героя.

- Приоритет врагов в перетаскиваемом окне: левее значит важнее, клик по иконке выключает героя
- Режимы атаки: сначала герои с малым HP (порог в %) или сначала приоритет
- Если выбранных героев нет рядом, бьёт цель Dark Seer или врага с меньшим HP
- Без целей иллюзии следуют за Dark Seer, фармят лесные кемпы или пушат линию и башню
- Пока иллюзии бьют цель, их нельзя выделить; ручной приказ отключает скрипт для иллюзии на несколько секунд

## Установка

1. Нажмите «Установить» в Script Manager или поместите `dark_seer_illusions.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Heroes → Hero List → Dark Seer → Illusions` и включите «Управлять иллюзиями».

## Что нового

# Обновление 1.0.3

- qLocalization встроен в скрипт: отдельный файл !_qLocalizer.lua больше не нужен.

# Обновление 1.0.2

- Настройки перенесены на отдельную вкладку: Heroes → Hero List → Dark Seer → Illusions.

# Обновление 1.0.1

- Кнопка в заголовке окна сворачивает окно, а прячет его в край экрана, только когда окно прижато к краю.

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Dark Seer Illusion Control (English)

## What it does

Illusions from Wall of Replica and Normal Punch attack the selected enemies by priority on their own. Set the priority in a small window: drag the hero icons, click to turn a hero off.

- Enemy priority in a draggable window: further left is higher, click an icon to turn a hero off
- Attack modes: low HP heroes first (threshold in %) or priority first
- When no selected hero is in range, attacks Dark Seer's target or the enemy with the lowest HP
- With no targets the illusions follow Dark Seer, farm jungle camps or push the lane and tower
- Illusions can't be selected while attacking a target; a manual order pauses the script for that illusion for a few seconds

## Install

1. Click Install in Script Manager or place `dark_seer_illusions.lua` in the `umbrella\scripts` folder.
2. Reload Lua scripts.
3. Open `Heroes → Hero List → Dark Seer → Illusions` and turn on "Control illusions".

## Changelog

# Update 1.0.3

- qLocalization is built into the script: the separate !_qLocalizer.lua file is no longer needed.

# Update 1.0.2

- The settings moved to their own tab: Heroes → Hero List → Dark Seer → Illusions.

# Update 1.0.1

- The window header button folds the window and only docks it into the screen edge when the window touches that edge.

# Release v1.0.0

- Release version: the first publication of the script.
