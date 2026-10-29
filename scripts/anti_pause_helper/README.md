# AntiPause Helper

помогает снять паузу в игре / helps resume a paused game

<!-- releases:start -->
Скачать: [anti_pause_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/anti-pause-helper-v1.0.0/anti_pause_helper.lua) — `anti-pause-helper-v1.0.0`, 2026-10-18

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`anti-pause-helper-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/anti-pause-helper-v1.0.0) | 2026-10-18 | [anti_pause_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/anti-pause-helper-v1.0.0/anti_pause_helper.lua) | 16 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=anti-pause-helper&expanded=true)
<!-- releases:end -->

## Что умеет

AntiPause Helper отслеживает событие паузы и отправляет команду на снятие паузы. В текущем исходнике попытка выполняется один раз на событие и ограничена интервалом в 5 секунд; автоматических повторов каждую секунду нет. Автор: dreiki (Discord: dreiki666).

- Включение и выключение автоматической попытки
- Опция игнорирования пауз от союзников включена по умолчанию
- Не пытается снять паузу, поставленную самим игроком
- Одна попытка на событие паузы; между командами действует интервал 5 секунд

## Установка

1. Поместите `anti_pause_helper.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Scripts → Other → AntiPause Helper → AntiPause Helper → Settings`.

## Что нового

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# AntiPause Helper (English)

## What it does

AntiPause Helper watches for a pause event and issues an unpause command. In the supplied source, it makes one attempt per event with a 5-second rate limit; it does not retry every second. Author: dreiki (Discord: dreiki666).

- Toggle automatic unpause attempts
- Ignore allied pauses, enabled by default
- Does not try to unpause a game paused by the local player
- One attempt per pause event, with a 5-second interval between commands

## Install

1. Place `anti_pause_helper.lua` in the `umbrella\scripts` folder.
2. Reload the Lua scripts.
3. Open `Scripts → Other → AntiPause Helper → AntiPause Helper → Settings`.

## Changelog

# Release v1.0.0

- Release version: the first publication of the script.
