# Best Friends Forever (OpenMW)

A collection of utilities for followers made with performance in mind. Follower HUD, teleportation, immortality and more. Modernized Attend Me, if you will.

[Attend Me](https://www.nexusmods.com/morrowind/mods/51232) is great, but it can be improved. That's why I'm presenting to you Best Friends Forever - performant and modernized alternative to Attend Me with extra flair!

## Features

Note that effectively everything in this mod toggleable and configurable.

### Follower HUD

Convenient way to see you followers' status.

- Current and total health, magicka and fatigue
- If in combat - equipped weapon, enchanted item or spell
- If not in combat - custom fancy icon representing who they are

### Teleportation Module

You will never lose your followers again. Everywhere you go - they will be teleported to you, including:

- Cell transitions
- Recall and intervention
- Travel services
- Scripted teleports

> Note: this module might break certain scripted events like follower departure. If you encounter this, use script blacklist and let me know about the issue somewhere so I could add a rule to the default config.

### Catch Up Module

Younger brother to Teleportation. Simply put, your followers will speed up the further they get from you. Meaning they will keep up with you even without needing to wear the Boots of Blinding Speed.

### Immortality Module

Ever been annoyed that your story-rich follower constantly dies in combat, borking the questline and requiring you to reload the save? Yeah, I did too. Well, you will never lose your followers again. Again.

This module will make sure your followers won't ever get killed pernanently. Instead, they will fall on the ground for set amount of time or until the end of the combat. Additionally, all enemies will ignore them lying on the ground, keeping the difficulty mostly in tact.

Does not apply to:

- Summons
- Actors under any Command effect

<details>
<summary><b>Follower Injuries</b></summary>

When a follower would have died, they roll for an injury: **80%** minor (10 minutes), **15%** major (7 days), **5%** permanent death.

**Skill groups**

- **Hand skills:** Long Blade, Short Blade, Axe, Blunt Weapon, Spear, Hand-to-hand, Block, Marksman, Security, Alchemy, Armorer
- **Fine-hand skills:** Marksman, Security, Alchemy, Armorer
- **Leg skills:** Athletics, Acrobatics, Sneak
- **Armor skills:** Light Armor, Medium Armor, Heavy Armor, Unarmored (draining them increases physical damage taken)
- **Weapon-arm skills:** Axe, Blunt Weapon, Long Blade, Spear, Marksman

Max Health/Fatigue deductions are applied directly by the mod, not by the spell.

<details>
<summary><b>Minor injuries</b> (10 minutes)</summary>

| Injury              | Spell effects                                          | Max deduction    |
| ------------------- | ------------------------------------------------------ | ---------------- |
| **Bruised Ribs**    | Drain Endurance 10, Athletics 15                       | none             |
| **Twisted Ankle**   | Drain Speed 20, Leg skills 20                          | none             |
| **Jarred Wrist**    | Drain Strength 10, Hand skills 15                      | none             |
| **Pulled Shoulder** | Drain Strength 25, Weapon-arm skills 20, Athletics 10  | none             |
| **Sprained Thumb**  | Drain Agility 10, Fine-hand skills 25, Hand-to-hand 20 | none             |
| **Scraped Knees**   | Drain Speed 10, Acrobatics 25, Sneak 25                | none             |
| **Dazed**           | Drain Intelligence 20, Willpower 20                    | none             |
| **Shaken Nerves**   | Drain Willpower 25, Luck 15                            | none             |
| **Black Eye**       | Blind 20, Drain Marksman 20, Security 20               | none             |
| **Bleeding Gash**   | Drain Agility 10, Armor skills 15                      | Max Health −10%  |
| **Winded**          | Drain Athletics 15                                     | Max Fatigue −30% |
| **Muscle Cramp**    | Drain Strength 10, Speed 10, Leg skills 15             | none             |

</details>

<details>
<summary><b>Major injuries</b> (7 days)</summary>

| Injury                  | Spell effects                                                               | Max deduction   |
| ----------------------- | --------------------------------------------------------------------------- | --------------- |
| **Broken Leg**          | Drain Speed 40, Agility 25, Leg skills 50                                   | none            |
| **Broken Arm**          | Drain Strength 35, Agility 15, Hand skills 40                               | none            |
| **Dislocated Shoulder** | Drain Strength 40, Weapon-arm skills 40, Block 40, Armorer 30, Athletics 20 | none            |
| **Maimed Hand**         | Drain Agility 35, Hand skills 50 (Fine-hand skills 60)                      | none            |
| **Concussion**          | Drain Intelligence 35, Willpower 35, Blind 20                               | none            |
| **Lost Eye**            | Blind 50, Drain Marksman 40, Security 40, Agility 15, Luck 10               | none            |
| **Punctured Lung**      | Drain Endurance 40, Athletics 40                                            | Max Health −20% |
| **Crushed Ribs**        | Drain Strength 25, Endurance 30, Armor skills 30                            | Max Health −20% |
| **Internal Bleeding**   | Drain Endurance 30, Armor skills 20                                         | Max Health −35% |
| **Festering Wound**     | Weakness to Common Disease 100, Drain Endurance 25, Personality 30          | Max Health −25% |
| **Severe Burns**        | Drain Endurance 15, Personality 40, Armor skills 30                         | Max Health −15% |
| **Spinal Trauma**       | Drain Agility 40, Speed 25, Strength 20, Leg skills 30                      | none            |

</details>

</details>

> Note: this module might break scripted events when your followers have to engage in combat with you. The solution is the same as with TP module.

### Ward Module

Module to remove one more friction point in playing with followers. Ward will protect your followers from all diseases and stat damage.

Disabled by default.

### Call Keybind

A keybing to unstuck your followers. Teleport everyone to you at the press of a button.

Unbound by default.

## Compatibility

Safe to install or update mid-playthrough.  
When removing the mod, make sure no follower is currently downed and they don't have a speed boost.

Should be compatible with anything. Though Immortality and Teleport modules might break certain scripts - please report such cases so I could expand the default blacklist.

It is technically compatible with [Attend Me](https://www.nexusmods.com/morrowind/mods/51232), but they should not be used together.

### Builtin Support

Script blacklist:

- [Loafy's Necromancy - Reanimate Dead](https://www.nexusmods.com/morrowind/mods/58901) by TheLoafyOne
- [Water Life](https://www.nexusmods.com/morrowind/mods/42417) by abot
- [Inquisitive Guards](https://www.nexusmods.com/morrowind/mods/46538) by RubberMan
- [Morrowind Comes Alive](https://www.nexusmods.com/morrowind/mods/6006) by Neoptolemus and Morrowind community

Unique follower icons:

- [Biz'Kuitz Blissful Mind - Alfiq Scholar Companion](https://www.nexusmods.com/morrowind/mods/59156) by 6moonless
- Julan, Ashlander Companion by Kateri
- [Tetra the Pack Guar](https://www.nexusmods.com/morrowind/mods/47928) by Tizzo

## Requirements

Load Best Friends Forever as high as possible in the load order - before any mods that might alter melee damage calculations.

- OpenMW 0.52 or newer
- [Follower Detection Util](https://www.nexusmods.com/morrowind/mods/58053) version 3.1 - Load before BFF

## Recommended Mods

- [Friendlier Fire](https://www.nexusmods.com/morrowind/mods/57975)
- [Follower Commands](https://www.nexusmods.com/morrowind/mods/58818)

## API

### Events

```lua
-- Sent when the follower enters Downed state
-- Payload: { follower: Actor, leader: Actor }
-- Scope: Player, Global
BestFriendsForever_followerDown

-- Sent when the follower is released from the Downed state
-- Payload: { follower: Actor, leader: Actor }
BestFriendsForever_followerUp
```

### Interfaces

```lua
-- Returns downed followers of the player
-- Returns: table<string, Actor>
-- Scope: Player
I.BestFriendsForever.getDownedFollowers()

-- Assigns a unique icon to a certain follower
-- fileName is a texture path relative to Data Files
-- isTransparent=true layers the image over the default background
-- false displays the image by itself
-- Scope: Player
I.BestFriendsForever.setFollowerIcon(recordId, fileName, isTransparent)
```

### Follower Menu

Player scripts can register buttons in the follower menu through the
`I.BestFriendsForever` interface. Buttons are sorted alphabetically and the menu
shows up to 10 action buttons per page.

The built-in Wait action dismisses an eligible follower; interact with them to
have them follow you again. It is unavailable for summons and actors under a
Command effect.

Run a function with the current Follower Detection Util state:

```lua
I.BestFriendsForever.registerFollowerMenuButton {
    name = "My Action",
    action = function(followerState)
        I.UI.setMode("Companion", { target = followerState.actor })
    end,
    condition = function(followerState)
        return not followerState.isSummon
    end,
}
```

The optional `condition` function receives the follower state and must return a
boolean. When it returns `false`, the button appears disabled and cannot be
activated. Companion Share uses this to exclude summons.

Or send that state as the event payload to the player, follower, or global
script:

```lua
I.BestFriendsForever.registerFollowerMenuButton {
    name = "My Event",
    event = "MyMod_followerAction",
    target = "follower", -- "player", "follower", or "global"
}
```

Buttons may set `closeAfterActivation = true` to close the menu without leaving
the current UI mode. The built-in Companion Share button uses this to open the
follower in Companion mode for trading. <!-- TODO: what? -->

Player scripts can also reopen the follower menu by sending the
`BestFriendsForever_openFollowerMenu` event to the player. Its payload is the
follower's Follower Detection Util state:

```lua
self:sendEvent("BestFriendsForever_openFollowerMenu", followerState)
```

## Credits

**Sosnoviy Bor** - Author  
**butts** - Follower icons and the initial idea for them  
**urm** - Main inspiration and many UI elements ([Attend Me](https://www.nexusmods.com/morrowind/mods/51232))  
**ownlyme** - Custom settings renderers and ideas  
**Hyacinth** - Ideas  
**atka** - Inspiration for the Call feature  
**Pirate443** - Inspiration for the UI design ([HUD Companion Health Bar](https://www.nexusmods.com/morrowind/mods/60242))

Powered by [Super Settings Renderers](https://www.nexusmods.com/morrowind/mods/59673) and [Drop-in Utils](https://www.nexusmods.com/morrowind/mods/60374)
