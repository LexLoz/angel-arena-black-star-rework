LINKED_ABILITIES = {
	shredder_chakram_2 = { "shredder_return_chakram_2" },
	shredder_chakram = { "shredder_return_chakram" },
	kunkka_x_marks_the_spot = { "kunkka_return" },
	life_stealer_infest = { "life_stealer_control", "life_stealer_consume" },
	rubick_telekinesis = { "rubick_telekinesis_land" },
	bane_nightmare = { "bane_nightmare_end" },
	phoenix_icarus_dive = { "phoenix_icarus_dive_stop" },
	phoenix_fire_spirits = { "phoenix_launch_fire_spirit" },
	ancient_apparition_ice_blast = { "ancient_apparition_ice_blast_release" },
	wisp_tether = { "wisp_tether_break" },
	alchemist_unstable_concoction = { "alchemist_unstable_concoction_throw" },
	monkey_king_mischief = { "monkey_king_untransform" },
	monkey_king_primal_spring = { "monkey_king_primal_spring_early" },
}

MULTICAST_TYPE_NONE = 0
MULTICAST_TYPE_SAME = 1      -- Fireblast
MULTICAST_TYPE_DIFFERENT = 2 -- Ignite
MULTICAST_TYPE_INSTANT = 3   -- Bloodlust
MULTICAST_ABILITIES = {
	ogre_magi_bloodlust = MULTICAST_TYPE_INSTANT,
	ogre_magi_fireblast = MULTICAST_TYPE_SAME,
	ogre_magi_ignite = MULTICAST_TYPE_DIFFERENT,
	ogre_magi_unrefined_fireblast = MULTICAST_TYPE_SAME,
	ogre_magi_multicast_arena = MULTICAST_TYPE_NONE,

	item_manta_arena = MULTICAST_TYPE_NONE,
	item_diffusal_style = MULTICAST_TYPE_NONE,
	item_refresher_arena = MULTICAST_TYPE_NONE,
	item_refresher_core = MULTICAST_TYPE_NONE,

	invoker_quas = MULTICAST_TYPE_NONE,
	invoker_wex = MULTICAST_TYPE_NONE,
	invoker_exort = MULTICAST_TYPE_NONE,
	invoker_invoke = MULTICAST_TYPE_NONE,
	shredder_chakram = MULTICAST_TYPE_NONE,
	alchemist_unstable_concoction = MULTICAST_TYPE_NONE,
	alchemist_unstable_concoction_throw = MULTICAST_TYPE_NONE,
	elder_titan_ancestral_spirit = MULTICAST_TYPE_NONE,
	elder_titan_return_spirit = MULTICAST_TYPE_NONE,
	ember_spirit_sleight_of_fist = MULTICAST_TYPE_NONE,
	monkey_king_tree_dance = MULTICAST_TYPE_NONE,
	monkey_king_primal_spring = MULTICAST_TYPE_NONE,
	monkey_king_primal_spring_early = MULTICAST_TYPE_NONE,
	wisp_spirits = MULTICAST_TYPE_NONE,
	wisp_spirits_in = MULTICAST_TYPE_NONE,
	wisp_spirits_out = MULTICAST_TYPE_NONE,
	arc_warden_tempest_double = MULTICAST_TYPE_NONE,
	phoenix_sun_ray = MULTICAST_TYPE_NONE,
	phoenix_sun_ray_stop = MULTICAST_TYPE_NONE,
	phoenix_sun_ray_toggle_move = MULTICAST_TYPE_NONE,

	terrorblade_conjure_image = MULTICAST_TYPE_INSTANT,
	terrorblade_reflection = MULTICAST_TYPE_INSTANT,
	magnataur_empower = MULTICAST_TYPE_INSTANT,
	oracle_purifying_flames = MULTICAST_TYPE_SAME,
	vengefulspirit_magic_missile = MULTICAST_TYPE_SAME,

	item_scythe_of_the_ancients = MULTICAST_TYPE_NONE,

	item_blink = MULTICAST_TYPE_NONE,
	item_arcane_blink = MULTICAST_TYPE_NONE,
	item_swift_blink = MULTICAST_TYPE_NONE,
	item_overwhelming_blink = MULTICAST_TYPE_NONE,
	item_blink_staff = MULTICAST_TYPE_NONE,
	item_ward_observer = MULTICAST_TYPE_NONE,
	item_ward_sentry = MULTICAST_TYPE_NONE,
	item_dust = MULTICAST_TYPE_NONE,
	item_eye_of_the_prophet = MULTICAST_TYPE_NONE,
	item_coffee_bean = MULTICAST_TYPE_NONE,
	item_armlet = MULTICAST_TYPE_NONE,
	item_radiance_arena = MULTICAST_TYPE_NONE,
	item_radiance_2 = MULTICAST_TYPE_NONE,
	item_radiance_3 = MULTICAST_TYPE_NONE,
	item_radiance_frozen = MULTICAST_TYPE_NONE,
	item_summoned_unit = MULTICAST_TYPE_NONE,
	item_behelit = MULTICAST_TYPE_NONE,
	item_golden_eagle_relic = MULTICAST_TYPE_NONE,
}

