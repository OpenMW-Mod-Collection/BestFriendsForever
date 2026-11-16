---@omw-context player
--[[
    CombatTracker - plug-and-play combat actor tracking for OpenMW Lua
    ==================================================================

    Tracks every actor that is currently in combat and fires two callbacks:
      * onEnter(actor, targets)  - actor was not in combat, now is
      * onLeave(actor)           - actor was in combat, now is not

    It is fed by OpenMW's built-in 'OMWMusicCombatTargetsChanged' event, which
    the stock AI script sends to player scripts whenever an actor's list of
    combat targets changes:  { actor = <GameObject>, targets = { <GameObject>... } }
    An empty / nil `targets` means the actor is no longer fighting.

    Must be used from a PLAYER script.

    -----------------------------------------------------------------------
    Usage (player script):

        local CombatTracker = require('scripts.CombatTracker.combatTracker')

        local tracker = CombatTracker.new{
            onEnter = function(actor, targets)
                print(actor.recordId .. ' entered combat')
            end,
            onLeave = function(actor)
                print(actor.recordId .. ' left combat')
            end,
        }

        return {
            engineHandlers = {
                onUpdate = tracker.onUpdate,   -- optional, but recommended (see below)
            },
            eventHandlers = {
                OMWMusicCombatTargetsChanged = tracker.onCombatTargetsChanged,
            },
        }

    If your script already has handlers for these, just call them from yours:

        eventHandlers = {
            OMWMusicCombatTargetsChanged = function(e)
                tracker.onCombatTargetsChanged(e)
                -- your own code
            end,
        }

    Why onUpdate? An actor that dies, is deleted, or gets unloaded may never
    report an empty target list. onUpdate runs a cheap, throttled prune() that
    drops such actors and fires onLeave for them.
    -----------------------------------------------------------------------

    Query API (all on the tracker instance):
        tracker.isInCombat(actor)      -> boolean
        tracker.getTargets(actor)      -> array of targets, or nil
        tracker.getActors()            -> array of actors currently in combat
        tracker.count()                -> number of actors in combat
        tracker.forEach(fn)            -> fn(actor, targets) for each tracked actor
        tracker.prune()                -> force a validity check now
        tracker.reset(fireOnLeave)     -> forget everyone (optionally firing onLeave)

    Options for CombatTracker.new{...}:
        onEnter        function(actor, targets)   optional
        onLeave        function(actor)            optional
        pruneInterval  seconds between automatic prunes in onUpdate (default 1.0, 0 = disabled)
        ignorePlayer   skip the player actor itself (default false)

    State is transient: it is rebuilt from incoming events and is not saved.
]]

local types = require("openmw.types")

local M = {}

-- True if the object can no longer be in combat (deleted or dead).
local function isGone(actor)
    return not actor:isValid() or types.Actor.isDead(actor)
end

-- Copy only valid game objects from a (possibly nil) targets list.
local function sanitizeTargets(targets)
    local result = {}
    for _, target in ipairs(targets) do
        if target:isValid() then
            result[#result + 1] = target
        end
    end
    return result
end

function M.new(options)
    options = options or {}
    local onEnter = options.onEnter
    local onLeave = options.onLeave
    local pruneInterval = options.pruneInterval or 1.0
    local ignorePlayer = options.ignorePlayer or false

    -- [actor.id] = { actor = <GameObject>, targets = { ... } }
    local tracked = {}
    local trackedCount = 0
    local nextPrune = 0

    local self = {}

    local function add(actor, targets)
        tracked[actor.id] = { actor = actor, targets = targets }
        trackedCount = trackedCount + 1
        if onEnter then
            onEnter(actor, targets)
        end
    end

    local function remove(id)
        local entry = tracked[id]
        if not entry then
            return
        end
        tracked[id] = nil
        trackedCount = trackedCount - 1
        if onLeave then
            onLeave(entry.actor)
        end
    end

    ---------------------------------------------------------------------
    -- Event handler: plug into eventHandlers.OMWMusicCombatTargetsChanged
    ---------------------------------------------------------------------
    function self.onCombatTargetsChanged(eventData)
        local actor = eventData.actor
        if actor == nil then
            return
        end

        if ignorePlayer and types.Player.objectIsInstance(actor) then
            return
        end

        local targets = sanitizeTargets(eventData.targets)
        local inCombat = #targets > 0 and not isGone(actor)

        local entry = tracked[actor.id]
        if inCombat then
            if entry then
                entry.targets = targets -- still in combat, just new targets
            else
                add(actor, targets)
            end
        elseif entry then
            remove(actor.id)
        end
    end

    ---------------------------------------------------------------------
    -- Cleanup of actors that vanished without reporting
    ---------------------------------------------------------------------
    function self.prune()
        local stale = {}
        for id, entry in pairs(tracked) do
            if isGone(entry.actor) then
                stale[#stale + 1] = id
            end
        end
        for _, id in ipairs(stale) do
            remove(id)
        end
    end

    -- Optional engine handler. Safe to call every frame; self-throttled.
    function self.onUpdate(dt)
        if pruneInterval <= 0 or trackedCount == 0 then
            return
        end

        nextPrune = nextPrune - dt
        if nextPrune > 0 then
            return
        end

        nextPrune = pruneInterval
        self.prune()
    end

    ---------------------------------------------------------------------
    -- Queries
    ---------------------------------------------------------------------
    function self.isInCombat(actor)
        return actor ~= nil and tracked[actor.id] ~= nil
    end

    function self.getTargets(actor)
        local entry = actor and tracked[actor.id]
        return entry and entry.targets or nil
    end

    function self.getActors()
        local list = {}
        for _, entry in pairs(tracked) do
            list[#list + 1] = entry.actor
        end
        return list
    end

    function self.count()
        return trackedCount
    end

    function self.forEach(fn)
        -- iterate over a snapshot so callbacks may safely change state
        local snapshot = {}
        for _, entry in pairs(tracked) do
            snapshot[#snapshot + 1] = entry
        end
        for _, entry in ipairs(snapshot) do
            fn(entry.actor, entry.targets)
        end
    end

    function self.reset(fireOnLeave)
        local ids = {}
        for id in pairs(tracked) do
            ids[#ids + 1] = id
        end
        for _, id in ipairs(ids) do
            if fireOnLeave then
                remove(id)
            else
                tracked[id] = nil
                trackedCount = trackedCount - 1
            end
        end
    end

    return self
end

return M
