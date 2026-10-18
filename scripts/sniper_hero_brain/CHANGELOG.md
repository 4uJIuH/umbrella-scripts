# Релиз v6.15.277

- Fixed: brain wasted Assassinate on Dazzle's Shallow Grave and Oracle's False Promise. Both abilities prevent the kill entirely during their window, so committing R was throwing the 50-100s cooldown for no result. Now the brain skips R on enemies with either modifier active. Force key still works if you want to manually commit anyway.
- Also from v6.15.276 (last week): R no longer fires on short channels like Keeper of the Light's Illuminate that finish before the 2s cast lands. Only the long, worth-it channels still get the auto-interrupt: Black Hole, Freezing Field, Dismember, Fiend's Grip, Death Ward, Static Storm, Life Drain. Plus TP-outs.
