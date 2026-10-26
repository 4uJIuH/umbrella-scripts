# Grimstroke Helper

подбирает цели для Ink Swell и управляет Dark Portrait / selects Ink Swell targets and controls Dark Portrait

<!-- releases:start -->
Скачать: [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.4.2/grimstroke_helper.lua) — `grimstroke-helper-v1.4.2`, 2026-10-21

| версия | дата | файл | загрузок |
| --- | --- | --- | --- |
| [`grimstroke-helper-v1.4.2`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/grimstroke-helper-v1.4.2) | 2026-10-21 | [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.4.2/grimstroke_helper.lua) | 46 |
| [`grimstroke-helper-v1.4.1`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/grimstroke-helper-v1.4.1) | 2026-10-20 | [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.4.1/grimstroke_helper.lua) | 16 |
| [`grimstroke-helper-v1.4.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/grimstroke-helper-v1.4.0) | 2026-10-19 | [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.4.0/grimstroke_helper.lua) | 10 |
| [`grimstroke-helper-v1.3.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/grimstroke-helper-v1.3.0) | 2026-10-19 | [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.3.0/grimstroke_helper.lua) | 4 |
| [`grimstroke-helper-v1.2.0`](https://github.com/4uJIuH/umbrella-scripts/releases/tag/grimstroke-helper-v1.2.0) | 2026-10-19 | [grimstroke_helper.lua](https://github.com/4uJIuH/umbrella-scripts/releases/download/grimstroke-helper-v1.2.0/grimstroke_helper.lua) | 3 |
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

# Обновление 1.4.2

- Окно помощника обновлено до новой версии интерфейса: шрифт как в меню Umbrella, кнопки подсвечиваются цветом акцента при наведении.
- Стрелка в заголовке стоит со стороны края экрана, к которому ближе окно.
- Кнопка прижатия к краю работает из любого места экрана: окно само переезжает к ближайшему краю.
- Вкладка прижатого окна стала крупнее и по высоте совпадает с заголовком.

# Обновление 1.4.1

- Фильтр Dark Portrait: встроенное комбо больше не кастует Dark Portrait на неотмеченного врага после повторного нажатия клавиши комбо.
- Фильтр Dark Portrait: Dark Portrait разрешен и на врага, связанного Soulbind с отмеченным врагом.
- Фильтр Dark Portrait: если при зажатой клавише комбо курсор переходит на другого врага, Dark Portrait кастуется, только когда разрешены и первая цель, и новая.
- Ink Swell: дистанция от союзника до врага теперь работает во всех режимах, включая «Разрешенный, ближайший к врагам».
- Исправлены ошибки Lua, когда иллюзия или ее цель исчезает.

# Обновление 1.4.0

- Окно помощника выглядит как панели самого Umbrella (Illusion Controller, Wards): цвета берутся из меню чита, заголовок с переключателем и фильтрами слева, названием по центру и красной стрелкой справа.
- Одно окно вместо панели союзников и отдельного окна фильтров: кнопка фильтров в заголовке переключает страницу, клавиша фильтров открывает сразу ее.
- Переключатель в заголовке ставит автоматику на паузу. Окно скрывается из меню или клавишей панели.
- Окно можно прижать к левому или правому краю экрана и спрятать в него: остается маленькая вкладка со стрелкой и переключателем автоматики.
- Размер окна настраивается в шестеренке у «Включить».
- Иконки неиспользуемого списка приглушены: союзники, когда Ink Swell выбирает любого союзника, враги, когда фильтр выключен.

# Обновление 1.3.0

- Новая панель на экране: союзники для Ink Swell показаны иконками, клик по иконке разрешает или запрещает Ink Swell. Зеленая точка значит, что рядом с союзником есть враг.
- В заголовке панели переключатель паузы, кнопка сворачивания и кнопка закрытия.
- Окно «Фильтры комбо» с обоими списками (Dark Portrait и соло Soulbind): иконки врагов и свой переключатель у каждого списка. Изменения в окне и в меню синхронизируются.
- Новые клавиши: показать или скрыть панель и открыть или закрыть окно фильтров.
- Все надписи панели на русском и английском, имена героев берутся из игры.
- Списки в меню компактные и не наезжают друг на друга, пока врагов нет.
- Отладка в лог (шестеренка у «Включить»): пишет клики по панели и нажатия клавиш.
- Оптимизация: Dark Portrait и Ink Swell проверяются реже, отрисовка не создает лишних объектов каждый кадр.

# Обновление 1.2.0

- Меню переделано: четыре группы в две колонки (помощник, Ink Swell, иллюзия Dark Portrait, встроенное комбо), у каждого пункта иконка и подсказка. Пункты гаснут, когда выключен их переключатель.
- Меню переведено на русский и английский и следует языку чита. Библиотека перевода встроена в файл, ставить ее отдельно не нужно.
- Настройки помощника один раз сбросятся на значения по умолчанию, потому что пункты меню переименованы. Отмеченные герои в белых списках сохраняются.

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

# Update 1.4.2

- The helper window uses the new interface version: the font matches the Umbrella menu, buttons light up in the accent colour on hover.
- The header chevron sits on the side of the screen edge the window is closer to.
- The dock button works from anywhere on the screen: the window moves to the nearest edge by itself.
- The docked tab is larger and as tall as the header.

# Update 1.4.1

- Dark Portrait filter: the built-in combo no longer casts Dark Portrait on an unmarked enemy after the combo key is released and pressed again.
- Dark Portrait filter: Dark Portrait is also allowed on an enemy bound by Soulbind to a marked enemy.
- Dark Portrait filter: if the enemy under the cursor changes while the combo key is held, Dark Portrait is cast only when both the first target and the new one are allowed.
- Ink Swell: the ally-to-enemy distance now works in every mode, including "Allowed ally closest to enemies".
- Fixed Lua errors when an illusion or its target disappears.

# Update 1.4.0

- The helper window looks like Umbrella's own panels (Illusion Controller, Wards): colours come from the cheat menu, the header has the switch and filters on the left, the title in the middle and a red chevron on the right.
- One window instead of the ally panel and a separate filters window: the filters button in the header switches the page, the filters key opens it directly.
- The header switch pauses the automation. Hide the window from the menu or with the panel key.
- Drag the window to the left or right screen edge to dock it there: only a small tab with a chevron and the automation switch stays.
- Window size is set in the gear next to Enable.
- Icons of a list that is not in use are dimmed: allies when Ink Swell picks any ally, enemies when their filter is off.

# Update 1.3.0

- New on-screen panel: Ink Swell allies are shown as icons, click an icon to allow or forbid Ink Swell. A green dot means an enemy is near that ally.
- The panel header has a pause switch, a fold button and a close button.
- "Combo Filters" window with both lists (Dark Portrait and solo Soulbind): enemy icons and a switch for each list. Changes sync with the menu.
- New keys: show or hide the panel and open or close the filters window.
- All panel text is in English and Russian, hero names come from the game.
- Menu lists are compact and no longer overlap while there are no enemies.
- Debug log (gear next to Enable): logs panel clicks and key presses.
- Optimization: Dark Portrait and Ink Swell are checked less often, drawing no longer creates extra objects every frame.

# Update 1.2.0

- Reworked menu: four groups in two columns (helper, Ink Swell, Dark Portrait illusion, built-in combo), with an icon and a tooltip on every item. Items grey out when their switch is off.
- The menu is translated into English and Russian and follows the cheat language. The translation library is embedded in the file, nothing else to install.
- Helper settings reset to defaults once because the menu items were renamed. Heroes checked in the whitelists are kept.

# Update 1.1.0

- Dark Portrait whitelist: the built-in combo casts Dark Portrait only on checked enemies. On other enemies it skips Dark Portrait and uses the other abilities as usual.
- Soulbind whitelist: with the level 15 talent, the combo Soulbinds a checked enemy even when no second enemy is nearby. Other enemies keep the original logic: Soulbind is cast only when a second enemy is in link range.
- Both lists work on the built-in combo key. Settings: Heroes → Grimstroke → Helper → Combo Whitelists.

# Update 1.0.0

- Initial release of the Grimstroke Ink Swell and Dark Portrait helper.
