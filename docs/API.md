# Best Friends Forever Public API

The API is used mostly for adding UI elements to existing menus, altering the current UI if your'brave enough and interacting/reacting to downed followers.

## Contents

- [BFF defaults and reserved values](#bff-defaults-and-reserved-values)
  - [Tooltip field defaults](#tooltip-field-defaults)
  - [Icon defaults](#icon-defaults)
  - [Menu defaults](#menu-defaults)
- [Events](#events)
- [Interfaces](#interfaces)
  - [Downed followers](#downed-followers)
  - [Follower icons](#follower-icons)
  - [Tooltip fields](#tooltip-fields)
  - [Raw UI access](#raw-ui-access)
- [Follower Down Outcome](#follower-down-outcome)
- [Follower Menu](#follower-menu)

## BFF defaults and reserved values

The built-in extension points use the defaults and reserved names below. They matter when your extensions coexist with BFF's own UI.

### Tooltip field defaults

| Built-in field | Order |
| -------------- | :---: |
| `name`         |   1   |
| `role`         |   2   |
| `summon`       |   3   |
| `diseases`     |   4   |
| `statDamage`   |   5   |

Use fractional order values such as `1.5` to insert a field between built-ins. Field names are unique exact strings, so they can be overriden.

### Icon defaults

Icon packs live in `textures/bff/icons/<preset>/`. Textures use `category_key.png`:

| Category   | Used for                               |
| ---------- | -------------------------------------- |
| `class`    | NPC specialization fallback            |
| `creature` | Creature-type fallback                 |
| `summon`   | Summoned-creature fallback             |
| `id`       | Record ID, matched automatically       |
| `rule`     | Predicate conditions, first match wins |

Built-in keys are `combat`, `mage`, `stealth`, and `civilian` for `class_*`, plus lowercase creature-type names for `creature_*` and `summon_*`. An `id_<recordId>` texture applies automatically to that record ID; no API call is needed. Keys may contain underscores and spaces, such as `id_julan twin.png`. `rule_*` keys come from registered suffixes.

`background.png` is a pack-level background override. Missing textures and backgrounds fall back to the `default` pack. Icons are always drawn over the background.

Icons resolve in this order:

- Unique IDs (`id_*`)
- Conditional icons (`rule_*`)
- Fallback icons (`creature_*`, `summon_*`, or `class_*`)

### Menu defaults

| Built-in button | Enabled when                             |
| --------------- | ---------------------------------------- |
| Companion Share | Not a summon                             |
| Wait Here       | Not a summon, not under a Command effect |
| Stop Combat     | Always available                         |
| Repair Gear     | Not a summon                             |

Button names are case-insensitively unique, so they can be overriden.

## Events

These events get broadcasted when a follower enters or leaves the Downed state.

```lua
-- Scope: Player, Global, and the follower's local script
-- Payload: { follower: Actor, leader: Actor }
BestFriendsForever_followerDown

-- Scope: Player and Global
-- Payload: { follower: Actor, leader: Actor }
BestFriendsForever_followerUp
```

## Interfaces

### Downed followers

`getDownedFollowers()` returns BFF's live table of downed followers of the player. BFF owns and updates the table; treat it as read-only.

```lua
-- Returns: table<string, Actor>
-- Scope: Player
I.BestFriendsForever.getDownedFollowers()
```

### Follower icons

Unique icons need no API call: an `id_<recordId>` texture applies automatically to that record ID. Use `registerFollowerIconSuffix()` only to bind a predicate to a `rule_*` texture. The API never takes a path. Automatic ID matching runs before rules; rules use the selected icon pack, run in registration order, and the first match wins. Registrations can happen at any time from a player script.

Changing the Icon Pack setting reloads the merged pack. Missing textures and backgrounds fall back to `default`.

```lua
-- Scope: Player
-- Payload: { suffix: string, rule: fun(actor: Actor): boolean }
I.BestFriendsForever.registerFollowerIconSuffix {
    suffix = "animunculi",
    rule = function(actor)
        return actor.recordId == "some_creature"
    end,
}
```

### Tooltip fields

`registerFollowerTooltipField()` adds information to BFF's follower tooltips without taking ownership of the HUD. Give each field a unique `name`, optionally set a numeric `order` (default `100`; built-ins use `1`-`5`, decimals allowed), and provide either `getText` or `getLayout`. Text fields can also set `header = true` to use the header template. Fields can be registered at any time; BFF rebuilds the tooltip.

`getText(followerState, followerData)` receives the FDU state and BFF's read-only follower data, and returns text or nil; nil hides the field.

```lua
-- Scope: Player
I.BestFriendsForever.registerFollowerTooltipField {
    name = "MyMod_status",
    order = 100,
    getText = function(followerState)
        return followerState.isSummon and "Summon" or nil
    end,
}
```

Use `getLayout` when the field needs its own UI instead of text. It receives the same two arguments and returns an `openmw.ui.Layout` table or nil. Provide either `getText` or `getLayout`, never both.

```lua
local ui = require("openmw.ui")

-- Scope: Player
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

`I.BestFriendsForever` also exposes BFF's live UI objects to other player scripts on the player. Interfaces do not cross contexts and UI Elements cannot be serialized through events or saved. This surface is intentionally unsafe: BFF still owns the objects, and normal updates and rebuilds can overwrite visibility, positions, text, bar contents, icon contents, and menu structure.

`getRawUI()` returns fresh top-level tables each call. Their values are live BFF-owned objects. Element handles become invalid when BFF destroys and rebuilds the corresponding surface; a destroyed Element has `layout == nil`.

`menu.buttons` is keyed by layout name and includes navigation buttons. `menu.actions` is keyed by registered button name and includes only action buttons on the current page. `hud.tooltipFields` is the live tooltip Content keyed by field layout name.

```lua
-- Scope: Player
-- Returns: {
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
```

`getFollowerWidget(actorOrId)` accepts an FDU Actor object or actor id string. It returns the same entry as `getRawUI().hud.followers[id]`, or nil when the follower has no current HUD widget.

```lua
-- Scope: Player
-- Params: actorOrId = Actor|string
-- Returns: follower entry|nil
I.BestFriendsForever.getFollowerWidget(actorOrId)
```

`refreshRawUI()` calls `Element:update()` on the current HUD, tooltip, menu root, and menu buttons. It refreshes existing layout only; it does not create child Elements.

`rebuildRawUI()` recreates the HUD and tooltip when the HUD is enabled, and rebuilds the open follower menu. It reruns registered mutators.

```lua
-- Scope: Player
I.BestFriendsForever.refreshRawUI()

-- Scope: Player
I.BestFriendsForever.rebuildRawUI()
```

`registerRawUIMutator()` reapplies raw changes after BFF rebuilds a surface. Pass a unique `name` and any of `afterHudBuild(hud)`, `afterTooltipBuild(hud)`, and `afterMenuBuild(menu)`. Each callback receives the matching section of `getRawUI()`. Registering the same name again replaces the previous mutator. Mutators are not persisted, so re-register them in `onInit`, `onLoad`, or `onActive`. Registration affects future rebuilds only; call `rebuildRawUI()` afterward to restyle UI that already exists.

Mutators have no error isolation: callback errors propagate into BFF's build path. Keep them fast and do not call `rebuildRawUI()` from inside a build callback.

```lua
-- Scope: Player
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
- Menu root: `BestFriendsForever_FollowerMenu`, `followerMenuHeader`, `followerMenuSummon`, `followerMenuAction_<index>`, `followerMenuPrevious`, `followerMenuExit`, `followerMenuNext`

The following mutator tints follower names after each HUD rebuild:

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
```

The following renames a menu action button on the current page:

```lua
local I = require("openmw.interfaces")

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

The follower-local `I.BestFriendsForever` is a separate interface from the player-side one with the same name. It lets quest and roleplay mods override BFF's down behavior, for example turning a scripted assassination into real death. Interfaces are object-local, so this is not the player-side interface.

Local scripts attached to the same follower can provide a synchronous outcome provider through this interface (version 2). BFF calls it when the follower would otherwise be downed. Returning `"death"` commits real death; returning `"down"` or `nil` uses the normal down behavior.

```lua
-- Scope: local scripts on a BFF-immortal follower
I.BestFriendsForever.setOutcomeProvider("MyMod", function()
    return "down" -- "down" | "death" | nil
end)

I.BestFriendsForever.clearOutcomeProvider("MyMod")
```

Only one provider is active; registering a new id replaces the previous one. Providers are not persisted, so re-register them in `onInit`, `onLoad`, or `onActive`. Keep the callback fast and side-effect-free. Errors and unexpected values fall back to a normal down. Without a `"death"` result, BFF always downs the follower.

## Follower Menu

The follower menu lets player scripts add follower-specific actions without drawing their own UI. Buttons run a function with the current follower state, can be registered at any time, and rebuild an open menu when added. Buttons are sorted alphabetically; the number shown per page is configurable (10 by default).

The built-in Wait action dismisses an eligible follower; interact with them to follow again. It is unavailable for summons and actors under a Command effect.

The built-in Stop Combat action removes Combat and Pursue AI packages. It preserves Follow, so a following follower resumes following and a waiting one stays put. The follower may re-engage if the enemy is still hostile.

To run a function with the current FDU state:

```lua
-- Scope: Player
I.BestFriendsForever.registerFollowerMenuButton {
    name = "My Action",
    action = function(followerState)
        I.UI.setMode("Companion", { target = followerState.actor })
    end,
    enabledWhen = function(followerState)
        return not followerState.isSummon
    end,
}
```

`visibleWhen` and `enabledWhen` are optional and receive the follower state. `visibleWhen` controls whether the button appears and counts toward pagination; a false or nil result hides it. `enabledWhen` controls disabled styling and activation; a false or nil result disables it and prevents activation. Both default to true. Companion Share uses `enabledWhen`, so summons see it disabled. `condition`, `event`, and `target` are removed and raise registration errors; send events from `action`.

To send an event from a button, do it inside `action`:

```lua
-- Scope: Player
I.BestFriendsForever.registerFollowerMenuButton {
    name = "My Event",
    action = function(followerState)
        followerState.actor:sendEvent("MyMod_followerAction", followerState)
    end,
}
```

Buttons may set `closeAfterActivation = true` to close the menu without leaving the current UI mode. Companion Share uses this when opening Companion mode.

Player scripts can reopen the menu by sending `BestFriendsForever_openFollowerMenu` to the player with an FDU state payload:

```lua
-- Scope: Player
self:sendEvent("BestFriendsForever_openFollowerMenu", followerState)
```
