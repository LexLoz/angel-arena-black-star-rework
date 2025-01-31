FRAMETIME = FrameTime() -- TODO: hook up cvars here

HERO_ASSIST_RANGE = 1300
COURIER_RESPAWN_TIME = 180
MAX_MOVEMENT_SPEED = 550
MAP_LENGTH = 8192
MAP_BORDER = 512

START_BOSS_UPGRADE_MIN = 30

MAX_ATTACK_SPEED = 700

DAMAGE_PER_ATTRIBUTE_FOR_UNIVERSALES = 0.7
DAMAGE_PER_UNRELIABLE_STAT = 1 / 6
DAMAGE_PER_UNRELIABLE_STRENGTH = 0.7

RELIABLE_BASE_DAMAGE_LIMIT = 5000
RELIABLE_BONUS_DAMAGE_LIMIT = 2000

BASE_MANA_PER_INT = 12
BASE_HP_PER_STRENGTH = 22

STAT_GAIN_LEVEL_LIMIT = 30
RELIABLE_BONUS_STAT_LIMIT = 500


SPEND_MANA_PER_DAMAGE = 100
SPEND_MANA_PER_DAMAGE_MULT_THRESHOLD = 1.25
SPEND_MANA_PER_DAMAGE_MAX_REDUCE_THRESHOLD = 5
SPEND_MANA_PER_HEAL = 100

SPEND_MANA_PER_HEAL_MULT_THRESHOLD = 2
SPEND_MANA_PER_HEAL_MAX_REDUCE_THRESHOLD = 10

STRENGTH_REGEN_AMPLIFY = 0.002
STRENGTH_CRIT_COOLDOWN = 21
STRENGTH_CRIT_COOLDOWN_DECREASE_PER_LEVEL = 0.03
STRENGTH_CRIT_MULTIPLIER = 0.3
STRENGTH_CRIT_SPELL_CRIT_DECREASRE_MULT = 3
STRENGTH_BASE_CRIT = 50

AGILITY_ARMOR_MULTIPLIER = 5
AGILITY_ARMOR_BASE_COEFF = 1 / 6

UNREABLE_AGILITY_ARMOR_COEFF = 1 / 60000
AGILITY_MAX_BASE_ARMOR_COUNT = 200
AGILITY_MAX_ATTACK_SPEED_COUNT = 700

ATTACK_SPEED_PER_LEVEL_AGILITY = 1
ATTACK_SPEED_PER_BONUS_AGILITY = 1
AGILITY_DAMAGE_AMPLIFY = 0.05

AGILITY_BONUS_BASE_PROCK_CHANCE = 6
AGILITY_BONUS_PROCK_CHANCE_PER_LEVEL = 0.045
AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK = 300
AGILITY_BONUS_AGILITY_FOR_BONUS_ATTACK_GROWTH_MULTIPLIER = 3
AGILITY_BONUS_BASE_DAMAGE = 100
AGILITY_BONUS_BONUS_DAMAGE = 0.03
DISTANCE_DIFFERENCE_FOR_CANCEL_ATACKS = 500
AGILITY_BONUS_ATTACKS_BASE_COUNT = 1
AGILITY_BONUS_ATTACKS_COOLDOWN = 2
AGILITY_BONUS_ATTACKS_THRESHOULD = 5
AGILITY_BONUS_MAX_EFFECTS_COUNT = 2

MANA_REGEN_AMPLIFY = 0.002

MAX_RESIST_PER_RELIABLE_INT = 25
MAX_RESIST_PER_UNRELIABLE_INT = 25

INTELLECT_PRIMARY_BONUS_DIFF_FOR_MAX_MULT = 4
INTELLECT_PRIMARY_BONUS_MAX_BONUS = 30
INTELLECT_PRIMARY_BONUS_UPGRADE_MULT = 1.5
INTELLECT_PRIMARY_BONUS_UPGRADE_DIFF_MULT = 1
INTELLECT_PRIMARY_BONUS_ON_CREEPS_DECREASE = 2

STAMINA_REGEN = 5
STAMINA_REGEN_INCREASE_MULT = 5
STAMINA_PER_AGILITY = 8
STAMINA_DAMAGE_PERCENT_IN_STAMINA_CONSUMPTION = 50
STAMINA_THRESHOLD_FOR_DEBUFF = 5
STAMINA_MAX_BAT_DECREASE = 0.3
STAMINA_MAX_MS_REDUSE = -30
STAMINA_DAMAGE_DECREASE_PCT = -75
STAMINA_DEBUFF_DURATION = 3
STAMINA_DEBUFF_DELAY = 1
STAMINA_START_DEBUFF_DELAY = 0


KILL_WEIGHT_START_INCREASE_MINUTE = 40
KILL_WEIGHT_BONUS_PER_MINUTE = 5

LEVELS_WITHOUT_ABILITY_POINTS = {
	[17] = true,
	[19] = true,
	[21] = true,
	[22] = true,
	[23] = true,
	[24] = true,
	-- also all of the levels above 25
}

-- TODO: These enums appear to be outdated
DOTA_ITEM_SLOT_10 = DOTA_ITEM_SLOT_9 + 1
--[[DOTA_STASH_SLOT_1 = DOTA_STASH_SLOT_1 + 1
DOTA_STASH_SLOT_2 = DOTA_STASH_SLOT_2 + 1
DOTA_STASH_SLOT_3 = DOTA_STASH_SLOT_3 + 1
DOTA_STASH_SLOT_4 = DOTA_STASH_SLOT_4 + 1
DOTA_STASH_SLOT_5 = DOTA_STASH_SLOT_5 + 1
DOTA_STASH_SLOT_6 = DOTA_STASH_SLOT_6 + 1]]

CustomNetTables:SetTableValue("attribute_constants", "const", {
	BASE_MANA_PER_INT = BASE_MANA_PER_INT,
	BASE_HP_PER_STRENGTH = BASE_HP_PER_STRENGTH,
	MANA_REGEN_AMPLIFY = MANA_REGEN_AMPLIFY,
	STRENGTH_REGEN_AMPLIFY = STRENGTH_REGEN_AMPLIFY,
	AGILITY_DAMAGE_AMPLIFY = AGILITY_DAMAGE_AMPLIFY,
	
})

