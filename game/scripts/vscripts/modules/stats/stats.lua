StatsClient = StatsClient or class({})
ModuleRequire(..., "data")

Events:Register("activate", function ()
	PlayerTables:CreateTable("stats_client", {}, AllPlayersInterval)
	PlayerTables:CreateTable("stats_team_rating", {}, AllPlayersInterval)
	CustomGameEventManager:RegisterListener("stats_client_add_guide", Dynamic_Wrap(StatsClient, "AddGuide"))
	CustomGameEventManager:RegisterListener("stats_client_vote_guide", Dynamic_Wrap(StatsClient, "VoteGuide"))
end)

function StatsClient:FetchPreGameData()
	local data = {
		matchid = tostring(GameRules:Script_GetMatchID()),
		players = {},
	}
	for i = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:IsValidPlayerID(i) and not PlayerResource:IsPlayerAbandoned(i) then
			data.players[i] = PlayerResource:GetRealSteamID(i)
		end
	end

	StatsClient:Send("fetchPreGameMatchData", data, function(response)
		for playerId, data in pairs(response) do
			playerId = tonumber(playerId)

			PLAYER_DATA[playerId].serverData = data
			PLAYER_DATA[playerId].Inventory = data.inventory or {}
			local isBanned = Options:IsEquals("EnableBans") and data.isBanned == true
			PLAYER_DATA[z].isBanned = isBanned

			local clientData = table.deepcopy(data)
			clientData.TBDRating = nil
			PlayerTables:SetTableValue("stats_client", playerId, clientData)

			if isBanned then
				PlayerResource:MakePlayerAbandoned(playerId)
			end
		end
	end, math.huge)
end

function StatsClient:CalculateAverageRating()
	local teamRatings = {}

	for playerId, data in pairs(PLAYER_DATA) do
		local team = PlayerResource:GetTeam(playerId)
		if data.serverData and not PlayerResource:IsBanned(playerId) then
			teamRatings[team] = teamRatings[team] or {}
			table.insert(teamRatings[team], data.serverData.Rating or (2500 + (data.serverData.TBDRating or 0)))
		end
	end

	for team, values in pairs(teamRatings) do
		PlayerTables:SetTableValue("stats_team_rating", team, math.round(table.average(values)))
	end
end

function StatsClient:AssignTeams(callback)
	local data = {
		size = Teams.Data[DOTA_TEAM_GOODGUYS].count,
		players = {},
	}
	for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(i) then
			table.insert(data.players, { id = i, steamid = PlayerResource:GetRealSteamID(i) })
		end
	end

	StatsClient:Send("assignTeams", data, callback, false, nil, function(response)
		GameMode:BreakSetup(response.error and ("Server error: " .. response.error) or "Unknown server error")
	end)
end

