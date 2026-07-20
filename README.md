# Best Friends Forever (OpenMW)

A collection of utilities for followers made with performance in mind. Follower HUD, teleportation, immortality and more. Modernized Attend Me, if you will.

[Attend Me](https://www.nexusmods.com/morrowind/mods/51232) is great, but it can be improved. That's why I'm presenting to you Best Friends Forever - performant and modernized alternative to Attend Me with extra flair!

Featuring:

- Follower status HUD with:
  - Current and total health, magicka and fatigue
  - Equipped weapon, spell, disease or the lack of them
- Followers teleport to you if they get unloaded
- Followers speed up to catch up to you
- Immortal followers:
  - Instead of dying, followers get knocked down for some time
  - Summoned creatures and followers under any Command effect die as usual instead of being knocked down. Command effects on already downed actors don't do anything, though
  - Enemies switch aggro from the follower to you
  - Knocked down followers lose aggro, so this can be also used as more punishing alternative to [Friendlier Fire's](https://www.nexusmods.com/morrowind/mods/57975) aggro prevention
- Keybind to teleport all your followers to you

## Compatibility

Safe to install or update mid-playthrough.  
When removing the mod, make sure no follower is currently downed and they don't have a speed boost.

Should be compatible with anything.

It is technically compatible with [Attend Me](https://www.nexusmods.com/morrowind/mods/51232), but they should not be used together.

Supported edge case mods:

- [Loafy's Necromancy - Reanimate Dead](https://www.nexusmods.com/morrowind/mods/58901) by TheLoafyOne
- [Water Life](https://www.nexusmods.com/morrowind/mods/42417) by abot
- [Inquisitive Guards](https://www.nexusmods.com/morrowind/mods/46538) by RubberMan
- [Morrowind Comes Alive](https://www.nexusmods.com/morrowind/mods/6006) by Neoptolemus and Morrowind community

## Requirements

Load Best Friends Forever as high as possible in the load order - before any mods that might alter melee damage calculations.

- [Follower Detection Util](https://www.nexusmods.com/morrowind/mods/58053) - Load before BFF

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
