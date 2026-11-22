# Best Friends Forever Public API

This is the contract other OpenMW Lua mods can build on. Use it to react when followers fall or recover, customize their HUD icons and tooltips, extend the follower menu, and let story mods decide whether a would-be down becomes a real death.

[Back to the README](../README.md)

## At a glance

- `BestFriendsForever_followerDown` and `BestFriendsForever_followerUp` report changes to a follower's downed state.
- `I.BestFriendsForever` is the player-side interface for downed-follower lookup, custom icons, tooltip fields, follower-menu buttons, and direct access to BFF's live UI elements.
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

`I.BestFriendsForever.version` is currently `5`. This is the main player-side interface: it gives you read-only access to the downed-follower table, lets you add custom icons, tooltip fields, and follower-menu buttons, and exposes BFF's live UI elements for direct modification.

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

`registerFollowerTooltipField()` adds extra information to BFF's follower tooltips without taking ownership of the HUD. Give the field a unique name, optionally adjust its sort order, and provide either `getText` for a simple string or `getLayout` for a complete UI layout. Text fields can also set `header = true` to use the header text template. Fields can be registered at any time.

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

### Raw UI access

`I.BestFriendsForever` also exposes BFF's live UI objects. This surface is available only to other PLAYER scripts on the player, because interfaces do not cross contexts and UI Elements cannot be serialized through events or saved. It is intentionally unsafe: BFF still owns these objects, and its update loop can overwrite visibility, positions, text, bar contents, icon contents, and menu structure during normal updates and rebuilds.

`getRawUI()` returns fresh top-level tables each call. The `root`, `tooltip`, `layout`, `buttons`, `actions`, `followers`, and `tooltipFields` values inside them are live BFF-owned objects. Element handles become invalid when BFF destroys and rebuilds the corresponding surface; a destroyed Element has `layout == nil`.

`menu.buttons` is keyed by layout name and includes the navigation buttons. `menu.actions` is keyed by registered button name and includes only action buttons on the current page. `hud.tooltipFields` is the live tooltip Content keyed by field layout name.

`getFollowerWidget(actorOrId)` accepts a Follower Detection Util Actor object or an actor id string. It returns the same entry as `getRawUI().hud.followers[id]`, or nil when the follower has no current HUD widget.

`refreshRawUI()` calls `Element:update()` on the current HUD, tooltip, menu root, and menu button elements. That refreshes the current layout but does not create new child Elements. `rebuildRawUI()` recreates the HUD and tooltip when the HUD is enabled and rebuilds the follower menu if it is open, rerunning registered mutators.

`registerRawUIMutator()` lets a player script reapply raw changes after BFF rebuilds a surface. Pass a unique `name` and any of `afterHudBuild(hud)`, `afterTooltipBuild(hud)`, and `afterMenuBuild(menu)`. Each callback receives the same table section as `getRawUI()`. Registering the same name again replaces the previous mutator, and mutators are not persisted, so re-register them in `onInit`, `onLoad`, or `onActive`. Registration only affects future rebuilds; call `rebuildRawUI()` after registering to restyle UI that already exists.

There is no error isolation: errors from callbacks propagate into BFF's build path. Mutators should be fast and should not call `rebuildRawUI()` from inside a build callback.

```lua
-- Scope: Player
-- Returns a fresh snapshot table:
-- {
--   hud = {
--     root = Element|nil,
--     tooltip = Element|nil,
--     followers = {
--       [actorId] = { actor = Actor, state = FDUState, data = FollowerData, layout = Layout },
--     },
--     tooltipFields = Content,
--   },
--   menu = {
--     root = Element|nil,
--     state = FDUState|nil,
--     page = number,
--     buttons = { [layoutName] = Element },
--     actions = { [buttonName] = Element },
--   },
-- }
I.BestFriendsForever.getRawUI()

-- Scope: Player
-- Accepts an Actor or actor id string. Returns the follower entry or nil.
I.BestFriendsForever.getFollowerWidget(actorOrId)

-- Scope: Player
-- Updates live elements without rebuilding them.
I.BestFriendsForever.refreshRawUI()

-- Scope: Player
-- Rebuilds the enabled HUD, its tooltip, and the open follower menu.
I.BestFriendsForever.rebuildRawUI()

-- Scope: Player
-- Registers callbacks that rerun after BFF rebuilds a UI surface.
I.BestFriendsForever.registerRawUIMutator {
    name = "MyMod_hudTint",
    afterHudBuild = function(hud) end,
    afterTooltipBuild = function(hud) end,
    afterMenuBuild = function(menu) end,
}
```

BFF currently uses these layout names in its HUD and menu surfaces:

- HUD root: `root`, `rootOuterPadding`, `rootFlexPadding`, `rootFlex`
- Follower widget: `followerFlex_<actor.id>`, `followerFlex_V1`, `followex_V1_H1`, `followerFlex_Bars`, `followerName`
- Tooltip root and fields: `followerTooltip`, `followerTooltipOuterPadding`, `followerTooltipHorizontalPadding`, `followerTooltipFields`, `followerTooltip_<fieldName>`
- Menu root: `BestFriendsForever_FollowerMenu`, `followerMenuHeader`, `followerMenuAction_<index>`, `followerMenuPrevious`, `followerMenuExit`, `followerMenuNext`

```lua
local I = require("openmw.interfaces")
local util = require("openmw.util")

I.BestFriendsForever.registerRawUIMutator {
    name = "MyMod_hudTint",
    afterHudBuild = function(hud)
        for _, widget in pairs(hud.followers) do
            local name = widget.layout.content.followerName
            if name then
                name.props.textColor = util.color.rgb(1, 0.4, 0.4)
            end
        end
    end,
}

local ui = I.BestFriendsForever.getRawUI()
if ui.menu.root then
    local button = ui.menu.actions["My Action"]
    if button then
        button.layout.content[1].content[2].props.text = "Do the thing"
        button:update()
    end
end
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

Only one provider is active; registering a new id replaces the previous one. Providers are not persisted, so re-register them in `onInit`, `onLoad`, or `onActive`. Keep the callback fast and side-effect-free. Errors and unexpected return values fall back to a normal down. Without a provider returning `"death"`, BFF always downs the follower instead of killing them.

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

Buttons may set `closeAfterActivation = true` to close the menu without leaving the current UI mode. The built-in Companion Share button uses this to open the follower in Companion mode for trading.

Player scripts can also reopen the follower menu by sending the `BestFriendsForever_openFollowerMenu` event to the player. Its payload is the follower's Follower Detection Util state:

```lua
self:sendEvent("BestFriendsForever_openFollowerMenu", followerState)
```
