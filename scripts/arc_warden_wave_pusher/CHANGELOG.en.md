# 1.2.0

- The smart Magnetic Field placement is fully redesigned: the dome covers the most allied creeps and separately prioritizes catapults.
- During a push, the tower stays outside the dome and keeps attacking the protected creeps.
- The clone enters the placed dome and tries not to leave it during the push.
- Added near-death dome: before disappearing, the clone calculates where allied and enemy waves meet and leaves Magnetic Field there. Works even without a tower.
- If the dome point is far away, the clone moves into cast range in advance.
- Added a display of the future dome position with its real radius and the number of creeps inside.
- Display settings let you choose the effect, the radius colour, the counter colour and size, and the display range.
- Spark Wraith logic is improved: the clone prioritizes Dars and Standard Bearers, accounts for incoming allied creep attacks and does not waste the ability.
- After Spark, the clone adds an extra point when it is needed for a guaranteed kill, and makes no unnecessary attacks.
- Regular creeps are still handled by standard AutoPlay when there are no priority targets.
- Updated display of the current push target: cleaner effects, colour and size settings.
- Removed the smart gun toggle key: the included addon controls the gun automatically.
- Fixed a Tempest Double timer bug that stopped the near-death dome from triggering.
- Added Russian and English localization, plus addon debugging options in settings.

# 1.1.0

- Added an option for the clone to yield control to combos and pause pushing when an enemy hero is nearby.
- The option is available in Russian and English and is enabled by default.

## 1.0.1

- Added Russian and English menu localization based on the selected Umbrella language.
- Auto-play logic and target priorities are unchanged.
