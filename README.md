# Best Friends Forever (OpenMW)

A collection of utilities for followers made with performance in mind. Follower HUD, teleportation, immortality and more. Modernized Attend Me, if you will.

[Attend Me](https://www.nexusmods.com/morrowind/mods/51232) is great, but it can be improved. That's why I'm presenting to you Best Friends Forever - performant and modernized alternative to Attend Me with extra flair!

## Features

Note that effectively everything in this mod toggleable and configurable.

### Follower HUD

Convenient way to see you followers' status.

- Current and total health, magicka and fatigue
- Equipped weapon, spell, disease or the lack of them

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

This module will make sure your followers won't ever get killed pernanently. Instead, they will fall on the ground for set amount of time. Additionally, all enemies will ignore them lying on the ground, keeping the difficulty mostly in tact.

Does not apply to:

- Summons
- Actors under any Command effect

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

Supported edge case mods:

- [Loafy's Necromancy - Reanimate Dead](https://www.nexusmods.com/morrowind/mods/58901) by TheLoafyOne
- [Water Life](https://www.nexusmods.com/morrowind/mods/42417) by abot
- [Inquisitive Guards](https://www.nexusmods.com/morrowind/mods/46538) by RubberMan
- [Morrowind Comes Alive](https://www.nexusmods.com/morrowind/mods/6006) by Neoptolemus and Morrowind community

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
-- Sent when the player clicks certain follower's widget
-- Payload: Actor (follower object)
-- Scope: Player, Global
BestFriendsForever_followerWidgetClicked

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
```

## Credits

**Sosnoviy Bor** - Author  
**urm** - Main inspiration and many UI elements ([Attend Me](https://www.nexusmods.com/morrowind/mods/51232))  
**ownlyme** - Slider renderer and ideas  
**Hyacinth** - Ideas  
**atka** - Inspiration for the Call feature
