# Tinker Helper

набор функций для фарма и автоматизации на Тинкере / a collection of farming and automation features for Tinker

<!-- releases:start -->
Скачать: [tinker_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/tinker-helper-v1.0.1/tinker_helper.lua) — `tinker-helper-v1.0.1`, 2026-10-19

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`tinker-helper-v1.0.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/tinker-helper-v1.0.1) | 2026-10-19 | [tinker_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/tinker-helper-v1.0.1/tinker_helper.lua) | 2 |
| [`tinker-helper-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/tinker-helper-v1.0.0) | 2026-10-13 | [tinker_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/tinker-helper-v1.0.0/tinker_helper.lua) | 13 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=tinker-helper&expanded=true)
<!-- releases:end -->

## Что умеет

Сборный скрипт с автофармом, глиммером, подбором алтаря мудрости и уклонением турелями.

- Автофарм лесных и линейных крипов
- Автоматические действия с Glimmer Cape и алтарём мудрости
- Включает додж турелями и конфликтует с Tinker Turret Dodge — не используйте их одновременно

## Установка

1. Поместите `tinker_helper.lua` в `umbrella\scripts` и перезагрузите Lua-скрипты.
2. Настройки: Герои → Tinker → Tinker Helper.

## Что нового

# Исправление v1.0.1

- Скрипт больше не ломает другие скрипты. Раньше он подменял общий модуль `Config` своим меню, и скрипты, загруженные после него, не могли читать и сохранять настройки.
- Внутренние таблицы `State`, `Constants` и функция `L` больше не глобальные и не пересекаются с переменными других скриптов.
- Скрипт больше не добавляет свою функцию в общий модуль `Camp`.
- Поиск лесных крипов использует правильный фильтр юнитов.

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Tinker Helper (English)

## What it does

A bundled script with automatic farming, Glimmer usage, Wisdom Rune pickup, and turret dodging.

- Automatic jungle and lane creep farming
- Automates selected Glimmer Cape and Wisdom Rune actions
- Includes turret dodging and conflicts with Tinker Turret Dodge; do not run both together

## Install

1. Place `tinker_helper.lua` in `umbrella\scripts` and reload the Lua scripts.
2. Settings: Heroes → Tinker → Tinker Helper.

## Changelog

# Fix v1.0.1

- The script no longer breaks other scripts. It used to replace the shared `Config` module with its own menu, so scripts loaded after it could not read or save their settings.
- The internal `State` and `Constants` tables and the `L` function are no longer global and no longer clash with other scripts' variables.
- The script no longer adds its own function to the shared `Camp` module.
- Neutral creep search uses a valid unit filter.

# Release v1.0.0

- Release version: the first publication of the script.
