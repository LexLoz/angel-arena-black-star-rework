modifier_arena_courier = class({})
function modifier_arena_courier:IsHidden() return true end
function modifier_arena_courier:IsPurgable() return false end
function modifier_arena_courier:RemoveOnDeath() return false end

function modifier_arena_courier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		--MODIFIER_EVENT_ON_DEATH,
		--MODIFIER_PROPERTY_RESPAWNTIME 
	} 
end
function modifier_arena_courier:GetModifierMoveSpeed_Absolute() return 800 end
function modifier_arena_courier:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
	}
end

if IsServer() then
	function modifier_arena_courier:OnCreated()
		local courier = self:GetParent()
		self:StartIntervalThink(1)
		courier:SetBaseMaxHealth(1000)
		courier:SetMaxHealth(1000)
		courier:SetHealth(1000)
		--courier:CreatureLevelUp(30)
	end

	function modifier_arena_courier:OnIntervalThink()
		local courier = self:GetParent()

		--drop stones from courier
		--[[for _,v in pairs(STONES_TABLE) do
			local stone =  FindItemInInventoryByName(courier, v[1], _, _, _, true)
			--print(stone)
			if stone then
				local position = FindFountain(courier:GetTeam())
				courier:DropItemAtPositionImmediate(stone, position:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
			end
		end]]
		--[[courier:SetBaseMaxHealth(courier:GetBaseMaxHealth() + COURIER_HEALTH_GROWTH)
		courier:SetMaxHealth(courier:GetMaxHealth() + COURIER_HEALTH_GROWTH)
		courier:SetHealth(courier:GetHealth() + COURIER_HEALTH_GROWTH)]]
	end

	--[[function modifier_arena_courier:GetModifierConstantRespawnTime()
		return 60
	end]]

	function modifier_arena_courier:OnDeath(k)
		local courier = self:GetParent()
		--courier:SetTimeUntilRespawn(60)

		--[[if k.unit == courier then
			for _,v in pairs(STONES_TABLE) do
				local stone =  FindItemInInventoryByName(courier, v[1], _, _, _, true)
				if stone then
					courier:DropItemAtPositionImmediate(stone, courier:GetAbsOrigin() + RandomVector(RandomInt(90, 300)))
				end
			end
		end]]

		--print(self._level)
		--[[Timers:CreateTimer(60, function()
			courier:RespawnUnit()
			courier:UpgradeCourier(10)
			FindClearSpaceForUnit(courier, FindFountain(courier:GetTeam()):GetAbsOrigin(), true)
		end)]]
	end
end
