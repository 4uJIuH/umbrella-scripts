# BehaviorScoreHelper

повышает порядочность: авто GG, авто репорты, анти-тильт и авто лайк / raises your behavior score: auto GG, auto reports, anti-tilt and auto commend

<!-- releases:start -->
Скачать: [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.1.3/BehaviorScoreHelper.lua) — `behavior-score-helper-v2.1.3`, 2026-10-21

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`behavior-score-helper-v2.1.3`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v2.1.3) | 2026-10-21 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.1.3/BehaviorScoreHelper.lua) | 5 |
| [`behavior-score-helper-v2.1.2`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v2.1.2) | 2026-10-20 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.1.2/BehaviorScoreHelper.lua) | 2 |
| [`behavior-score-helper-v2.1.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v2.1.1) | 2026-10-19 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.1.1/BehaviorScoreHelper.lua) | 2 |
| [`behavior-score-helper-v2.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v2.1.0) | 2026-10-19 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.1.0/BehaviorScoreHelper.lua) | 0 |
| [`behavior-score-helper-v2.0.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v2.0.1) | 2026-10-19 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.0.1/BehaviorScoreHelper.lua) | 1 |
| [`behavior-score-helper-v2.0.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v2.0.0) | 2026-10-19 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v2.0.0/BehaviorScoreHelper.lua) | 0 |
| [`behavior-score-helper-v1.1.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v1.1.1) | 2026-10-15 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v1.1.1/BehaviorScoreHelper.lua) | 8 |
| [`behavior-score-helper-v1.1.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/behavior-score-helper-v1.1.0) | 2026-10-15 | [BehaviorScoreHelper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/behavior-score-helper-v1.1.0/BehaviorScoreHelper.lua) | 4 |

