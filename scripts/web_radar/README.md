# Cloud Radar

живой радар матча для друзей по ссылке / live match radar for friends via a link

<!-- releases:start -->
Скачать: [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.2.0/web_radar.lua) — `web-radar-v2.2.0`, 2026-10-19

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`web-radar-v2.2.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.2.0) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.2.0/web_radar.lua) | 0 |
| [`web-radar-v2.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.1.0) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.1.0/web_radar.lua) | 0 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=web-radar&expanded=true)
<!-- releases:end -->

## Что умеет

Показывает друзьям карту вашего матча в браузере: героев, в том числе в тумане войны, крипов, варды, кемпы, руны, вышки, Рошана и ленту событий. Сервер не нужен: нажмите Start и отправьте ссылку.

- Карта с иконками героев, вардов, рун и вышек
- Герои в тумане по мапхаку и прогноз волн крипов в тумане
- Предметы, способности с перезарядками, KDA, NW и байбек
- Лента событий: смерти, руны, телепорты, Smoke, фарм леса, варды, башни, Рошан и Торментор
- Карта и консоль поверх игры (картинка в картинке)

## Установка

1. Поместите `web_radar.lua` в папку `umbrella\scripts`.
2. Перезагрузите Lua-скрипты.
3. Откройте `Scripts → Main → Cloud Radar`, включите радар и нажмите Start.
4. Скопируйте ссылку из поля «Ссылка» и отправьте друзьям.

## Что нового

# Обновление v2.2.0

- Волны крипов в тумане: каждые 30 секунд скрипт выпускает волну по каждой линии и ведет ее до встречи с вражеской волной или первой живой вражеской башни. Место встречи уточняется по видимым крипам.
- Позиции башен запоминаются, поэтому волны работают и после разрушения башен.
- Панель как в игре над картой: портреты, KDA, HP и мана, ульт и TP, счет, NW команд, время, день и ночь.
- Настройки слоев карты перенесены в меню-шестеренку в углу карты.
- Исправлена прокрутка списков Radiant и Dire.
- Новые данные: ники игроков, атрибуты, урон, броня, скорость, скорость атаки, опыт, урон по героям, лечение, поставленные варды и стаки, заряды скана, варды и Smoke в лавке.
- K/D врагов считается по убийствам с момента запуска радара.

# Обновление v2.1.0

- Герои в тумане войны: последняя позиция с мапхака и сколько секунд назад их видели.
- Линейные крипы в тумане: прогноз движения волны по линии до вражеской башни или встречной волны.
- Союзные и вражеские варды с радиусом обзора и временем жизни, руны и вышки в тумане.
- Лесные кемпы (есть крипы, пусто, стаки), нейтралы и курьеры включены по умолчанию у всех.
- Карточки героев: иконки предметов, нейтралки, рюкзака и способностей с перезарядками, LH/DN, золото союзников.
- Лента событий: Smoke, фарм леса и появление врага в тумане, новые вражеские варды, уничтоженные башни и казармы, места по ближайшей башне.
- На карте: линия телепорта с отсчетом, зона скана, иконки примененных способностей, переключатели слоев.

# Релиз v2.0.0

- Релизная версия: первая публикация скрипта.

---

# Cloud Radar (English)

## What it does

Shows your match map to friends in a browser: heroes, including those in the fog of war, creeps, wards, camps, runes, towers, Roshan and an event feed. No server needed: press Start and send the link.

- Map with hero, ward, rune and tower icons
- Heroes in the fog from maphack and predicted creep waves in the fog
- Items, abilities with cooldowns, KDA, net worth and buyback
- Event feed: deaths, runes, teleports, Smoke, jungle farming, wards, towers, Roshan and Tormentor
- Map and console on top of the game (picture in picture)

## Install

1. Place `web_radar.lua` in the `umbrella\scripts` folder.
2. Reload the Lua scripts.
3. Open `Scripts → Main → Cloud Radar`, enable the radar and press Start.
4. Copy the link from the Link field and send it to friends.

## Changelog

# Update v2.2.0

- Creep waves in the fog: every 30 seconds the script sends a wave down each lane and walks it until it meets the enemy wave or the first alive enemy tower. Visible creeps refine the meeting point.
- Tower positions are remembered, so waves keep working after towers fall.
- In-game style top bar above the map: portraits, KDA, HP and mana, ultimate and TP, score, team net worth, clock, day and night.
- Map layer settings moved to a gear menu in the map corner.
- Fixed scrolling in the Radiant and Dire lists.
- New data: player names, attributes, damage, armor, move speed, attack speed, XP, hero damage, healing, wards placed and stacks, scan charges, wards and Smoke in the shop.
- Enemy K/D is counted from kills since the radar started.

# Update v2.1.0

- Heroes in the fog of war: last maphack position and how many seconds ago they were seen.
- Lane creeps in the fog: the wave is predicted along its lane up to the enemy tower or the opposing wave.
- Allied and enemy wards with vision radius and time left, runes and towers in the fog.
- Neutral camps (occupied, empty, stacks), neutrals and couriers are now on by default for everyone.
- Hero cards: item, neutral item, backpack and ability icons with cooldowns, LH/DN, allied gold.
- Event feed: Smoke, enemy farming the jungle or spotted in the fog, new enemy wards, destroyed towers and barracks, places named by the nearest tower.
- On the map: teleport line with a countdown, scan area, icons of used abilities, layer toggles.

# Release v2.0.0

- Release version: the first publication of the script.
