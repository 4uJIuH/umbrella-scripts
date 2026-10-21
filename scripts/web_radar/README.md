# Cloud Radar

живой радар матча для друзей по ссылке / live match radar for friends via a link

<!-- releases:start -->
Скачать: [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.5.0/web_radar.lua) — `web-radar-v2.5.0`, 2026-10-21

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`web-radar-v2.5.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.5.0) | 2026-10-21 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.5.0/web_radar.lua) | 0 |
| [`web-radar-v2.3.3`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.3.3) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.3.3/web_radar.lua) | 72 |
| [`web-radar-v2.3.2`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.3.2) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.3.2/web_radar.lua) | 3 |
| [`web-radar-v2.3.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.3.1) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.3.1/web_radar.lua) | 0 |
| [`web-radar-v2.3.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.3.0) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.3.0/web_radar.lua) | 0 |
| [`web-radar-v2.2.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.2.1) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.2.1/web_radar.lua) | 0 |
| [`web-radar-v2.2.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.2.0) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.2.0/web_radar.lua) | 1 |
| [`web-radar-v2.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/web-radar-v2.1.0) | 2026-10-19 | [web_radar.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/web-radar-v2.1.0/web_radar.lua) | 1 |

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
3. Откройте `Scripts → Scripts → Cloud Radar`, включите радар и нажмите Start.
4. Скопируйте ссылку из поля «Ссылка» и отправьте друзьям.

## Что нового

# Обновление v2.5.0

- Радар работает и когда вы смотрите чужой матч зрителем, а не только в своем. Зрителю на сайт уходят KDA, золото и последний байбек всех десяти игроков, а лавка показана для Radiant и Dire.
- Новая настройка «Частота сбора»: как часто радар читает игру (герои, предметы и способности, обход карты). Прежний «Режим» стал «Частотой передачи» и отвечает только за отправку на сайт; она не бывает чаще сбора.
- Поиск фризов: если игра замирает дольше полсекунды, строка нагрузки в меню показывает длительность фриза, время работы радара и самую медленную часть (сбор, сеть, события или игра). С включенной отладкой подробности уходят в лог.
- История применений способностей и счетчики эффектов очищаются, когда юнит исчезает, а не копятся до конца матча.

# Исправление v2.3.3

- Игра больше не начинает тормозить к середине и концу матча. Радар заново проходил весь список замеченных способностей и отправлял полный пакет каждый раз, когда игра переиспользовала номер сущности (новый крип вместо умершего). Теперь это занимает одно действие, а полный пакет уходит только при смене героя.
- Удаление сущностей, которые радар не отслеживает (снаряды, крипы вне радара, служебные объекты), больше не запускает лишнюю очистку и внеочередной обход карты.
- Варды без известного таймера забываются через 6 минут для обсервера и 7 минут для сентри, а не висят в памяти до конца матча.
- Кэш звуков ограничен по размеру.
- С включенной отладкой радар раз в 30 секунд пишет в лог память Lua, время сбора и размер своих таблиц.

# Исправление v2.3.2

- Статус в меню скрипта показывает реальное состояние радара, а не «выключен». Строка нагрузки тоже обновляется.
- Подписи в меню короче и больше не обрезаются.
- Сайт: панель целей стала списком, по одной строке на цель. Глиф, скан и заряды показаны цветными метками Radiant и Dire, лавка показана иконками предметов.
- Карта стала крупнее, а лишняя ширина отдается боковым панелям. Шестеренка слоев стоит в углу самой карты, легенда помещается в одну строку.
- Перезарядки больше минуты показаны как 2:34. Рядом со временем матча видно, что наступит дальше: день или ночь.

# Исправление v2.3.1

- Скрипт переехал: Scripts › Scripts › Cloud Radar. Настройки сбрасываются один раз, включите радар заново.
- Меню из двух вкладок. Main: включение, Start и Stop, статус, режим нагрузки, нагрузка и ссылка для друзей. Data: что передавать на сайт.
- Режим нагрузки теперь сам задает частоту передачи (3, 5 или 10 Гц). Отдельная «Частота передачи» и кнопки пресетов, которые спорили с ним, убраны.
- «Передавать события» стоит во главе типов событий и гасит их, когда выключен. Информация о героях гаснет, когда выключен слой «Герои».
- Изменения в меню применяются сразу, без задержки.

# Обновление v2.3.0

