# Best Friends Forever Public API

This is the contract other OpenMW Lua mods can build on. Use it to react when followers fall or recover, customize their HUD icons and tooltips, extend the follower menu, and let story mods decide whether a would-be down becomes a real death.

[Back to the README](../README.md)

## At a glance

- `BestFriendsForever_followerDown` and `BestFriendsForever_followerUp` report changes to a follower's downed state.
- `I.BestFriendsForever` is the player-side interface for downed-follower lookup, custom icons, tooltip fields, and follower-menu buttons.
- `I.BestFriendsForeverDown` is the local-side hook that lets a follower's own scripts choose between a normal down and real death.

## BFF defaults and reserved values

The built-in extension points use the following defaults and reserved names. They matter when you want your own icons, tooltip fields, or menu buttons to coexist with BFF's own UI.

### Tooltip fields

| Built-in field | Order | Toggle key   | Notes                                        |
| -------------- | ----: | ------------ | -------------------------------------------- |
| `name`         |     1 | —            | Always shown                                 |
| `role`         |     2 | `class`      | Class for NPCs, type/base name for creatures |
| `diseases`     |     3 | `diseases`   | Uses the `diseaseVerbosity` setting          |
| `statDamage`   |     4 | `statDamage` | Summarizes drained or damaged stats          |

Use fractional order values such as `1.5` to insert a field between built-ins. Field names are unique exact strings.

`toggleKey` checks `SettingsBestFriendsForever_tooltip.enabledFields`; the built-in keys are `class`, `diseases`, and `statDamage`. `enabledSetting` checks `SettingsBestFriendsForever_HUDFollower.enabledElements`; the built-in keys are `name`, `health`, `magicka`, and `fatigue`. If your field uses a new `toggleKey`, add that key to the tooltip settings group yourself or the field will stay visible unless its callback returns nil.

### Follower icons

Icon resolution is: record ID map first, then rules in registration order, then BFF's built-in class/creature-type fallback. Registering the same rule function again replaces its previous registration.

### Follower menu

| Built-in button | Condition                                | Close behavior                         |
| --------------- | ---------------------------------------- | -------------------------------------- |
| Companion Share | Not a summon                             | `closeAfterActivation = true`          |
| Wait Here       | Not a summon, not under a Command effect | `closeAfterActivation = true`          |
| Repair Gear     | Not a summon                             | Closes when Repair mode actually opens |

Button names are unique case-insensitively. A button must define exactly one of `action` or `event`. Event buttons require `target` (`player`, `follower`, or `global`); action buttons cannot define `target`. The page size setting is `SettingsBestFriendsForever_menu.maxButtonsPerPage`, default `10`.

## Events

BFF broadcasts these events so other mods can react to downed state without polling follower state. The scope tells you which script contexts receive each event.

```lua
-- Sent when the follower enters Downed state
-- Payload: { follower: Actor, leader: Actor }
-- Scope: Player, Global, and the follower's local script
BestFriendsForever_followerDown

-- Sent when the follower is released from the Downed state
-- Payload: { follower: Actor, leader: Actor }
BestFriendsForever_followerUp
```

## Interfaces

`I.BestFriendsForever.version` is currently `4`. This is the main player-side interface: it gives you read-only access to the downed-follower table and lets you add custom icons, tooltip fields, and follower-menu buttons.

### Downed followers

`getDownedFollowers()` returns the live downed-follower table. BFF owns that table and may update it at any time, so treat it as read-only.

```lua
-- Returns downed followers of the player
-- Returns: table<string, Actor>  (live table, treat it as read-only)
-- Scope: Player
I.BestFriendsForever.getDownedFollowers()
```

### Follower icons

`setFollowerIcon()` assigns a texture to followers that match either record IDs or a custom rule. IDs are looked up first; rules are checked in registration order and the first match wins. Anything unmatched falls back to BFF's built-in class and creature-type icons. Registrations can happen at any time from a player script.

```lua
-- Assigns an icon to followers. Provide exactly one of recordIds or rule.
-- recordIds is a record ID string or a list of IDs (useful when a follower
-- is replaced by a twin with a different ID); recordId = "..." is shorthand
-- for one ID. IDs are looked up first.
-- rule(actor) is checked after ID lookup, in registration order; the first
-- matching rule wins. Anything unmatched falls back to BFF's built-in
-- class/creature-type icons.
-- fileName is a texture path relative to Data Files
-- isTransparent=true layers the image over the default background
-- false displays the image by itself
-- Scope: Player
I.BestFriendsForever.setFollowerIcon {
    recordIds = { "julan", "julan_twin" },
    fileName = "textures/bffs/Julan 1.png",
    isTransparent = true,
}

I.BestFriendsForever.setFollowerIcon {
    rule = function(actor)
        return actor.recordId == "some_creature"
    end,
    fileName = "textures/bffs/Animunculi.png",
    isTransparent = true,
}
```

