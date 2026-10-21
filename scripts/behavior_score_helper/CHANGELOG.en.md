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