function StatsClient:OnGameEnd(winner)
	--local status, nextCall = xpcall(function()
	GameRules:SetSafeToLeave(true)
		if GameMode.Broken then
			PlayerTables:CreateTable("stats_game_result", {error = GameMode.Broken}, AllPlayersInterval)
			return
		end
		if not IsInToolsMode() and StatsClient.GameEndScheduled then return end
		StatsClient.GameEndScheduled = true
		local time = GameRules:GetDOTATime(false, true)
		local matchID = tostring(GameRules:Script_GetMatchID())
		if (GameRules:IsCheatMode() and not StatsClient.Debug) or time < 0 then
			return
		end
		local data = {
			matchID = matchID,
			mapName = GetMapName(),
			players = {},
			killGoal = KILLS_TO_END_GAME_FOR_TEAM,
			teamsInfo = {},
			version = ARENA_VERSION,
			duration = math.floor(time),
			flags = {
				isRanked = Options:IsEquals("EnableRatingAffection")
			}
		}

		for i = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
			if GetTeamAllPlayerCount(i) > 0 then
				data.teamsInfo[tostring(i)] = {
					duelsWon = (Duel.TimesTeamWins[i] or 0),
					isGameWinner = i == winner,
					score = Teams:GetScore(i),
				}
			end
		end

		for i = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if PlayerResource:IsValidPlayerID(i) then
				local hero = PlayerResource:GetSelectedHeroEntity(i)
				local playerInfo = {
					abandoned = PlayerResource:IsPlayerAbandoned(i),
					steamid = PlayerResource:GetRealSteamID(i),

					heroDamage = PlayerResource:GetPlayerStat(i, "heroDamage"),
					bossDamage = PlayerResource:GetPlayerStat(i, "bossDamage"),
					heroHealing = PlayerResource:GetHealing(i),
					duelsPlayed = PlayerResource:GetPlayerStat(i, "Duels_Played"),
					duelsWon = PlayerResource:GetPlayerStat(i, "Duels_Won"),
					kills = PlayerResource:GetKills(i),
					deaths = PlayerResource:GetDeaths(i),
					assists = PlayerResource:GetAssists(i),
					lasthits = PlayerResource:GetLastHits(i),
					heroName = HeroSelection:GetSelectedHeroName(i) or "",
					bonus_str = 0,
					bonus_agi = 0,
					bonus_int = 0,

					team = tonumber(PlayerResource:GetTeam(i)),
					level = 0,
					items = {}
				}
				if IsValidEntity(hero) then
					playerInfo.level = hero:GetLevel()
					if hero.Additional_str then playerInfo.bonus_str = hero.Additional_str end
					if hero.Additional_agi then playerInfo.bonus_agi = hero.Additional_agi end
					if hero.Additional_int then playerInfo.bonus_int = hero.Additional_int end
					for item_slot = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
						local item = hero:GetItemInSlot(item_slot)
						if item then
							playerInfo.items[item_slot] = {
								name = item:GetAbilityName(),
								charges = item:GetCurrentCharges()
							}
						end
					end
					if playerInfo.heroName == "" then playerInfo.heroName = hero:GetFullName() end
				end
				playerInfo.netWorth = Gold:GetGold(i)
				for slot, item in pairs(playerInfo.items) do
					playerInfo.netWorth = playerInfo.netWorth + GetTrueItemCost(item.name)
				end
				data.players[i] = playerInfo
			end
		end
		PrintTable(data)

		local clientData = {players = {}}

		--StatsClient:Send("endMatch", data, function(response)
			--[[if not response.players then
				local err = response.error and ("Server error: " .. response.error) or "Unknown server error"
				PlayerTables:CreateTable("stats_game_result", { error = err }, AllPlayersInterval)
			else]]
				--for playerId, receivedData in pairs(response.players) do
				for i,_ in pairs(data.players) do
					local playerId = i
					--[[if PlayerResource:IsValidPlayerID(i) then
						playerId = i
					else
						return print("error load screen")
					end]]
					local sentData = data.players[playerId]
					clientData.players[playerId] = {
						hero = sentData.heroName,
						heroDamage = sentData.heroDamage,
						bossDamage = sentData.bossDamage,
						heroHealing = sentData.heroHealing,

						netWorth = sentData.netWorth,
						bonus_str = sentData.bonus_str,
						bonus_agi = sentData.bonus_agi,
						bonus_int = sentData.bonus_int,
						items = sentData.items,

						--ratingNew = receivedData.ratingNew,
						--ratingOld = receivedData.ratingOld,
						--ratingGamesRemaining = receivedData.ratingGamesRemaining or 10,
						--experienceNew = receivedData.experienceNew or 0,
						--experienceOld = receivedData.experienceOld or 0,
					}
				end
				PlayerTables:CreateTable("stats_game_result", clientData, AllPlayersInterval)
			--end
		--end, math.huge, nil, true)
	--end, function(msg)
		--return msg..'\n'..debug.traceback()..'\n'
	--end)
	--if not status then
		--PlayerTables:CreateTable("stats_game_result", {error = nextCall}, AllPlayersInterval)
	--end
end

function StatsClient:HandleError(err)
	if err and type(err) == "string" then
		StatsClient:Send("HandleError", {
			version = ARENA_VERSION,
			text = err
		})
	end
end

