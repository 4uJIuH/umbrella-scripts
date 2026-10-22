# Fix v2.6.1

- The 10 Hz mode is back, as Smooth used to be: "Fast, 10 Hz" sits between Balanced and Smooth (20 Hz) in both settings, send rate and collection rate.

# Update v2.6.0

- Smooth mode updates the site almost instantly: 20 Hz with up to 8 packets in flight, and the radar no longer waits for the reply to the previous packet. Balanced keeps up to 2 packets in flight, Eco one. The Smooth choice may reset to Balanced once; pick it again.
- A dropped connection to the server (common when a provider blocks it) no longer pauses sending for several seconds or forces a full resend: only what did not arrive is sent again.
- Fixed the game freezing and crashing after the throne falls. As soon as the match ends, the radar stops touching game objects and handling events, sending slows to once every 2 seconds, and server replies that arrive at that moment can no longer crash the game.
- The load line shows the ping to the server.
- Site: a new broadcast-style look with a large score and match clock, the game's team colors and a narrow typeface for numbers. The page fits a phone screen.
- Site: heroes move along the exact match timeline and glide between packets, without jerks on an uneven connection. The map draws at the screen refresh rate, and the side panels update at most 4 times per second.

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
