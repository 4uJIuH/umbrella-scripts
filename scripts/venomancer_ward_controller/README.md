# Venomancer Ward Controller

автоматически направляет Plague Wards на Healing Ward и героев / automatically targets Healing Ward and heroes with Plague Wards

<!-- releases:start -->
Скачать: [venomancer_ward_controller.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/venomancer-ward-controller-v1.0.0/venomancer_ward_controller.lua) — `venomancer-ward-controller-v1.0.0`, 2026-10-18

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`venomancer-ward-controller-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/venomancer-ward-controller-v1.0.0) | 2026-10-18 | [venomancer_ward_controller.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/venomancer-ward-controller-v1.0.0/venomancer_ward_controller.lua) | 3 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=venomancer-ward-controller&expanded=true)
<!-- releases:end -->

## Что умеет

Автоматически управляет вардами Venomancer. Healing Ward Juggernaut получает приоритет; если её нет, варды атакуют героя противника с наименьшим здоровьем. Скрипт разработан Ромбитом и его командой, которые являются его единственными владельцами.

- Приоритетная цель — Healing Ward Juggernaut
- Иначе выбирает героя противника с наименьшим здоровьем в радиусе
- Приказы атаки отправляются с интервалом, чтобы не спамить команды

## Установка

1. Поместите `venomancer_ward_controller.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Heroes → Hero List → Venomancer → Main Settings → Ward Settings`.

## Что нового

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Venomancer Ward Controller (English)

## What it does

Automatically controls Venomancer Plague Wards. Juggernaut's Healing Ward takes priority; otherwise, the wards attack the lowest-health enemy hero in range. Created by Ромбит and his team, who retain sole ownership of the script.

- Prioritizes Juggernaut's Healing Ward
- Otherwise selects the lowest-health enemy hero in range
- Throttles attack orders to avoid command spam

## Install

1. Place `venomancer_ward_controller.lua` in the `umbrella\scripts` folder.
2. Reload the Lua scripts.
3. Open `Heroes → Hero List → Venomancer → Main Settings → Ward Settings`.

## Changelog

# Release v1.0.0

- Release version: the first publication of the script.
