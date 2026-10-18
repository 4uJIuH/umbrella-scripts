# Update v2.5.3

- yandex music: playlists. a plus button in the expanded player adds or removes the current track from your playlists (off by default, music > playlists)
- yandex music: like, shuffle and repeat answer with an error when the player didn't react, the heart waits for the real answer
- setting to center a short track title in the small island, setting to hide the artist there, background opacity when glass mode is off
- the clock in the main menu follows the chosen short view, 12 hour mode drops the seconds

# Update v2.5.2

- courier delivery rework: follows the courier through the stash, learns the fountain speed zone, notices cancelled deliveries and a dead courier, delivery sound has its own switch
- music in the main menu is on by default, the search timer drops into a side bubble over it
- yandex music: likes and volume work inside the player itself (the bridge adds a debug port flag to its shortcuts, restart the player once)
- spotify likes are read live, not only toggled
- roshan: health watcher, aegis claim through chat events, "stack until minute" slider
- while the cursor is over the island, umbrella wheel zoom switches to keys so scrolling the volume doesn't zoom the camera
- debug log catches slow and unsent bridge requests, the island says so when umbrella holds the answers back
- fix: kill notification showed the victim's icon instead of the killer's

# Update v2.5.1

- fixes random freezes of the whole game and the bridge hanging after them: the bridge no longer hammers windows audio (ducking held every audio session open and rescanned them every few ms, each media poll scanned them three times)
- the bridge answers requests on worker threads, so one slow call can't block the rest
- sounds can't pile up: the same sound is dropped if it repeats within 70 ms, at most 10 play at once
- the script doesn't send a new poll while the previous one is still waiting
- the "what's new" card doesn't come back on patch updates

# Update v2.5.0

- two live activities at once: music in the pill, fight, courier, pause or timer in the side bubble. hold a bubble to swap it with the island, swipe any bubble away
- the expanded island no longer collapses when a notification, fight or courier arrives
- synced lyrics in the player and in the small island, tap a line to jump
- real face id when you accept a match or the courier delivers, sdk call DynamicIsland.FaceID
- match found is a regular alert now: own priority, sound switch, respects do not disturb
- accessibility: reduce motion, bold text, increase contrast
- real sf symbols everywhere, the bridge installs the icon font next to the scripts and into umbrella fonts
- sdk api 2: scripts add their own widgets to the widget editor
- bridge: cider, musicbee, winamp and qobuz support, waveform falls back to the device meter, yandex music volume and ducking fixed, no more false "bridge not connected"
- covers no longer get mixed up after a bridge restart
- clicks over the island no longer reach dota in the main menu
- every setting got a short tooltip, settings save as soon as you change them

# Update v2.4.0

- hello screen and a setup assistant on first launch: bridge, size, look, alerts, likes and focus in a few taps
- new widget editor: drag widgets around, add and remove them, recolor with an ios color picker (grid, spectrum, sliders)
- swipe a notification or a side bubble sideways to close it, repeats in the notification center stack up
- live waveform that moves with what's actually playing
- music can show in the main menu too, media > show in main menu
- every alert has its own sound switch, alert sounds and interface sounds are separate with their own volume
- water, bounty and wisdom runes got their own priority and duration
- sdk for other scripts: notifications, live activities, action buttons and a permission prompt like on iphone. guide in docs/sdk.md and on https://rootq.gitbook.io/rootq-docs/
- debug log with a timeline for bug reports, plus a recording dot while it's on
- folders and links opened from the island come to the front over dota
- the island no longer pops open right after you swipe something away
- hello hides the chat and closes the umbrella menu while it plays

# Update v2.3.0

- no sf pro fonts yet? the island offers to install them in one click, no admin rights needed
- the island scales itself on first launch, so it looks right on 1440p and 4k
- dragging is smooth now and snaps to the center of the screen with a thin guide, like on iphone
- the widget editor shows your widgets live even in the main menu
- if the bridge isn't running, the island tells you once instead of silently losing music and sounds
- one broken piece can't take the whole island down anymore, plus a debug log switch if something acts up
- works with the new umbrella folder, config and covers go where umbrella wants them
- turning off spotify likes now really closes the debug port, the bridge stops touching spotify's shortcuts. full likes guide: docs/spotify-likes.md
- updates in one click from here on, the island installs the next version by itself

# Update v2.2.0

- updates, notification center and system alerts
- updates right from the island: a new version shows up in the menu, hit update and it downloads, installs and restarts on its own. this is the last time you update by hand
- what's new card after every update
- notification center: expand the island and scroll down to see your last alerts, even the ones do not disturb kept quiet
- system alerts: headphones or speakers switching, windows sound muted, laptop charging and low battery
- press and hold to expand, like on iphone (settings > more)
- show all screens button to see every island state without a match
- track titles scroll like in apple music, long podcasts show hours
- "+2" on an alert when more are waiting
- notification sound plays when the alert shows up, not when it gets queued, and doesn't double up anymore
- the haptic engine switch now mutes every sound, reminders got their own chime
- rounded shadows everywhere, new color picker, ios spinner
- moon in do not disturb takes the artwork color
- light island theme and russian texts cleaned up
- less work per frame
- covers go to scripts/dynamic_island_covers and old ones get cleaned up, no more pile of jpgs in your scripts folder

# Update v2.1.0

- ios look pass
- sf pro text everywhere, sizes and weights like on ios
- ios system colors, secondary text is see-through white like on iphone
- all icons redrawn in sf symbols style, player buttons too
- timers don't wobble anymore, digits are fixed width
- one set of apple springs for everything, island feels calmer
- content inside the island moves together with the shape, no more popping or teleporting
- fight radar restyled, round avatars and markers like in find my
- fps and ping don't jump every half second, they turn orange or red when things go bad
- wave color comes from the artwork properly, white covers get a white wave
- new toggles: track title in the small island, wave color from artwork

# Release v2.0.0

- first proper release
- media bridge is one exe now, sounds inside, closes together with dota
- match flow in the menu: queue, accept countdown, who accepted, draft
- do not disturb, your own reminders, rampage timer
- side bubbles that pop out of the island, rolling digits
- new menu, everything extra is hidden in gears
- spotify likes keep working after spotify updates
