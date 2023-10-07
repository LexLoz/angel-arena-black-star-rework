Events:Register("activate", function ()
	CustomGameEventManager:RegisterListener("metamorphosis_elixir_cast", Dynamic_Wrap(GameMode, "MetamorphosisElixirCast"))
	CustomGameEventManager:RegisterListener("modifier_clicked_purge", Dynamic_Wrap(GameMode, "ModifierClickedPurge"))
	CustomGameEventManager:RegisterListener("options_vote", Dynamic_Wrap(Options, "OnVote"))
	CustomGameEventManager:RegisterListener("team_select_host_set_player_team", Dynamic_Wrap(GameMode, "TeamSelectHostSetPlayerTeam"))
	CustomGameEventManager:RegisterListener("set_help_disabled", Dynamic_Wrap(GameMode, "SetHelpDisabled"))
	CustomGameEventManager:RegisterListener("on_ads_clicked", Dynamic_Wrap(GameMode, "OnAdsClicked"))
	CustomGameEventManager:RegisterListener("modifier_universal_attribute_clicked", Dynamic_Wrap(GameMode, "ChangePrimaryBonus"))
end)

function GameMode:ChangePrimaryBonus(data)
	if data.PlayerID and data.unit and data.modifier then
		local ent = EntIndexToHScript(data.unit)
		local mod = ent:FindModifierByName(data.modifier)
		if IsValidEntity(ent) and
			ent:IsAlive() and
			ent:GetPlayerOwnerID() == data.PlayerID and
			table.includes(ONCLICK_PURGABLE_MODIFIERS, data.modifier) and
			not ent:IsStunned() and
			not ent:IsChanneling() and
			not ent:IsHexed() then
				--if not mod.OnCooldown then
					ent:EmitSound("Hero_Tinker.RearmStart")
					if not ent:GetNetworkableEntityInfo("BonusPrimaryAttribute"..tostring(mod.CurrentPrimaryBonus - 1)) then
						ent:SetNetworkableEntityInfo("BonusPrimaryAttribute"..tostring(mod.CurrentPrimaryBonus - 1), nil)
                		ent:RemoveModifierByName(mod.PrimaryBonuses[mod.CurrentPrimaryBonus])
					end
					--print(mod.CurrentPrimaryBonus)
                	mod:ChangePrimaryBonus(mod.CurrentPrimaryBonus + 1)
					Attributes:UpdateAll(ent, 1)

					--if mod.CurrentPrimaryBonus ~= 4 then
						--mod.OnCooldown = true
						--Timers:CreateTimer(2, function()
							--mod.OnCooldown = false
						--end)
					--end
				--else
					--Containers:DisplayError(data.PlayerID, "#dota_hud_error_ability_in_cooldown")
				--end
			else
				Containers:DisplayError(data.PlayerID, "#arena_hud_cant_change_primary_bonus")
			end
	end
end

function GameMode:MetamorphosisElixirCast(data)
	local hero = PlayerResource:GetSelectedHeroEntity(data.PlayerID)
	local elixirItem = FindItemInInventoryByName(hero, "item_metamorphosis_elixir", false)
	local newHeroName = tostring(data.hero)
	if IsValidEntity(hero) and
		hero:GetFullName() ~= newHeroName and
		HeroSelection:IsHeroPickAvaliable(newHeroName) and
		(elixirItem or hero.ForcedHeroChange) and
		(hero.ForcedHeroChange or Options:IsEquals("EnableRatingAffection", false) or
		PlayerResource:GetPlayerStat(data.PlayerID, "ChangedHeroAmount") == 0) then
		if not Duel:IsDuelOngoing() then

			--DropInfinityGauntlet(hero)

			if HeroSelection:ChangeHero(data.PlayerID, newHeroName, true, elixirItem and elixirItem:GetSpecialValueFor("transformation_time") or 0, elixirItem) then
				PlayerResource:ModifyPlayerStat(data.PlayerID, "ChangedHeroAmount", 1)
			end
		else
			Containers:DisplayError(data.PlayerID, "#arena_hud_error_cant_change_hero")
		end
	end
end

function GameMode:ModifierClickedPurge(data)
	if data.PlayerID and data.unit and data.modifier then
		local ent = EntIndexToHScript(data.unit)
		if IsValidEntity(ent) and
			ent:IsAlive() and
			ent:GetPlayerOwnerID() == data.PlayerID and
			table.includes(ONCLICK_PURGABLE_MODIFIERS, data.modifier) and
			not ent:IsStunned() and
			not ent:IsChanneling() then
			ent:RemoveModifierByName(data.modifier)
		end
	end
end

function GameMode:TeamSelectHostSetPlayerTeam(data)
	if GameRules:PlayerHasCustomGameHostPrivileges(PlayerResource:GetPlayer(data.PlayerID)) and data.player then
		if data.team then
			PlayerResource:SetCustomTeamAssignment(tonumber(data.player), tonumber(data.team))
		end
		if data.player2 then
			local team = PlayerResource:GetCustomTeamAssignment(data.player)
			local team2 = PlayerResource:GetCustomTeamAssignment(data.player2)
			PlayerResource:SetCustomTeamAssignment(tonumber(data.player2), DOTA_TEAM_NOTEAM)
			PlayerResource:SetCustomTeamAssignment(tonumber(data.player), team2)
			PlayerResource:SetCustomTeamAssignment(tonumber(data.player2), team)
		end
	end
end

function GameMode:SetHelpDisabled(data)
	local player = data.player or -1
	if PlayerResource:IsValidPlayerID(player) then
		PlayerResource:SetDisableHelpForPlayerID(data.PlayerID, player, tonumber(data.disabled) == 1)
	end
end

function GameMode:OnAdsClicked(data)
	PLAYER_DATA[data.PlayerID].adsClicked = true
end
