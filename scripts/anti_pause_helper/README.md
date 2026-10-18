# AntiPause Helper

помогает снять паузу в игре / helps resume a paused game

<!-- releases:start -->
Первая версия: [`v1.0.0` — `anti_pause_helper.lua`](https://raw.githubusercontent.com/4uJIuH/umbrella-scripts/main/scripts/anti_pause_helper/anti_pause_helper.lua)

[Релизы на GitHub](https://github.com/4uJIuH/umbrella-scripts/releases?q=anti-pause-helper&expanded=true)
<!-- releases:end -->

## Что умеет

Отслеживает событие паузы и отправляет команду на её снятие. В исходнике предусмотрена одна попытка на событие с интервалом ограничения 5 секунд — повторов каждую секунду нет. Автор: dreiki (Discord: dreiki666).

- Автоматическое снятие паузы можно включить или выключить
- По умолчанию скрипт игнорирует паузы от союзников
- Не пытается снять паузу, поставленную самим игроком

## Установка

1. Поместите `anti_pause_helper.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Scripts → Other → AntiPause Helper → AntiPause Helper → Settings`.

---

# AntiPause Helper (English)

## What it does

Watches for a pause event and issues an unpause command. The supplied source makes one attempt per event with a 5-second rate limit; it does not retry every second. Author: dreiki (Discord: dreiki666).

- Automatic unpause can be enabled or disabled
- Ignores allied pauses by default
- Does not try to unpause a game paused by the local player

## Install

1. Place `anti_pause_helper.lua` in the `umbrella\scripts` folder.
2. Reload the Lua scripts.
3. Open `Scripts → Other → AntiPause Helper → AntiPause Helper → Settings`.
