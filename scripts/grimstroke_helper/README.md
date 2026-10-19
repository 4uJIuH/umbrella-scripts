# Grimstroke Helper

подбирает цели для Ink Swell и управляет Dark Portrait / selects Ink Swell targets and controls Dark Portrait

<!-- releases:start -->
Скачать: [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.1.0/grimstroke_helper.lua) — `grimstroke-helper-v1.1.0`, 2026-10-19

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`grimstroke-helper-v1.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/grimstroke-helper-v1.1.0) | 2026-10-19 | [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.1.0/grimstroke_helper.lua) | 0 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=grimstroke-helper&expanded=true)
<!-- releases:end -->

## Что умеет

Grimstroke Helper помогает автоматически выбирать союзника для Ink Swell и управлять иллюзией Dark Portrait. Автор: ! M0RC1 (Discord: wh1teray).

- Выбирает союзника для Ink Swell по близости к врагу, с настройкой разрешённых целей и каста на себя
- Управляет Dark Portrait и приоритизирует видимых вражеских героев с низким здоровьем
- Настраивает поведение иллюзии, когда врагов не видно; панель целей можно перемещать

## Установка

1. Нажмите «Установить» в Script Manager или поместите grimstroke_helper.lua в umbrella\scripts.
2. Перезагрузите Lua-скрипты.
3. Откройте Heroes → Hero List → Grimstroke → Helper.

## Что нового

# Обновление 1.1.0

- Белый список для Dark Portrait: встроенное комбо кастует Dark Portrait только на отмеченных врагов. На остальных врагах оно пропускает Dark Portrait и использует другие способности как обычно.
- Белый список для Soulbind: с талантом 15 уровня комбо накладывает Soulbind на отмеченного врага, даже если рядом нет второго врага. Для остальных врагов Soulbind, как и раньше, кастуется только когда в радиусе связи есть второй враг.
- Оба списка работают на клавише встроенного комбо. Настройки: Герои → Grimstroke → Helper → Combo Whitelists.

# Обновление 1.0.0

- Первый выпуск помощника Grimstroke для Ink Swell и Dark Portrait.

---

# Grimstroke Helper (English)

## What it does

Grimstroke Helper automatically selects an ally for Ink Swell and controls the Dark Portrait illusion. Author: ! M0RC1 (Discord: wh1teray).

- Selects an Ink Swell ally by proximity to enemies, with configurable allowed targets and self-cast
- Controls Dark Portrait and prioritizes visible enemy heroes with low health
- Configures illusion behavior when enemies are not visible; the target panel is draggable

## Install

1. Click Install in Script Manager or place grimstroke_helper.lua in umbrella\scripts.
2. Reload Lua scripts.
3. Open Heroes → Hero List → Grimstroke → Helper.

## Changelog

# Update 1.1.0

- Dark Portrait whitelist: the built-in combo casts Dark Portrait only on checked enemies. On other enemies it skips Dark Portrait and uses the other abilities as usual.
- Soulbind whitelist: with the level 15 talent, the combo Soulbinds a checked enemy even when no second enemy is nearby. Other enemies keep the original logic: Soulbind is cast only when a second enemy is in link range.
- Both lists work on the built-in combo key. Settings: Heroes → Grimstroke → Helper → Combo Whitelists.

# Update 1.0.0

- Initial release of the Grimstroke Ink Swell and Dark Portrait helper.
