# Best Friends Forever (OpenMW)

## Unreleased

- Moved the public API contract out of the README into an expanded `docs/API.md` with built-in defaults and reserved values.
- Added raw UI access to `I.BestFriendsForever`: `getRawUI`, `getFollowerWidget`, `refreshRawUI`, `rebuildRawUI`, and `registerRawUIMutator`.
- Added `I.BestFriendsForeverDown`, a local-only interface for choosing whether a would-be down becomes a down or real death.
- Added `I.BestFriendsForever.registerFollowerTooltipField` for player scripts.
- `registerFollowerTooltipField` now accepts `getLayout` callbacks returning complete UI layouts.
- `I.BestFriendsForever.setFollowerIcon` now takes a spec table with `recordIds` (string or list; `recordId` for one) or a `rule(actor)` function. Icon lookup is now ID map → rules → built-in class/creature-type fallback.
- Animunculi uses a rule; the four creature types are handled by the built-in fallback (textures still TODO).
- `I.BestFriendsForever` interface version is now 5.
- `BestFriendsForever_followerDown` is now also sent to the follower's local scripts.

## 3.0

- Complete mod rewrite
- Added Follower Icons (thx butts)
- Added unique Follower Icons to Biz'kuitz, Julan and Tetra the Pack Guar
- Added Tooltips to follower widgets
- Tooltips now show general info about the follower, their diseases and damaged stats
- Added follower Interaction Menu
- Added Companion Share, Wait Here, Follower Info and Repair Gear features to Interaction Menu
- Added interfaces to add new Follower Icons (unique or conditional), edit or expand Tooltips, add new Interactions and edit the Follower HUD
- Complete overhaul of the mod's settings (I won't list every change, check them for yourself)
- Added settigns presets
- Removed all GOTOs

## 2.0

- Added Ward module - module that will protect your followers from any diseases and stat damage
- Updated settings page with new renderers
- Updated the dependency checking module
- Updated the Follower Detection Util integration
- Improved Immortality's enemy retargeting system
- Added Water Breathing and Slowfall abilities to Immortality module, fixing followers being permanently stuck when downed in water and dying to fall damage
- Added a setting to Immortality to keep the follower down until the end of the combat
- Simplified Immortality's timer logic
- Improved teleporting heuristics, increasing max teleport distance and preferring tp positions out of the way of the player
- Added option to display labels on bars in percents (for some reason)
- Added more script names to the default blacklists (from Death and Taxes and TR)
- Adjusted some default settings values (I already forgot which ones myself)
- Mod now requires OpenMW 0.52 and Follower Detection Util 3.1

## 1.2.7

- Refixed the keybind issue (thx Arrean)

## 1.2.6

- Change the default keybing for Call from None to L for mod compatibility and engine features reasons. This should also eleviate keybing synchronization with the Meditation Skill mod. It's dumb and weird, I know
- Added Tharsten Heart-Fang's script to Immortality and Teleportation default blacklists

## 1.2.5

- Added a guardrail for the leader check to Catch Up script

## 1.2.4

- Added Morrowind Comes Alive guard and adventurer scripts to the default global blacklist

## 1.2.3

- Fixed lethal melee hits breaking the immortality script. Again

## 1.2.2

- Fixed "Command Effects Prevent Getting Knocked Down" setting being inverted

## 1.2.1

- Added a leader check guardrail for attaching scripts

## 1.2

- Changed how downed followers get up: instead of waiting till the end of combat, they lie down for a fixed amount of time. This would make it more reliable, probably more performant and feel more natural when knowcking them down when not in combat (accidentally or on purpose)
- Added "Death Chance" setting to Immortality
- Added script blacklist for Inquisitive Guards

## 1.1.5

- Fixed setting "Enable Icons" to False breaking the mod
- Fixed immortality breaking Loafy's Necromancy zombie death script

## 1.1.4

- Added compatibility for abot's Water Life
- Added follower widget count limit setting
- Split the "HUD Expansion Direction" settings into separate vertical and horizontal fields

## 1.1.3

- Fixed melee hits not triggering immortality
- Added a guardrail for HUD visibility updater

## 1.1.2

- Fixed HUD visibility settings. Again

## 1.1.1

- Fixed HUD visibility settings. Again

## 1.1

- Removed H3lp Yours3lf dependency
- Improved teleportation position heuristics to look better

## 1.0.8

- Fixed "When to Show Follower HUD" setting not always behaving as you'd expect it to
- Fixed immortality hit handlers not being detached correctly

## 1.0.7

- Fixed teleportation not taking "enabled" flag into account

## 1.0.6

- Streamlined and fixed script attachment/detachment mechanism. Again

## 1.0.5

- Fixed follower HUD displaying when it shouldn't 2: Electric Boogaloo

## 1.0.4

- Fixed script detachment
- Fixed Command spell handling
- Fixed follower HUD displaying when it shouldn't
- Fixed Call being able to trigger when the world is paused
- Improved "Command Effects Prevent Getting Knocked Down" setting description
- Hopefully made the mod a bug-free experience

## 1.0.3

- Fixed infinite loop during teleportation position calculation
- Removed leftover console prints

## 1.0.2

- Fixed Follower HUD not hiding with the rest of the HUD

## 1.0.1

- Fixed the Element Alignment setting

## 1.0

Initial release
