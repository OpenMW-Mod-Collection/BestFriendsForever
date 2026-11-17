---@omw-context global
local groups = {
    "blacklist",
    "catchUp",
    "immortality",
    "toggles",
    "ward",
}

for _, group in ipairs(groups) do
    require("scripts.BestFriendsForever.settings." .. group)
end