- Оптимизация: меньше нагрузки на FPS. Тяжелые части (юниты, варды, руны, кемпы, цели, детали героев) обновляются реже, чем позиции героев, и кодируются только когда пора.
- Режимы нагрузки теперь управляют всем: частотой передачи, обновлением каждой части, бюджетом сканирования юнитов за кадр, курьерами, крипами, Рошаном и деталями героев.
- Экономный режим для слабых ПК, Сбалансированный по умолчанию, Плавный для самой быстрой карты.
- Когда радар выключен, скрипт не обрабатывает события игры.
- Имена частиц и звуков кэшируются, в драках меньше работы на каждый эффект.

# Исправление v2.2.1

- В списке способностей остались только способности героя: ивентовые вроде Season Dark Carnival больше не показываются.
- Верхняя панель переделана: названия команд и NW над героями, крупный счет, время и день или ночь в центре, индикатор готовности ульта на портрете.
- Справа одна карточка «Герои» с прокруткой и разделами Radiant и Dire. Шестеренка в ее углу выбирает, кого показывать: обе команды, только союзников или только врагов.

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
3. Open `Scripts → Scripts → Cloud Radar`, enable the radar and press Start.
4. Copy the link from the Link field and send it to friends.

## Changelog

# Update v2.5.0

- The radar also works when you watch someone else's match as a spectator, not only in your own. For a spectator it sends KDA, gold and last buyback for all ten players, and the shop stock for both Radiant and Dire.
- New setting "Collection rate": how often the radar reads the game (heroes, items and abilities, map scan). The old "Mode" is now "Send rate" and only controls sending to the site; it is never faster than collection.
- Freeze finder: if the game stalls for more than half a second, the menu load line shows the freeze length, the radar's own time and its slowest part (collection, network, events or the game). With debug on, the details go to the log.
- Ability use history and effect counters are cleared when a unit is removed instead of piling up until the match ends.

# Fix v2.3.3

- The game no longer starts lagging in the middle and late match. Each time the game reused an entity number (a new creep in place of a dead one), the radar walked its whole list of seen abilities and sent a full packet. Now this is a single step, and a full packet goes out only when a hero changes.
- Removing entities the radar does not track (projectiles, creeps outside the radar, helper objects) no longer runs extra cleanup and an early map scan.
- Wards with no known timer are forgotten after 6 minutes for an observer and 7 minutes for a sentry instead of staying in memory until the match ends.
- The sound cache has a size limit.
- With debug on, the radar logs Lua memory, collect time and the size of its tables every 30 seconds.

# Fix v2.3.2

- The script menu status shows the real radar state instead of "off". The load line updates too.
- Shorter menu labels that no longer get cut off.
- Site: the objectives panel is a list with one row per objective. Glyph, scan and charges use Radiant and Dire color tags, and the shop stock uses item icons.
- The map is larger, and spare width goes to the side panels. The layers gear sits in the corner of the map itself, and the legend fits on one line.
- Cooldowns over a minute show as 2:34. Next to the match clock you can see what comes next: day or night.

# Fix v2.3.1

- The script moved to Scripts › Scripts › Cloud Radar. Settings reset once, turn the radar on again.
- Two menu tabs. Main: enable, Start and Stop, status, load mode, load readout and the link for friends. Data: what is sent to the site.
- The load mode now sets the send rate itself (3, 5 or 10 Hz). The separate Send rate combo and preset buttons that fought it are gone.
- "Send events" heads the event types and greys them out when off. Hero info greys out when the Heroes layer is off.
- Menu changes apply at once.

# Update v2.3.0

- Optimization: less FPS cost. Heavy parts (units, wards, runes, camps, objectives, hero details) refresh less often than hero positions and are encoded only when due.
- Load modes now control everything: send rate, refresh of each part, unit scan budget per frame, couriers, creeps, Roshan and hero details.
- Economy for weak PCs, Balanced by default, Smooth for the fastest map.
- With the radar off, the script skips game event processing.
- Particle and sound names are cached, so fights cost less per effect.

# Fix v2.2.1

- The ability list shows only the hero's own abilities: event ones like Season Dark Carnival are gone.
- Reworked top bar: team names and net worth above the heroes, a large score, clock and day or night in the middle, an ultimate ready indicator on the portrait.
- One scrolling "Heroes" card on the right with Radiant and Dire sections. The gear in its corner picks whom to show: both teams, allies only or enemies only.

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