REFRESH_LIST_IGNORE_REFRESHER = {
	dazzle_good_juju = true,
	item_refresher_arena = true,
	item_refresher_core = true,
	--saitama_push_ups = true,
	--saitama_squats = true,
	--saitama_sit_ups = true,

	--sans_genocide_mod = true,

	faceless_void_chronosphere = true,
	-- enigma_black_hole = true,
	-- tidehunter_ravage = true,
	-- necrolyte_reapers_scythe = true,

	-- item_scythe_of_sun = true,
	item_scythe_of_the_ancients = true,
	item_edge_of_vyse = true,
	-- item_abyssal_blade = true,
	item_sheepstick = true,
	item_demon_king_bar = true,
	item_titanium_bar = true,

	item_behelit = true,
	item_ultimate_scepter_arena = true,

	item_infinity_gauntlet = true,
}

REFRESH_LIST_IGNORE_BODY_RECONSTRUCTION = {
	dazzle_good_juju = true,
	item_refresher_arena = true,
	item_refresher_core = true,
	item_black_king_bar = true,
	item_titanium_bar = true,
	item_coffee_bean = true,
	item_demon_king_bar = true,

	faceless_void_chronosphere = true,
	enigma_black_hole = true,
	necrolyte_reapers_scythe = true,

	destroyer_body_reconstruction = true,

	item_scythe_of_sun = true,
	item_scythe_of_the_ancients = true,
	item_edge_of_vyse = true,
	item_abyssal_blade = true,
	item_sheepstick = true,

	item_behelit = true,
	item_ultimate_scepter_arena = true,

	item_infinity_gauntlet = true,
}

REFRESH_LIST_IGNORE_REARM = {
	dazzle_good_juju = true,
	-- tinker_rearm_arena = true,
	item_refresher_arena = true,
	item_refresher_core = true,
	item_titanium_bar = true,
	item_guardian_greaves_arena = true,
	item_demon_king_bar = true,
	item_pipe = true,
	item_arcane_boots = true,
	item_helm_of_the_dominator = true,
	item_sphere = true,
	item_necronomicon = true,
	item_hand_of_midas_arena = true,
	item_hand_of_midas_2_arena = true,
	item_hand_of_midas_3_arena = true,
	item_mekansm_arena = true,
	item_mekansm_2 = true,
	item_black_king_bar_arena = true,
	item_black_king_bar_2 = true,
	item_black_king_bar_3 = true,
	item_black_king_bar_4 = true,
	item_black_king_bar_5 = true,
	item_black_king_bar_6 = true,

	destroyer_body_reconstruction = true,
	stargazer_cosmic_countdown = true,
	faceless_void_chronosphere = true,
	zuus_thundergods_wrath = true,
	enigma_black_hole = true,
	freya_pain_reflection = true,
	skeleton_king_reincarnation = true,
	dazzle_shallow_grave = true,
	zuus_cloud = true,
	ancient_apparition_ice_blast = true,
	silencer_global_silence = true,
	naga_siren_song_of_the_siren = true,
	slark_shadow_dance = true,
	necrolyte_reapers_scythe = true,

	item_scythe_of_sun = true,
	item_scythe_of_the_ancients = true,
	item_edge_of_vyse = true,
	item_abyssal_blade = true,
	item_sheepstick = true,
	
	-- item_book_of_the_guardian = true,
	-- item_book_of_the_guardian_2 = true,

	item_behelit = true,
	item_ultimate_scepter_arena = true,

	item_infinity_gauntlet = true,
}

