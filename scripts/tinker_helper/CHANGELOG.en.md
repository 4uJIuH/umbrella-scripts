# Fix v1.0.1

- The script no longer breaks other scripts. It used to replace the shared `Config` module with its own menu, so scripts loaded after it could not read or save their settings.
- The internal `State` and `Constants` tables and the `L` function are no longer global and no longer clash with other scripts' variables.
- The script no longer adds its own function to the shared `Camp` module.
- Neutral creep search uses a valid unit filter.

# Release v1.0.0

- Release version: the first publication of the script.
