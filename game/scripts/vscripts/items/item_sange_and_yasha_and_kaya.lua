local factory = require("items/factory_sange_yasha_kaya")

DeclarePassiveAbility("item_sange_and_yasha_and_kaya", "modifier_item_sange_and_yasha_and_kaya")

LinkLuaModifier("modifier_item_sange_and_yasha_and_kaya", "items/item_sange_and_yasha_and_kaya.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_sange_and_yasha_and_kaya = factory(
  { sange = true, yasha = true, kaya = true }
)