COFFEE_BEAN_NOT_REFRESHABLE = {
	dazzle_good_juju = true,
	zuus_cloud = true,
	monkey_king_boundless_strike = true,
	dazzle_shallow_grave = true,
	--saitama_push_ups = true,
	--saitama_squats = true,
	--saitama_sit_ups = true,
}

DUEL_NOT_REFRESHABLE = {
	dazzle_good_juju = true,
	saitama_push_ups = true,
	saitama_squats = true,
	saitama_sit_ups = true,
	item_demon_king_bar = true,
	item_behelit = true,
}


BOSS_BANNED_ABILITIES = {
	item_heart_cyclone = true,
	item_blink_staff = true,
	item_urn_of_demons = true,
	razor_static_link = true,
	tusk_walrus_kick = true,
	--death_prophet_spirit_siphon = true,
	item_force_staff = true,
	item_hurricane_pike = true,
	rubick_telekinesis = true,
	item_demon_king_bar = true,
	morphling_adaptive_strike_str = true,
	item_spirit_helix = true,
	silencer_last_word = true,
	item_scythe_of_the_ancients = true,
	item_ultimate_scepter_arena = true,
	item_harpoon = true,
}

ATTACK_DAMAGE_ABILITIES = {
	nevermore_shadowraze1 = true,
	nevermore_shadowraze2 = true,
	nevermore_shadowraze3 = true,
	clinkz_strafe = true,
	morphling_waveform = 1,

	mars_gods_rebuke = true,
	tidehunter_anchor_smash = true,
	monkey_king_boundless_strike = true,
	dawnbreaker_fire_wreath = true,
	saitama_serious_punch = true,
	--pangolier_swashbuckle = true,

	ember_spirit_sleight_of_fist = true,

	void_spirit_astral_step = true,

	phantom_assassin_stifling_dagger = true,
	juggernaut_omni_slash = true,
	juggernaut_swift_slash = true,

	medusa_split_shot = true,
	medusa_split_shot_arena = true,

	drow_ranger_multishot = true,
	magnataur_empower = true,
	kunkka_tidebringer = true,

	muerta_pierce_the_veil = true,
	muerta_gunslinger = true,
	primal_beast_trample = true,
	omniknight_hammer_of_purity = true,

	hoodwink_acorn_shot = true,
	templar_assassin_psi_blades = true,
	dragon_knight_elder_dragon_form = true,

	luna_moon_glaive = true,
	riki_tricks_of_the_trade = true,

	item_battlefury_arena = true,
	item_quelling_fury = true,
	item_elemental_fury = true,
	item_ultimate_splash = true,

	item_revenants_brooch = true,
}

