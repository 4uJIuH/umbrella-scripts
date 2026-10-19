# Self Play

автоматически управляет героем и выполняет игровые задачи / automatically controls a hero and handles in-game objectives

<!-- releases:start -->
Скачать: [Self-Play.zip](https://github.com/4uJIuH/umbrella-scripts/releases/download/self-play-v1.0.1/Self-Play.zip) — `self-play-v1.0.1`, 2026-10-15

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`self-play-v1.0.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/self-play-v1.0.1) | 2026-10-15 | [Self-Play.zip](https://github.com/4uJIuH/umbrella-scripts/releases/download/self-play-v1.0.1/Self-Play.zip) | 2 |
| [`self-play-v1.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/self-play-v1.0.0) | 2026-10-13 | [Self-Play.zip](https://github.com/4uJIuH/umbrella-scripts/releases/download/self-play-v1.0.0/Self-Play.zip) | 5 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=self-play&expanded=true)
<!-- releases:end -->

## Что умеет

Полноценный self-play-скрипт: действует вместе с командой, может искать Roshan и руны, выбирает роль и линию и использует сборки. Автор предупреждает, что скрипт не проверен на всех героях и может содержать ошибки.

- командные действия, Roshan и руны
- выбор роли, линии и сборки для героя
- архив включает главный файл, модули, данные и необходимые библиотеки

## Установка

1. Распакуйте `Self-Play.zip` в папку `Umbrella\scripts`, сохранив структуру файлов.
2. Перезагрузите скрипты. Меню: Scripts → Self Play → Main.

## Что нового

# Обновление v1.0.1

- Ротация на свободную линию: бот уходит с линии, где стоит слишком много союзников.
- Новый ползунок «Уверенность в драках»: насколько смело бот вступает в бой.
- Керри и мид не уходят в драки и пуши команды, пока не готовы к ним.
- Бот ставит игру на паузу, если камера не смотрит на героя; слежение камерой включено по умолчанию.
- Автоматическое переподключение к матчу после вылета.
- Покупки: Blood Grenade для саппортов в начале игры, сентри для оффлейна и саппортов, точнее учитываются потраченные деньги.

# Релиз v1.0.0

- Релизная версия: первая публикация скрипта.

---

# Self Play (English)

## What it does

A full self-play script that coordinates with the team, can pursue Roshan and runes, selects a role and lane, and uses builds. The author notes it has not been tested on every hero and may contain bugs.

- team play, Roshan, and rune objectives
- selects a role, lane, and hero build
- archive includes the main file, modules, data, and bundled libraries

## Install

1. Extract `Self-Play.zip` into `Umbrella\scripts`, preserving its folder structure.
2. Reload scripts. Menu: Scripts → Self Play → Main.

## Changelog

# Update v1.0.1

- Lane rotation: the bot leaves a lane that is crowded with allies.
- New Confidence in fights slider: how boldly the bot joins a fight.
- Carry and mid no longer join team fights and pushes before they are ready.
- The bot pauses while the camera is away from the hero; camera follow is on by default.
- Automatic reconnect to the match after a disconnect.
- Shopping: Blood Grenade for supports early on, sentries for offlane and supports, spent gold is tracked more precisely.

# Release v1.0.0

- Release version: the first publication of the script.