[Все релизы](https://github.com/4uJIuH/umbrella-scripts/releases?q=behavior-score-helper&expanded=true)
<!-- releases:end -->

## Что умеет

BehaviorScoreHelper берет на себя рутину порядочности в Dota 2: пишет приветствие и GG, репортит за токсичность, войс и препятствование игре, мутит спамеров пингами и лайкает всех после матча.

- Авто-приветствие в начале матча и авто GG после падения трона, в общий или командный чат
- Контроль своего чата: сдерживание всех сообщений, шанс отправки или запрет матов и осков; мут своего микрофона
- Репорт за токсичность: маты, оскорбления, спам сообщениями или любое сообщение; слова из файлов фильтров с белым списком
- Репорт за войс: союзник говорит дольше N секунд или просто включил микрофон
- Репорт за препятствование игре: ранний байбек, варды под своей базой, куча вардов в одной точке, вард под вражеской вышкой, денай своих вардов
- Анти-тильт: мут на старте матча, скрытие типов и пингов, мут за спам пингами и за пинги твоей смерти, опыта или героя
- Авто-комменд всех игроков на экране итогов, с паузой и кнопкой «Лайкнуть сейчас»
- Игроков из твоей пати можно не репортить и не мутить
- Уведомления на экране, в чате или в консоли
- Интерфейс на русском и английском через qLocalization

## Установка

1. Нажмите «Установить» в Script Manager: он загрузит `BehaviorScoreHelper.lua`, qLocalization и четыре файла фильтров в `umbrella\scripts` и `umbrella\scripts\filters`.
2. При ручной установке скачайте `BehaviorScoreHelper.lua`, четыре файла из папки `filters` и `!_qLocalizer.lua`; разместите их в соответствующих папках `umbrella\scripts` и `umbrella\scripts\filters`.
3. Перезагрузите Lua-скрипты.
4. Откройте `Scripts → Utility → Behavior Score`: вкладки Chat, Reports, Anti-Tilt и Utilities.

Примечание: GitHub скачивает библиотеку как `_qLocalizer.lua`; переименуй её в `!_qLocalizer.lua` перед загрузкой Lua-скриптов.

## Что нового

# Исправление v2.1.3

- Убраны лаги после падения трона: авто-лайк больше не ищет экран итогов каждый кадр, а проверяет его два раза в секунду и перестает через 5 минут.
- Скрытие тильт-уведомлений и мут за пинги по тебе не работают после конца игры, когда они уже не нужны.
- Авто GG больше не отправляется дважды в конце игры.

# Исправление v2.1.2

- Авто GG: убрана настройка «Пауза после падения трона». GG отправляется сразу после падения трона.

# Исправление v2.1.1

- «Не пускать маты и оски»: заблокированное сообщение не уходит в чат, а у тебя в чате появляется уведомление со словом, из-за которого оно задержано. Обычные сообщения отправляются как раньше.
- Фильтры теперь понимают шаблоны из файлов в `scripts/filters` (раньше многие строки не срабатывали) и всегда дополняются встроенным списком. Раньше пропускались слова вроде «гандон», «даун», «пидорас».
- Фильтры английского и русского мата и оскорблений сильно расширены.
- Ловятся латинские буквы и цифры внутри русских слов (`xуй`, `6лять`), цифры в английских (`sh1t`) и растянутые буквы (`суууука`). Обычные слова вроде «команда», «мандарин», «ссылка» не блокируются.
- Репорт за токсичность использует те же фильтры.

# Обновление v2.1.0

- Фильтр спама пингами: новый пункт «Репорт при муте». Когда игрок получает мут за спам пингами, скрипт также отправляет на него репорт за препятствование игре и за токсичность в чате. По умолчанию выключен.

# Исправление v2.0.1

- Выпадающие списки больше не сбрасываются после смены языка чита. Выбор хранится номером в `configs/behavior_score_helper.txt` и восстанавливается при загрузке.

# Обновление v2.0.0

- Скрипт переработан на основе версии 2.5: новые вкладки Chat, Reports, Anti-Tilt и Utilities.
- Новое: контроль своего чата, мут своего микрофона, репорт за войс, репорт за слив вардов, мут на старте, скрытие типов и пингов, мут за спам пингами и за пинги смерти, опыта или героя.
- Репорт за токсичность: выбор причины (маты, оскорбления, спам, любое сообщение), слова по-прежнему из файлов в `scripts/filters`.
- Авто-комменд лайкает всех игроков, есть пауза и кнопка «Лайкнуть сейчас».
- Игроков из пати можно не репортить и не мутить, уведомления на экране, в чате или в консоли.
- Отправленные репорты и приветствие запоминаются для матча, после перезагрузки скриптов не повторяются.
- Убраны: баннер репорта, запись репортов в файл, тихий режим, выбор героев для лайка и готовые фразы GG.
- Настройки скрипта один раз сбросятся на значения по умолчанию.

# Исправление v1.1.1

- Исправлены названия раздела и вкладок, которые отображались как ключи локализации.

# Обновление v1.1.0

- Добавлена локализация интерфейса на русский и английский языки через qLocalization.
- Script Manager устанавливает qLocalization вместе со скриптом.
- Добавлена ручная установка локализатора и файлов фильтров в инструкции.

# Обновление v1.0.0

- Первый релиз BehaviorScoreHelper.
- Авто GG и приветствие союзников в начале матча.
- Авто репорт токсичных сообщений по файлам фильтров (мат и запрещённые слова) с режимами поиска и белым списком.
- Авто репорт за ранний выкуп (фид).
- Авто лайк на экране итогов матча.
- Script Manager устанавливает скрипт вместе с файлами фильтров в `scripts/filters`.

---

# BehaviorScoreHelper (English)

## What it does

BehaviorScoreHelper takes care of the behavior score routine in Dota 2: it writes a greeting and GG, reports toxicity, voice spam and griefing, mutes ping spammers and commends everyone after the match.

- Auto greeting at match start and auto GG after the throne falls, to all chat or team chat
- Control of your own chat: block all messages, send by chance, or block profanity and insults; mute your own mic
- Toxic report: profanity, insults, message spam or any message; words come from the filter files, with a whitelist
- Voice report: an ally talks longer than N seconds or just turns on the mic
- Griefing report: early buyback, wards in own base, a pile of wards in one spot, a ward under an enemy tower, denying own wards
- Anti-tilt: mute at match start, hide tips and pings, mute for ping spam and for pinging your death, XP or hero
- Auto commend for every player on the end screen, with a delay and a Commend Now button
- Party members can be left out of reports and mutes
- Notifications on screen, in chat or in the console
- The interface is in Russian and English through qLocalization

## Install

1. Click Install in Script Manager to download `BehaviorScoreHelper.lua`, qLocalization, and the four filter files into `umbrella\scripts` and `umbrella\scripts\filters`.
2. For manual installation, download `BehaviorScoreHelper.lua`, the four files from the `filters` folder, and `!_qLocalizer.lua`; place them in the corresponding `umbrella\scripts` and `umbrella\scripts\filters` folders.
3. Reload the Lua scripts.
4. Open `Scripts → Utility → Behavior Score`: tabs Chat, Reports, Anti-Tilt and Utilities.

Note: GitHub downloads the library as `_qLocalizer.lua`; rename it to `!_qLocalizer.lua` before loading Lua scripts.

## Changelog

# Fix v2.1.3

- Fixed lag after the throne falls: auto commend no longer looks for the end screen every frame, it checks twice a second and gives up after 5 minutes.
- Hiding tilt alerts and muting for pings at you stop after the game ends, when they are no longer needed.
- Auto GG is no longer sent twice at the end of the game.

# Fix v2.1.2

- Auto GG: removed the "Delay after throne falls" setting. GG is sent as soon as the throne falls.

# Fix v2.1.1

- Block profanity and insults: a blocked message is not sent, and you get a notice in your chat with the word that stopped it. Normal messages are sent as before.
- The filters now understand the patterns in the `scripts/filters` files (many lines used to never match) and always include the built-in list. Words like "gandon", "daun" and "pidoras" used to get through.
- The English and Russian profanity and insult filters are much larger.
- Latin letters and digits inside Russian words (`xуй`, `6лять`), digits in English words (`sh1t`) and stretched letters (`fuuuck`) are caught. Normal words like "class", "assassin", "команда" are not blocked.
- The toxic report uses the same filters.

# Update v2.1.0

- Ping Spam Filter: new Report on Mute option. When a player is muted for ping spam, the script also reports them for griefing and for chat toxicity. Off by default.

# Fix v2.0.1

- Dropdowns no longer reset after the cheat language changes. The choice is stored as a number in `configs/behavior_score_helper.txt` and restored on load.

# Update v2.0.0

- The script is reworked on the base of version 2.5: new tabs Chat, Reports, Anti-Tilt and Utilities.
- New: control of your own chat, mute your own mic, voice report, ward griefing report, mute at match start, hiding tips and pings, mute for ping spam and for pinging your death, XP or hero.
- Toxic report: pick the reason (profanity, insults, spam, any message); words still come from the files in `scripts/filters`.
- Auto commend likes every player, with a delay and a Commend Now button.
- Party members can be left out of reports and mutes; notifications on screen, in chat or in the console.
- Sent reports and the greeting are remembered for the match and are not repeated after a script reload.
- Removed: the report banner, writing reports to a file, quiet mode, hero choice for commends and preset GG phrases.
- The script settings reset to defaults once.

# Fix v1.1.1

- Fixed the section and tab names that were displayed as localization keys.

# Update v1.1.0

- Added Russian and English interface localization through qLocalization.
- Script Manager now installs qLocalization with the script.
- Added manual installation instructions for the localizer and filter files.

# Update v1.0.0

- Initial release of BehaviorScoreHelper.
- Auto GG and a greeting for allies at the start of the match.
- Auto report for toxic chat messages using filter files (profanity and banned words), with search modes and a whitelist.
- Auto report for early buybacks (feeding).
- Auto like on the post-match screen.
- Script Manager installs the script together with the filter files into `scripts/filters`.