-- "CalculateSpellDamageTooltip"	"0"
SPELL_AMPLIFY_NOT_SCALABLE_MODIFIERS = table.deepmerge({
	zuus_arc_lightning = "arc_damage",
	phantom_assassin_fan_of_knives = true,
	venomancer_poison_nova = true,
	antimage_mana_void = true,
	zuus_static_field = true,
	enigma_midnight_pulse = true,
	enigma_black_hole = "damage",
	zaken_stitching_strikes = true,
	morphling_adaptive_strike_agi = "damage_base",
	nyx_assassin_mana_burn = true,
	nyx_assassin_spiked_carapace = true,
	nyx_assassin_jolt = true,
	elder_titan_earth_splitter = true,
	necrolyte_reapers_scythe = true,
	doom_bringer_infernal_blade = "burn_damage",
	phoenix_sun_ray = "base_damage",
	silencer_glaives_of_wisdom = true,
	winter_wyvern_arctic_burn = true,
	obsidian_destroyer_sanity_eclipse = true,
	obsidian_destroyer_arcane_orb = true,
	centaur_stampede = true,
	spectre_dispersion = true,
	skywrath_mage_arcane_bolt = "bolt_damage",
	centaur_return = "return_damage",
	huskar_life_break = true,
	huskar_burning_spear_arena = true,
	--death_prophet_spirit_siphon = true,
	witch_doctor_maledict = "damage",
	silencer_last_word = "damage",
	riki_backstab = true,
	bloodseeker_rupture = "movement_damage_pct",
	bloodseeker_blood_mist = true,
	jakiro_liquid_ice = "base_damage",
	--witch_doctor_voodoo_restoration = true,
	sandking_caustic_finale = "caustic_finale_damage_base",
	antimage_counterspell = true,
	bloodseeker_bloodrage = true,
	saber_excalibur = true,
	venomancer_noxious_plague = true,
	freya_ice_cage = true,
	earth_spirit_rolling_boulder = "damage",
	zuus_thundergods_wrath = "damage",

	item_lotus_sphere = true,
	item_spirit_helix = true,
	item_ethereal_blade = true,
	item_witch_blade = true,
	item_spirit_vessel = true,
	item_overwhelming_blink = true,
	item_orchid = true,
	item_bloodthorn = true,
	item_book_of_the_guardian = true,
	item_book_of_the_guardian_2 = true,
	item_unstable_quasar = "base_damage",

	item_sunray_dagon_arena = "damage",
	item_sunray_dagon_2_arena = "damage",
	item_sunray_dagon_3_arena = "damage",
	item_sunray_dagon_4_arena = "damage",
	item_sunray_dagon_5_arena = "damage",

}, ATTACK_DAMAGE_ABILITIES)

MANA_SPEND_SPELLS_EXEPTIONS = {
	obsidian_destroyer_sanity_eclipse = true,
	storm_spirit_ball_lightning = true,
	saber_excalibur = true,
	ogre_magi_unrefined_fireblast = true,
	muerta_gunslinger = true,
	muerta_pierce_the_veil = true,

	item_essential_orb_fire_1 = 80,
	item_essential_orb_fire_2 = 80,
	item_essential_orb_fire_3 = 80,
	item_essential_orb_fire_4 = 80,
	item_essential_orb_fire_5 = 80,
	item_essential_orb_fire_6 = 80,

	item_unstable_quasar = true,

	item_demon_king_bar = true,
	item_fallhammer = true,
	item_maelstrom = true,
	item_mjollnir = true,
	item_gungir = true,
	item_diffusal_style = true,

	zuus_arc_lightning = 50,
	leshrac_lightning_storm = 50,
	bristleback_quill_spray = 50,
	storm_spirit_overload = 50,
}

OCTARINE_NOT_LIFESTALABLE_ABILITIES = {
	["freya_pain_reflection"] = true,
	["spectre_dispersion"] = true,
	["modifier_item_blade_mail_arena_active"] = true,
	["modifier_item_sacred_blade_mail_active"] = true,
	["modififer_sara_conceptual_reflection"] = true,
	--["muerta_gunslinger"] = true,
	["item_battlefury_arena"] = true,
	["item_quelling_fury"] = true,
	["item_elemental_fury"] = true,
	["item_ultimate_splash"] = true,
}

