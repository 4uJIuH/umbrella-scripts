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