--Guides
function StatsClient:AddGuide(data)
	data = {

	PlayerID = 0,
	description = "",
	items = {
			[3] = {
					content = {
							[0] = "item_wand_of_midas",
							[1] = "item_chest_of_midas",
							[2] = "item_blood_of_midas",
							[3] = "item_bottle_arena",
							[4] = "item_hand_of_midas_2_arena",
							[5] = "item_refresher_arena"},
					title = "for gang"},
			[0] = {
					content = {
							[0] = "item_skull_of_midas",
							[1] = "item_splitshot_ultimate",
							[2] = "item_thunder_musket",
							[3] = "item_golden_eagle_relic",
							[4] = "item_butterfly_of_wind",
							[5] = "item_skadi_4",
							[6] = "item_piercing_blade",
							[7] = "item_monkey_king_bar"},
					title = "range"},
			[10] = {
					content = {
							[0] = "item_ultimate_splash",
							[1] = "item_elemental_fury",
							[10] = "item_bloodthorn_2",
							[11] = "item_fallhammer",
							[12] = "item_radiance_frozen",
							[13] = "item_book_of_the_guardian_2",
							[14] = "item_unstable_quasar",
							[15] = "item_refresher_core",
							[16] = "item_essential_orb_fire_6",
							[17] = "item_essential_orb_fire_5",
							[2] = "item_splitshot_ultimate",
							[3] = "item_thunder_musket",
							[4] = "item_summoned_unit",
							[5] = "item_assault",
							[6] = "item_phantom_cuirass",
							[7] = "item_golden_eagle_relic",
							[8] = "item_soulcutter",
							[9] = "item_demonic_cuirass",},
					title = "for farm bears",},
			[1] = {
					content = {
							[0] = "item_skull_of_midas",
							[1] = "item_elemental_fury",
							[2] = "item_fallhammer",
							[3] = "item_golden_eagle_relic",
							[4] = "item_butterfly_of_wind",
							[5] = "item_skadi_4",
							[6] = "item_piercing_blade",
							[7] = "item_monkey_king_bar",},
					title = "meele"},
			[2] = {
					content = {
							[0] = "item_skull_of_midas",
							[1] = "item_essential_orb_fire_6",
							[10] = "item_sange_and_yasha_and_kaya",
							[11] = "item_refresher_arena",
							[2] = "item_essential_orb_fire_5",
							[3] = "item_radiance_3",
							[4] = "item_octarine_core_arena",
							[5] = "item_book_of_the_guardian",
							[6] = "item_bloodstone",
							[7] = "item_ultimate_scepter_arena",
							[8] = "item_blade_of_discord",
							[9] = "item_book_of_the_keeper",},
					title = "mage"},
			[4] = {
					content = {
							[0] = "item_summoned_unit",
							[1] = "item_assault",
							[2] = "item_phantom_cuirass",
							[3] = "item_vladmir",
							[4] = "item_dark_flow",
							[5] = "item_desolator3",
							[6] = "item_thunder_musket",
							-- [7]	= "item_shard_level10"
						},
					title = "for boss"},
			[5] = {
					content = {
							[0] = "item_ultimate_splash",
							[1] = "item_desolator6",
							[2] = "item_soulcutter",
							[3] = "item_demonic_cuirass",
							[4] = "item_diffusal_style",
							[5] = "item_radiance_frozen",
							[6] = "item_demon_king_bar",
							[7] = "item_timelords_butterfly",
							[8] = "item_shard_str_extreme",
							[9] = "item_shard_agi_extreme"},
					title = "LATE FOR CARRY",},
			[6] = {
					content = {
							[0] = "item_ultimate_splash",
							[1] = "item_scythe_of_the_ancients",
							[2] = "item_unstable_quasar",
							[3] = "item_book_of_the_guardian_2",
							[4] = "item_radiance_frozen",
							[5] = "item_titanium_bar",
							[6] = "item_scythe_of_sun",
							[7] = "item_sunray_dagon_5_arena",
							[8] = "item_shard_int_extreme",
							[9] = "item_shard_agi_extreme"},
					title = "LATE FOR MAGE",},
			[7] = {
					content = {
							[0] = "item_behelit",
							[1] = "item_coffee_bean",
							[2] = "item_octarine_core_arena",
							[3] = "item_refresher_arena",},
					title = "FOR summoners"},
			[8] = {
					content = {
							[0] = "item_flesh_potion",
							[1] = "item_titanium_fruit",
							[2] = "item_eye_of_the_prophet",
							[3] = "item_lightning_rod",},
					title = "optional"},
			[9] = {
					content = {
							[0] = "item_pipe_of_enlightenment",
							[1] = "item_sacred_blade_mail",
							[2] = "item_lotus_sphere",
							[3] = "item_vermillion_robe",},
					title = "against mages",},
	},
	steamID = "-1",
	title = "",
    youtube = "",
	}
	
	local playerId = data.PlayerID
	local hero = HeroSelection:GetSelectedHeroName(playerId)
	local steamID = PlayerResource:GetRealSteamID(playerId)
	--[[if #data.title < 4 or #data.description < 4 then
		return
	end
	if #data.title > 60 or #data.description > 250 or table.count(data.items) == 0 then
		return
	end
	if not NPC_HEROES_CUSTOM[hero] or NPC_HEROES_CUSTOM[hero].Enabled == 0 then
		return
	end
	for _,group in ipairs(data.items) do
		if type(group.title) ~= "string" or #group.title > 20 then
			return
		end
		for _,item in ipairs(group.content) do
			if not KeyValues.ItemKV[item] then
				error("Invalid item", item)
			end
		end
	end]]

	--[[if data.youtube ~= nil and (type(data.youtube) ~= "string" or #data.youtube == 0) then
		data.youtube = nil
	end]]

	CustomGameEventManager:Send_ServerToAllClients("stats_client_add_guide_success", {
		title = data.title,
		description = data.description,
		steamID = steamID,
		hero = hero,
		items = data.items,
		youtube = data.youtube,
		version = ARENA_VERSION,
	})
	--print('send guide')

	--[[StatsClient:Send("AddGuide", {
		title = data.title,
		description = data.description,
		steamID = steamID,
		hero = hero,
		items = data.items,
		youtube = data.youtube,
		version = ARENA_VERSION,
	} function(response)
		if response.insertedId then
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "stats_client_add_guide_success", {insertedId = response.insertedId})
		else
			Containers:DisplayError(playerId, response.error)
		end
	end)]]
