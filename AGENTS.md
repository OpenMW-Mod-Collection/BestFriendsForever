# Best Friends Forever — agent notes

## Repo shape

- OpenMW 0.52+ Lua-only mod. `BestFriendsForever.omwscripts` is the authoritative entrypoint list; source lives under `scripts/BestFriendsForever/`. There is no build, test, lint, typecheck, codegen, or CI config.
- No `.esp`: `load.lua` (LOAD context) creates `BFF_Immortality` and the injury spells at runtime from `common/injuries.lua`.
- `BestFriendsForever.zip` is an ignored/untracked packaging artifact, not source. `.luarc.json` is also ignored and machine-local: it wires LuaLS to a Cod3x checkout and `omw_context_plugin.lua`.
- Follower Detection Util must load before BFF. `player.lua` checks `I.FollowerDetectionUtil.version >= 7` and `FollowerDetectionUtil.omwscripts`; failure logs and shows a popup via `utils/dependencyChecker.lua`. (README names the FDU mod version 3.1.)

## Contexts and wiring

- Every script starts with `---@omw-context ...`; editor diagnostics depend on it. Keep the annotation correct when adding files.
- MENU: `settingsPlayer.lua` (pages + player groups) and `settingsRenderers/*`. GLOBAL: `settingsGlobal.lua`, `global.lua`. PLAYER: `player.lua` merger plus `playerHandlers/*` (combat, teleport, menu, repair UI, HUD, raw UI access, `I.BestFriendsForever` interface). `actor.lua` runs as NPC/CREATURE local script.
- `global.lua` attaches/detaches `followerScripts/*` on `FDU_SyncFollowerList`; CUSTOM lines in `.omwscripts` do not by themselves give followers a module.
- New setting groups need a file in `settings/` **and** an entry in the explicit list in `settingsPlayer.lua` or `settingsGlobal.lua`. Section scope (`playerSection` vs `globalSection`) must match the script context; runtime reads are cached via `utils/settingsCache.lua`, so key/section renames must be updated at registration, cache, and readers.
- Renderer IDs (`SuperSlider6`, `SuperSelect3`, `SuperColorPicker2`, `*_V1`) are referenced by other mods via `InstalledSettingsRenderers`; don't rename them casually. UI strings live only in `l10n/BestFriendsForever/en.yaml`; cross-context messages use `BestFriendsForever_*` events.

## Gotchas and verification

- `global.lua` passes `ResyncAll` to `settingsCache.new` before assigning it, so toggling settings does not currently resync follower scripts; script attachment happens on the FDU list event. Account for this when changing toggle behavior.
- `playerHandlers/teleport.lua:frame` gates HUD updates behind a 0.1 s teleport cooldown via `player.lua:onUpdate`, so a HUD `pollingRate` below 0.1 s does not increase update frequency.
- Save/load state lives in `onSave/onLoad` of `playerHandlers/combat.lua` (merged by `player.lua`), `actor.lua`, `globalHandlers/*` (merged by `global.lua`), and `followerScripts/teleport.lua`; keep `data or {}` defaults for old saves when adding state.
- Raw UI mutators are runtime-only registrations; external player scripts must re-register them after load. Raw Element handles are invalidated when BFF rebuilds its UI.
- No automated verification exists. Check changes in-game with OpenMW + FDU, on both a new game and an existing save; `docs/API.md` is the public interface contract implemented by the player handlers.
