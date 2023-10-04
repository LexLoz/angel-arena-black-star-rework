require("items/item_infinity_stones")

STONES_TIME_DROP = 6
DROP_CHANCE_DECREASE = 2

PLAYERS_DROP_CHANCE = {}

CHAMPIONS_DROP_CHANCE = {
    -- [15] = 999999,
    [5] = 999999,
    [4] = 80,
    [3] = 60,
    [2] = 40,
    [1] = 20
}

STONES_TABLE = {
    {"item_power_stone", true},
    {"item_time_stone", true},
    {"item_soul_stone", true},
    {"item_mind_stone", true},
    {"item_space_stone", true},
    {"item_reality_stone", true},
}

STONES_LIST = {
    ["item_power_stone"] = true,
    ["item_time_stone"] = true,
    ["item_soul_stone"] = true,
    ["item_mind_stone"] = true,
    ["item_space_stone"] = true,
    ["item_reality_stone"] = true
}

STONES_IN_WORLD = {}

DROPPED_STONES = 0