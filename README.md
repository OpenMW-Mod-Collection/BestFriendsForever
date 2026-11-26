# Best Friends Forever - Follower HUD and QoL (OpenMW)

What if I said that your followers don't have to feel like a burden? That you can get modern follower experience in this fossil of a game?

What initially started as "[Attend Me](https://www.nexusmods.com/morrowind/mods/51232), but less laggy" gradually evolved into something far more greater. And still less laggy, by the way :D

<div align="center">

<!-- TODO: HUD preview goes here -->
<img src="">

</div>

In short, BFFs features can be split into 3 groups:

1. Utility Scripts
    - **Teleportation** - your followers will teleport to you anywhere and everywhere
    - **Catch Up** - your followers will always keep up with you
    - **Immortality** - instead of dying, your followers will fall on the ground until the end of combat. Additionally, they can get temporary injuries (check Injuries for details)
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

## Details

### Injuries

To balance things out and maybe even introduce new roleplay options, when followers get downed thanks to Immortality script, they will:

- **Get a Minor Injury for 10 minutes (80%)** - they aren't severe, but still make you pay more attention to your follower in combat if you decide to push further
- **Get a Major Injury for 7 days (15%)** - they are really bad and majorly render your follower barely capable of fighting if you get the right injury. It's advised to send your followers home, to an inn or to your base of operations to not make matters even worse
- **Die (5%)** - self-explanatory

<div align="center">

*Active injuries appear in the follower tooltip and turn the follower icon red.*

<img src=""> 

*Different injuries can stack too!*

</div>

Chances are configurable, but the time is not. Unless you want to edit the files manually where I can only wish you good luck.

<details>

<summary>List of Minor Injuries</summary>

- **Winded**: Max Fatigue -50% (MAX)
- **Bruised Ribs**: Drain Endurance 15, Max Fatigue -25% (MAX)
- **Sprained Ankle**: Drain Speed 20, Drain Acrobatics 40
- **Jarred Wrist**: Drain Agility 15, Drain Strength 10
- **Dazed**: Blind 20
- **Rattled**: Drain Willpower 20, Max Magicka -30% (MAX)
- **Ringing Ears**: Sound 20, Drain Willpower 10
- **Singed**: Weakness to Fire 25%, Drain Endurance 10
- **Stumbling**: a 1s paralyze or knockdown every 45-90 seconds (STAG)
- **Skittish**: a 10s Demoralize every 60-120 seconds (DEM)

</details>

<details>

<summary>List of Major Injuries</summary>

- **Broken Leg**: Drain Speed 60, Drain Acrobatics 100, Drain Athletics 60, Burden 100
- **Broken Sword Arm**: Drain Strength 50, Drain Agility 40, Drain Long Blade, Short Blade, Axe, Blunt Weapon, and Spear 50 each, Drain Block 50
- **Shattered Ribs**: Drain Endurance 50, Max Fatigue -75% (MAX), Max Health -25% (MAX)
- **Severe Concussion**: Drain Intelligence 50, Drain Willpower 50, Blind 40, and a 1s paralyze or knockdown every 20-40 seconds (STAG)
- **Crushed Hand**: Drain Agility 60, Drain Strength 30, Drain Block 100, Drain Marksman 60, Burden 50
- **Maimed Eye**: Blind 50, Drain Marksman 60, Drain Agility 20
- **Festering Wound**: Weakness to Common Disease 100%, Weakness to Blight Disease 50%, Max Health -40% (MAX), Drain Endurance 20
- **Burnt-Out Channels**: Max Magicka -80% (MAX), Stunted Magicka, Silence, Drain Willpower 30
- **Broken Nerve**: Drain Willpower 40, Weakness to Magicka 30%, and a 15s Demoralize every 30-60 seconds (DEM)
- **Raw Burns**: Weakness to Fire 75%, Weakness to Frost 40%, Weakness to Shock 40%, Max Health -30% (MAX), Drain Endurance 30

</details>

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
- **JaceyS** - Reference for the follower icons ([Big Icons](https://www.nexusmods.com/morrowind/mods/49662), [Jacey's Vector Icons](https://www.nexusmods.com/morrowind/mods/49914))
- **urm** - Main inspiration and many UI elements ([Attend Me](https://www.nexusmods.com/morrowind/mods/51232))
- **ownlyme** - Custom settings renderers and ideas
- **Hyacinth** - Ideas
- **atka** - Inspiration for the Call feature
- **Pirate443** - Inspiration for the UI design ([HUD Companion Health Bar](https://www.nexusmods.com/morrowind/mods/60242))

Powered by [Super Settings Renderers](https://www.nexusmods.com/morrowind/mods/59673) and [Drop-in Utils](https://www.nexusmods.com/morrowind/mods/60374)
