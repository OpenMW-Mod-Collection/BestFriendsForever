# Best Friends Forever - Follower HUD and QoL (OpenMW)

What if I said that your followers don't have to feel like a burden? That you can get modern follower experience in this fossil of a game?

What initially started as "[Attend Me](https://www.nexusmods.com/morrowind/mods/51232), but less laggy" gradually evolved into something far more greater. And still less laggy, by the way :D

In short, BFFs features can be split into 3 groups:

1. Utility Scripts
    - **Teleportation** - your followers will teleport to you anywhere and everywhere
    - **Catch Up** - your followers will always keep up with you
    - **Immortality** - instead of dying, your followers will fall on the ground until the end of combat
    - **Call keybind** - will teleport all your followers to you. Usually, out of your way
    - **Ward** - automatic disease curing and stat restoration (cheat zone, disabled by default)
2. Follower HUD
    - Health, fatigue and magicka bars
    - Hand drawn custom follower icons
    - Icon with selected weapon, spell or enchantment when in combat
    - Tooltips with current diseases and damaged stats
3. Interaction Menu
    - **Companion Share** with anyone
    - **Repair Gear** - opens repair menu only with follower's gear
    - **Stats Window** - with the exact stats they have
    - **Stop Combat** - makes follower stop the current fight
    - **Wait** - pause follower from following you, until the next interaction with them

Each feature, as always, as configurable as reasonably possible.

## Compatibility

Safe to install or update mid-playthrough. When removing the mod, make sure no follower is currently downed and they don't have a speed boost.

Should be compatible with anything. Though Immortality and Teleport modules might break certain scripted events. If you encounter this, use script blacklist and let me know about the issue so I could add a rule to the default config.

It is technically compatible with [Attend Me](https://www.nexusmods.com/morrowind/mods/51232), but they should not be used together.

### Builtin Support

Script blacklist:

- [Loafy's Necromancy - Reanimate Dead](https://www.nexusmods.com/morrowind/mods/58901) by TheLoafyOne
- [Water Life](https://www.nexusmods.com/morrowind/mods/42417) by abot
- [Inquisitive Guards](https://www.nexusmods.com/morrowind/mods/46538) by RubberMan
- [Morrowind Comes Alive](https://www.nexusmods.com/morrowind/mods/6006) by Neoptolemus and Morrowind community

Icon packs:

BFF ships `Default` and `Flat` presets under `textures/bff/icons` (`default` and `flat` folders). Copy a folder to make a custom pack; textures are named `category_key.png` with underscores and spaces allowed in keys. Unique icons use `id_<recordId>` and match automatically, `background.png` overrides the icon background, and missing files fall back to `default`. Built-in support includes icons for:

- [Biz'Kuitz Blissful Mind - Alfiq Scholar Companion](https://www.nexusmods.com/morrowind/mods/59156) by 6moonless
- Julan, Ashlander Companion by Kateri
- [Tetra the Pack Guar](https://www.nexusmods.com/morrowind/mods/47928) by Tizzo

## Requirements

Load Best Friends Forever as high as possible in the load order - before any mods that might alter melee damage calculations.

- OpenMW 0.52 or newer
- [Follower Detection Util](https://www.nexusmods.com/morrowind/mods/58053) version 3.1 - Load before BFF

## Recommended Mods

For an ultimate follower experience ;)

- [Friendlier Fire](https://www.nexusmods.com/morrowind/mods/57975)
- [Follower Commands](https://www.nexusmods.com/morrowind/mods/58818)
- [Fair Care](https://www.nexusmods.com/morrowind/mods/55293)
- [Disobedient Summons](https://www.nexusmods.com/morrowind/mods/58542)
- [Rapport - OpenMW Companions](https://www.nexusmods.com/morrowind/mods/54132)

## API

Best Friends Forever is built to be extended. Other mods can react when followers fall or recover, add custom icons and tooltip fields, register follower-specific actions, and even reach into BFF's live UI elements to reshape the HUD, tooltips, and follower menu.

See [docs/API.md](docs/API.md) for details.

## Credits

- **Sosnoviy Bor** - Author
- **butts** - Follower icons and the initial idea for them
- **urm** - Main inspiration and many UI elements ([Attend Me](https://www.nexusmods.com/morrowind/mods/51232))
- **ownlyme** - Custom settings renderers and ideas
- **Hyacinth** - Ideas
- **atka** - Inspiration for the Call feature
- **Pirate443** - Inspiration for the UI design ([HUD Companion Health Bar](https://www.nexusmods.com/morrowind/mods/60242))

Powered by [Super Settings Renderers](https://www.nexusmods.com/morrowind/mods/59673) and [Drop-in Utils](https://www.nexusmods.com/morrowind/mods/60374)