end

function StatsClient:VoteGuide(data)
	StatsClient:Send("VoteGuide", {
		steamID = PlayerResource:GetRealSteamID(data.PlayerID),
		id = data.id or "",
		vote = type(data.vote) == "number" and data.vote or 0
	})
end

local AUTH_KEY = GetDedicatedServerKey("1")
function StatsClient:Send(path, data, callback, retryCount, protocol, onerror, _currentRetry)
	--[[if type(retryCount) == "boolean" then
		retryCount = retryCount and math.huge or 0
	elseif not retryCount then
		retryCount = 0
	end]]
	--local request = CreateHTTPRequestScriptVM(protocol or "POST", self.ServerAddress .. path .. (protocol == "GET" and StatsClient:EncodeParams(data) or ""))
	--request:SetHTTPRequestHeaderValue("Auth-Key", AUTH_KEY)
	--request:SetHTTPRequestGetOrPostParameter("data", json.encode(data))
	--request:Send(function(response)
		--[[if response.StatusCode ~= 200 or not response.Body then
			local currentRetry = (_currentRetry or 0) + 1
			if not StatsClient.Debug and currentRetry < retryCount then
				Timers:CreateTimer(self.RetryDelay, function()
					StatsClient:Send(path, data, callback, retryCount, protocol, onerror, currentRetry)
				end)
			elseif onerror then
				if onerror == true then onerror = callback end

				local resp = json.decode(response.Body)
				if type(resp) ~= "table" then resp = {} end
				onerror(resp, response.StatusCode)
			end
		else
			local obj, pos, err = json.decode(response.Body)
			if obj and callback then
				callback(obj)
			end
		end
	end)]]
end

function StatsClient:EncodeParams(params)
	if type(params) ~= "table" or next(params) == nil then return "" end
	local str = "/?"
	for k,v in pairs(params) do
		k = k:gsub("([^%w ])", function(c) return string.format("%%%02X", string.byte(c)) end):gsub(" ", "+")
		v = v:gsub("([^%w ])", function(c) return string.format("%%%02X", string.byte(c)) end):gsub(" ", "+")
		str = str + k + "=" + v
	end
	return str
end
