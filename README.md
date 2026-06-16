# Good Company (OpenMW)

A collection of utilities for followers made with performance in mind. Modernized Attend Me, if you will.

[Attend Me](https://www.nexusmods.com/morrowind/mods/51232) is great, but it can be improved. That's why I'm presenting to you Good Company - performant and modernized alternative to Attend Me!

Featuring:

- Follower status HUD with:
  - Current and total health, magicka and fatigue
  - Equipped weapon, spell, disease or lack of them
  <!-- - Currently active temporary effects -->
- Followers teleport to you if they get unloaded
- Followers speed up to catch up to you
- Immortal followers:
  - Instead of dying, followers are knocked down until the end of combat
  - Enemies switch aggro from the follower to you
  - Summoned creatures and followers under any Command effect are excluded from immortality
  - Knocked down followers lose aggro, so this can be also used as more punishing alternative to [Friendlier Fire's](https://www.nexusmods.com/morrowind/mods/57975) aggro prevention
- Keybind to teleport all your followers to you

## Compatibility

Safe to install or update mid-playthrough.  
When removing the mod, make sure no follower is currently downed.

Should be compatible with anything.

It is technically compatible with [Attend Me](https://www.nexusmods.com/morrowind/mods/51232), but they should not be used together.

## Requirements

Load Good Company as high as possible in the load order - before any mods that might alter melee damage calculations.

Dependency load order doesn't matter.

- [Follower Detection Util](https://www.nexusmods.com/morrowind/mods/58053)
- [H3lp Yours3lf](https://www.nexusmods.com/morrowind/mods/56417)

## Recommended Mods

- [Friendlier Fire](https://www.nexusmods.com/morrowind/mods/57975)
- [Follower Commands](https://www.nexusmods.com/morrowind/mods/58818)

## API

### Events

```lua
-- Sent when the player clicks certain follower's widget
-- Payload: Actor (follower object)
-- Scope: Player, Global
GoodCompany_followerWidgetClicked

-- Sent when the follower enters Down state
-- Payload: { follower: Actor, leader: Actor }
-- Scope: Player, Global
GoodCompany_followerDown

-- Sent when the follower eis released from the Down state
-- Payload: { follower: Actor, leader: Actor }
GoodCompany_followerUp
```

### Interfaces

```lua
-- Returns downed followers of the player
-- Returns: table<string, Actor>
-- Scope: Player
I.GoodCompany.getDownedFollowers()
```

## Credits

**Sosnoviy Bor** - Author  
**urm** - Main inspiration and many UI elements ([Attend Me](https://www.nexusmods.com/morrowind/mods/51232))  
**atka** - Inspiration for Call feature  
**ownlyme** - The mod's name
