require("items/item_infinity_stones")

STONES_TIME_DROP = 0
DROP_CHANCE_DECREASE = 2

PLAYERS_DROP_CHANCE = {}

CHAMPIONS_DROP_CHANCE = {
    -- [15] = 999999,
    [5] = 50,
    [4] = 40,
    [3] = 30,
    [2] = 20,
    [1] = 10
}

STONES_TABLE = STONES_TABLE or {
    {"item_power_stone", true},
    {"item_time_stone", true},
    {"item_soul_stone", true},
    {"item_mind_stone", true},
    {"item_space_stone", true},
    {"item_reality_stone", true},
}

STONES_LIST = STONES_LIST or {
    ["item_power_stone"] = true,
    ["item_time_stone"] = true,
    ["item_soul_stone"] = true,
    ["item_mind_stone"] = true,
    ["item_space_stone"] = true,
    ["item_reality_stone"] = true
}

STONES_IN_WORLD = STONES_IN_WORLD or {}

DROPPED_STONES = DROPPED_STONES or 0