ARENA_NOT_CASTABLE_ABILITIES = {
	["techies_land_mines"] = GetAbilitySpecial("techies_land_mines", "radius"),
	["techies_stasis_trap"] = GetAbilitySpecial("techies_stasis_trap", "activation_radius"),
	["techies_remote_mines"] = GetAbilitySpecial("techies_land_mines", "radius"),
	["invoker_chaos_meteor"] = 1100,
	["disruptor_thunder_strike"] = GetAbilitySpecial("disruptor_thunder_strike", "radius"),
	["pugna_nether_blast"] = GetAbilitySpecial("pugna_nether_blast", "radius"),
	["enigma_midnight_pulse"] = GetAbilitySpecial("enigma_midnight_pulse", "radius"),
	["abyssal_underlord_firestorm"] = GetAbilitySpecial("abyssal_underlord_firestorm", "radius"),
	["skywrath_mage_mystic_flare"] = GetAbilitySpecial("skywrath_mage_mystic_flare", "radius"),
}

PERCENT_DAMAGE_MODIFIERS = {
}

-- https://dota2.gamepedia.com/Spell_Reflection#Not_reflected_abilities
SPELL_REFLECT_IGNORED_ABILITIES = {
	grimstroke_soul_chain = true,
	morphling_replicate = true,
	rubick_spell_steal = true,
}

NO_HEAL_AMPLIFY = {
	oracle_false_promise = true,
	abaddon_borrowed_time = true,
	wisp_tether = true,
	faceless_void_time_walk = true,
	bloodseeker_thirst = true,
	winter_wyvern_cold_embrace = true,

	skywrath_mage_arcane_bolt = true,
	muerta_pierce_the_veil = true,
	bane_brain_sap = true,
	beastmaster_drums_of_slom = true,

	dawnbreaker_converge = true,
	broodmother_insatiable_hunger = true,
	chaos_knight_chaos_strike = true,
	legion_commander_moment_of_courage = true,
	monkey_king_jingu_mastery = true,
	troll_warlord_battle_trance = true,
	skeleton_king_vampiric_aura = true,
	phantom_assassin_phantom_strike = true,
	marci_guardian = true,
	bloodseeker_bloodrage = true,
	juggernaut_blade_dance = true,
	
	life_stealer_open_wounds = true,
	lone_druid_spirit_link = true,

	item_lifesteal = true,
	item_mask_of_madness = true,
	item_satanic = true,
	item_vladmir = true,

	freya_pain_reflection = true,

	item_bloodstone = true,
	item_voodoo_mask = true,
}

HP_REGEN_AMP = {
	{ "item_kaya_and_sange",      "hp_regen_amp" },
	{ "item_sange",               "hp_regen_amp" },
	{ "item_sange_and_yasha",     "hp_regen_amp" },
	{ "item_heavens_halberd",     "hp_regen_amp" },
	{ "item_grandmasters_glaive", "sange_hp_regen_amp" },
	{ "item_trident",             "hp_regen_amp" },
}

ABILITIES_TRIGGERS_ATTACKS = {
	["nevermore_shadowraze1"] = true,
	["nevermore_shadowraze2"] = true,
	["nevermore_shadowraze3"] = true,
	["clinkz_strafe"] = true,
	["morphling_waveform"] = 1,

	["mars_gods_rebuke"] = true,
	["tidehunter_anchor_smash"] = true,
	["monkey_king_boundless_strike"] = true,
	["dawnbreaker_fire_wreath"] = 3,
	["pangolier_swashbuckle"] = 1.4,

	["void_spirit_astral_step"] = true,
}

GAIN_BONUS_GOLD_ITEMS = {
	"item_lucky_coin",
	"item_skull_of_midas",
	"item_chest_of_midas",
	"item_wand_of_midas",
	"item_blood_of_midas",
	"item_golden_eagle_relic",
	"item_ultimate_scepter_arena",
	"item_scythe_of_the_ancients",
}
