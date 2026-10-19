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
