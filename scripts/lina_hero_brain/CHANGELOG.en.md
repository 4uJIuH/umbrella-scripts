# Update v0.5.183

- The author did not describe the changes in this version.

# Update v0.5.180

- The author did not describe the changes in this version.

# Release v0.5.173

- Lina brain v0.5.173. First public release.
- A decision-making companion for UCZone's built-in Lina script. The framework keeps doing the routine work (orbwalk, items, target picking); the brain adds the cross-tick, Lina-specific decisions on top. It stays silent until you press the combo key or a real threat appears.
- Offense (combo key): adaptive W/Q/R burst combos, five archetypes picked by what the target is exposed to (Ethereal / Eul / Wind Waker / fast WQR / R-first); team-fight mode at 3+ enemies; auto-R kill-steal; and cannot-kill targeting that skips a target under Shallow Grave / False Promise / WK Reincarnation.
- Defense (always on, no key): a fact-driven save chain that only offers saves which actually counter the incoming threat; cast-point timing so a save lands on a delayed nuke (Sniper R, Doom) instead of firing early; a per-threat lock that stops two saves firing on one threat; and line-projectile / hook intercept (Pudge Hook, Mirana Arrow, Skewer, Hookshot).
- Flame Cloak arbiter: picks FC's best use each tick, offensive amp, defense reserve, escape over terrain, chase cutoff, or a value-weighted teamfight flip.
- Patch-resilient data: threat and ability catalogs are generated from Valve's KV files, so one regen after a patch keeps the numbers current.
- Menu: 26 controls, the essentials plus per-subsystem kill-switches; validated behaviors are hardcoded rather than toggled.
