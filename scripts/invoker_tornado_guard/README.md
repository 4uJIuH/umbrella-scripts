# Invoker Tornado Guard

не даёт Tornado сбить контроль на враге / keeps Tornado from breaking control on an enemy

<!-- releases:start -->
Скачать: [_invoker_tornado_ally_cc_guard.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/invoker-tornado-guard-v1.0.0/_invoker_tornado_ally_cc_guard.lua) — `invoker-tornado-guard-v1.0.0`, 2026-10-24

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`invoker-tornado-guard-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/invoker-tornado-guard-v1.0.0) | 2026-10-24 | [_invoker_tornado_ally_cc_guard.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/invoker-tornado-guard-v1.0.0/_invoker_tornado_ally_cc_guard.lua) | 22 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=invoker-tornado-guard&expanded=true)
<!-- releases:end -->

## Что умеет

Если цель или враг на пути смерча обездвижен (стан, хекс, рут, сон, страх, таунт, поводок, циклон, Chrono, Black Hole, Kinetic Field, Arena, каналы союзников вроде Dismember), Tornado не кастуется, а летит стыком к концу контроля.

- В комбо Tornado пропускается ещё до Invoke, комбо продолжает остальными скиллами
- Если контроль кончится не позже чем через 0.3 с, комбо ждёт и кидает Tornado ровно к концу контроля
- При ручном нажатии каст блокируется, и охранник сам кидает Tornado к концу контроля
- Остаток контроля берётся у движка; если его нельзя прочитать, Tornado ждёт, пока контроль спадёт
- Каждый запрет пишется в лог строкой BLOCK (ручное нажатие) или COMBO (комбо)

## Установка

1. Нажмите «Установить» в Script Manager или поместите `_invoker_tornado_ally_cc_guard.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Heroes → Hero List → Invoker → Main Settings → Tornado Guard`.

## Что нового

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Invoker Tornado Guard (English)

## What it does

If the target or an enemy in the tornado's path is disabled (stun, hex, root, sleep, fear, taunt, leash, cyclone, Chrono, Black Hole, Kinetic Field, Arena, ally channels like Dismember), Tornado isn't cast and lands right as the control ends instead.

- In a combo, Tornado is skipped before Invoke and the combo goes on with the other spells
- If the control ends within 0.3 s, the combo waits and throws Tornado exactly at the end
- On a manual press the cast is blocked and the guard throws Tornado at the end of the control itself
- The remaining control time comes from the engine; if it can't be read, Tornado waits until the control is gone
- Each block is logged as a BLOCK (manual press) or COMBO (combo) line

## Install

1. Click Install in Script Manager or place `_invoker_tornado_ally_cc_guard.lua` in the `umbrella\scripts` folder.
2. Reload Lua scripts.
3. Open `Heroes → Hero List → Invoker → Main Settings → Tornado Guard`.

## Changelog

# Release v1.0.0

- Release version: the first publication of the script.