### Tooltip fields

`registerFollowerTooltipField()` adds extra information to BFF's follower tooltips without taking ownership of the HUD. Give the field a unique name, optionally adjust its sort order, and provide either `getText` for a simple string or `getLayout` for a complete UI layout. Fields can be registered at any time.

```lua
-- Adds a field to the follower tooltip
-- name must be unique; order is a numeric weight and defaults to 100
-- built-in fields use 1-4; decimals such as 1.5 are allowed
-- getText receives the Follower Detection Util state and BFF's read-only
-- follower data, and returns text or nil (nil hides the field).
-- Safe to register at any time; BFF rebuilds the tooltip.
-- Scope: Player
I.BestFriendsForever.registerFollowerTooltipField {
    name = "MyMod_status",
    order = 100,
    getText = function(followerState)
        return followerState.isSummon and "Summon" or nil
    end,
}

-- Instead of text, a field can provide a complete UI layout.
-- getLayout receives the FDU state and BFF's read-only follower data
-- (down, spells, activeEffects, attributes, skills).
-- Return an openmw.ui.Layout table to show the field, or nil to hide it.
-- Provide either getText or getLayout, never both.
-- ui = require("openmw.ui")
I.BestFriendsForever.registerFollowerTooltipField {
    name = "MyMod_custom",
    order = 5,
    getLayout = function(followerState, followerData)
        return {
            type = ui.TYPE.Flex,
            props = { horizontal = true, gap = 4 },
            content = ui.content {
                { template = I.MWUI.templates.textNormal, props = { text = "Custom" } },
                {
                    template = I.MWUI.templates.textNormal,
                    props = { text = followerState.isSummon and "Summon" or "Follower" },
                },
            },
        }
    end,
}
```

## Follower Down Outcome

This is the local-side counterpart to `I.BestFriendsForever`. It gives quest and roleplay mods a chance to override BFF's down behavior, for example to turn a scripted assassination into a real death instead of a knockdown.

Local scripts attached to the same follower can provide a synchronous outcome through `I.BestFriendsForeverDown`. BFF calls the provider when the follower would otherwise be downed. Returning `"death"` commits real death; returning `"down"` or `nil` uses the normal down behavior.

```lua
-- Scope: local scripts on a BFF-immortal follower
-- Interface version: 1
I.BestFriendsForeverDown.setOutcomeProvider("MyMod", function()
    return "down" -- "down" | "death" | nil
end)

I.BestFriendsForeverDown.clearOutcomeProvider("MyMod")
```

Only one provider is active; registering a new id replaces the previous one. Providers are not persisted, so re-register them in `onInit`, `onLoad`, or `onActive`. Keep the callback fast and side-effect-free. Errors and unexpected return values fall back to a normal down. BFF's own `deathChance` setting is separate and is checked before the provider is called.

## Follower Menu

The follower menu is a small extension point for player scripts. Buttons can run code directly or send an event to another context, so you can expose follower-specific actions without drawing your own UI. Buttons can be registered at any time; an open menu rebuilds when a new button is added.

Player scripts can register buttons in the follower menu through the `I.BestFriendsForever` interface. Buttons are sorted alphabetically; the number of action buttons shown per page is configurable (10 by default).

The built-in Wait action dismisses an eligible follower; interact with them to have them follow you again. It is unavailable for summons and actors under a Command effect.

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

The optional `condition` function receives the follower state. Any truthy result enables the button; `false` or `nil` disables it and prevents activation. Companion Share uses this to exclude summons.

Or send that state as the event payload to the player, follower, or global script:

```lua
I.BestFriendsForever.registerFollowerMenuButton {
    name = "My Event",
    event = "MyMod_followerAction",
    target = "follower", -- "player", "follower", or "global"
}
```

Buttons may set `closeAfterActivation = true` to close the menu without leaving the current UI mode. The built-in Companion Share button uses this to open the follower in Companion mode for trading. <!-- TODO: what? -->

Player scripts can also reopen the follower menu by sending the `BestFriendsForever_openFollowerMenu` event to the player. Its payload is the follower's Follower Detection Util state:

```lua
self:sendEvent("BestFriendsForever_openFollowerMenu", followerState)
```
