# Techies Auto Miner

сам застраивает выбранные зоны минами / fills the chosen zones with mines on its own

<!-- releases:start -->
Скачать: [techies_auto_miner.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/techies-auto-miner-v1.5/techies_auto_miner.lua) — `techies-auto-miner-v1.5`, 2026-10-24

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`techies-auto-miner-v1.5`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/techies-auto-miner-v1.5) | 2026-10-24 | [techies_auto_miner.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/techies-auto-miner-v1.5/techies_auto_miner.lua) | 13 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=techies-auto-miner&expanded=true)
<!-- releases:end -->

## Что умеет

Скрипт для Techies: застраивает выбранные зоны минами, умеет рисовать области мышью, по умолчанию не блокирует нейтральные кемпы и плотно заставляет базы. Авто-зоны и ручные области можно совмещать.

- Авто-зоны по миникарте: своя и вражеская база, тройка (аванпост), лес, потайной магазин
- Ручные зоны мышью: бинд, ЛКМ ставит точки, Ctrl+ЛКМ замыкает; области сохраняются в конфиг
- Споун-боксы нейтральных кемпов по умолчанию исключаются; опция «Заставлять кемпы (нейтралы)» включает их
- Базы: прямоугольная сетка от трона, 2600 вперёд и 800 назад, шаг 360; здания и непроходимые клетки отсекаются
- Неудачные касты повторяются через 45 с, недостижимые точки через 90 с
- Мана: Arcane Boots, Stick/Wand и манго, если не хватает на мину
- ESP: круги мин, незаминированные точки, линия до цели, статус над героем
- ПКМ по игре или ручной приказ герою останавливают минирование; плашка состояния и дамп в debug.log

## Установка

1. Нажмите «Установить» в Script Manager или поместите `techies_auto_miner.lua` и `!_qLocalizer.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Heroes → Hero List → Techies → Авто-минирование` и назначьте клавишу «Старт / Стоп».

Примечание: GitHub скачивает библиотеку как `_qLocalizer.lua`; переименуй её в `!_qLocalizer.lua` перед загрузкой Lua-скриптов.

## Что нового

# Релиз v1.5

- Меню перенесено в `Heroes → Hero List → Techies → Авто-минирование`; все клавиши по умолчанию не назначены.
- Кнопка START на панели карты запускает минирование без бинда.
- Ручные зоны мышью: ЛКМ ставит точки, Ctrl+ЛКМ замыкает; областей сколько угодно, они сохраняются в конфиг.
- Нейтральные кемпы по умолчанию не минируются; опция «Заставлять кемпы (нейтралы)» включает их.
- Базы покрываются прямоугольной сеткой от трона (2600 вперёд, 800 назад), шаг мин по умолчанию 360.
- Неудачные касты повторяются через 45 с, недостижимые точки через 90 с, без вечных дыр.
- Исправлены пустые зоны при старте, ошибки ожидания маны и перезарядки и привязка тройки не к той башне.
- Добавлены плашка диагностики и дамп в debug.log.

# Релиз v1.1

- Релизная версия: первая публикация скрипта.

---

# Techies Auto Miner (English)

## What it does

A Techies script that mines the chosen zones by itself and lets you draw areas with the mouse. By default it leaves neutral camps unblocked and mines bases densely. Auto zones and manual areas can be combined.

- Auto zones from the minimap: your base, enemy base, triangle (outpost), jungle, secret shop
- Manual zones with the mouse: press the bind, left click adds points, Ctrl+left click closes; areas are saved to the config
- Neutral camp spawn boxes are excluded by default; "Force camps (neutrals)" mines them too
- Bases: a rectangular grid from the throne, 2600 forward and 800 back, step 360; buildings and unwalkable cells are cut off
- Failed casts retry after 45 s, unreachable points after 90 s
- Mana: uses Arcane Boots, Stick/Wand and mango when a mine needs more mana
- ESP: mine circles, unmined points, a line to the current target, status above the hero
- Right click or any manual order stops mining; status panel and a dump in debug.log

## Install

1. Click Install in Script Manager or place `techies_auto_miner.lua` and `!_qLocalizer.lua` in the `umbrella\scripts` folder.
2. Reload Lua scripts.
3. Open `Heroes → Hero List → Techies → Авто-минирование` and bind the Start / Stop key.

Note: GitHub downloads the library as `_qLocalizer.lua`; rename it to `!_qLocalizer.lua` before loading Lua scripts.

## Changelog

# Release v1.5

- The menu moved to `Heroes → Hero List → Techies → Авто-минирование`; all keys are unbound by default.
- The START button on the map panel starts mining without a bind.
- Manual mouse zones: left click adds points, Ctrl+left click closes; any number of areas, saved to the config.
- Neutral camps are not mined by default; "Force camps (neutrals)" turns them on.
- Bases are covered by a rectangular grid from the throne (2600 forward, 800 back); default mine spacing is 360.
- Failed casts retry after 45 s and unreachable points after 90 s, so no permanent holes.
- Fixed empty zones at start, mana and cooldown wait errors, and the triangle anchoring to the wrong tower.
- Added a diagnostics panel and a dump to debug.log.

# Release v1.1

- Release version: the first publication of the script.
