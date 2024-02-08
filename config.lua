Config = {}

Config.MaxWeight = 120000 -- Used to check if the player can actually hold the items

Config.MaxSlots = 41 -- Used to check if the player can actually hold the items

Config.ShowLootOptionIfDead = true -- Recommended to keep enabled
-- If enabled then if someone F8s without being dead then the option to loot them won't appear

Config.ShowLootOptionIfCuffed = true -- Recommended to keep enabled
-- If enabled then if someone F8s without being cuffed then the option to loot them won't appear

Config.DontShowOptionIfPlayerHasWhitelistedJob = true -- If the player that F8ed has one these jobs below, don't show the option for them to be looted


Config.WhitelistedJobs = {"police", "ems"} -- Only works if the option above is enabled


Config.LootOptionTime = 60 -- In seconds, recommended to keep at 60 seconds


Config.LootKeybind = 38 -- E key
-- https://docs.fivem.net/docs/game-references/controls/

Config.TextColor = {255, 0, 0, 255} -- Color that the text will be when the option to loot the player appears

Config.ShowTimerInText = true -- Will show how long a player has until the option to loot them is gone away
--Example if enabled: [E] Loot F8er (42s)
--Example if disabled: [E] Loot F8er

Config.LootText = "[E] Loot Player" -- The text to show when a player F8s

Config.NonLootableItems = {"item1", "item2"} -- MUST BE THE SAME ITEM NAMES AS IN YOUR QBCORE ITEMS LIST!
--Example: "weapon_pistol", "weapon_firework"

Config.DisallowLootingIfPlayerOnline = true -- Recommended to keep enabled
--So pretty much there is a duplication glitch but the option above fixes it
--If the player that F8ed joins the server again before the LootOptionTime is up then they can loot themselves and it won't take away their items
