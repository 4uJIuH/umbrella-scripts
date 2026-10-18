# Venomancer Ward Controller

автоматически направляет Plague Wards на Healing Ward и героев / automatically targets Healing Ward and heroes with Plague Wards

<!-- releases:start -->
Первая версия: [`v1.0.0` — `venomancer_ward_controller.lua`](https://raw.githubusercontent.com/4uJIuH/umbrella-scripts/main/scripts/venomancer_ward_controller/venomancer_ward_controller.lua)

[Релизы на GitHub](https://github.com/4uJIuH/umbrella-scripts/releases?q=venomancer-ward-controller&expanded=true)
<!-- releases:end -->

## Что умеет

Автоматически управляет вардами Venomancer. Healing Ward Juggernaut получает приоритет; если её нет, варды атакуют героя противника с наименьшим здоровьем. Скрипт разработан Ромбитом и его командой, которые являются его единственными владельцами.

- Приоритетная цель — Healing Ward Juggernaut
- Если Healing Ward нет поблизости, выбирает героя противника с наименьшим здоровьем
- Ограничивает частоту приказов атаки

## Установка

1. Поместите `venomancer_ward_controller.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Heroes → Hero List → Venomancer → Main Settings → Ward Settings`.

---

# Venomancer Ward Controller (English)

## What it does

Automatically controls Venomancer Plague Wards. Juggernaut's Healing Ward takes priority; otherwise, the wards attack the lowest-health enemy hero in range. Created by Ромбит and his team, who retain sole ownership of the script.

- Prioritizes Juggernaut's Healing Ward
- If no Healing Ward is nearby, selects the lowest-health enemy hero
- Throttles attack orders

## Install

1. Place `venomancer_ward_controller.lua` in the `umbrella\scripts` folder.
2. Reload the Lua scripts.
3. Open `Heroes → Hero List → Venomancer → Main Settings → Ward Settings`.
