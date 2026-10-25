# Chronosphere Helper

поправляет позицию Chronosphere, кастует комбо и отменяет пустые купола / corrects Chronosphere placement, casts a combo and cancels empty domes

<!-- releases:start -->
Скачать: [ChronosphereHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/chronosphere-helper-v1.0.0/ChronosphereHelper.lua) — `chronosphere-helper-v1.0.0`, 2026-10-24

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`chronosphere-helper-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/chronosphere-helper-v1.0.0) | 2026-10-24 | [ChronosphereHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/chronosphere-helper-v1.0.0/ChronosphereHelper.lua) | 12 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=chronosphere-helper&expanded=true)
<!-- releases:end -->

## Что умеет

Немного поправляет точку Chronosphere в пределах заданного времени. Если это возможно, захватывает больше врагов, ставит их в радиус атаки союзников ближнего боя и оставляет союзников снаружи. Чудес не делает: если поправить нельзя, каст идёт как есть.

- Helper: больше врагов в куполе, враги в радиусе атаки союзников ближнего боя, союзники снаружи
- Приоритетных союзников скрипт старается оставить вне купола, если это возможно
- Combo: Chronosphere через Time Walk или Blink Dagger со всеми поправками Helper
- Fail Switch: не даёт поставить купол без врагов и отменяет анимацию, если враги вышли из радиуса во время каста
- Fail Switch выключается, если позиции не всех врагов известны, поэтому не мешает ставить купол на невидимых врагов
- Работает на враге, который возрождается с Aegis

## Установка

1. Нажмите «Установить» в Script Manager или поместите `ChronosphereHelper.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Scripts → General → Utility → Chronosphere` и настройте группы Helper, Combo и Fail Switch.

## Что нового

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Chronosphere Helper (English)

## What it does

Makes small corrections to Chronosphere within the configured time range. When feasible, it fits more enemies inside, places them within attack range of melee allies and keeps allies outside. It doesn't work magic: if no correction is possible, the cast goes as is.

- Helper: more enemies inside the dome, enemies within reach of melee allies, allies outside
- Priority allies are kept outside the dome when possible
- Combo: casts Chronosphere through Time Walk or Blink Dagger with all Helper corrections
- Fail Switch: blocks a dome with no enemies and cancels the animation if enemies leave the range during the cast
- Fail Switch stays off unless all enemy positions are known, so it won't stop casts on invisible enemies
- Works on an enemy reviving with Aegis

## Install

1. Click Install in Script Manager or place `ChronosphereHelper.lua` in the `umbrella\scripts` folder.
2. Reload Lua scripts.
3. Open `Scripts → General → Utility → Chronosphere` and set up the Helper, Combo and Fail Switch groups.

## Changelog

# Release v1.0.0

- Release version: the first publication of the script.
