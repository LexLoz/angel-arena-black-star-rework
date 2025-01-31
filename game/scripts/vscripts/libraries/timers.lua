TIMERS_VERSION = "1.07"
require('libraries/binheap')

--[[

	1.06 modified by Celireor (now uses binary heap priority queue instead of iteration to determine timer of shortest duration)

	DO NOT MODIFY A REALTIME TIMER TO USE GAMETIME OR VICE VERSA MIDWAY WITHOUT FIRST REMOVING AND RE-ADDING THE TIMER

	-- A timer running every second that starts immediately on the next frame, respects pauses
	Timers:CreateTimer(function()
			print ("Hello. I'm running immediately and then every second thereafter.")
			return 1.0
		end
	)

	-- The same timer as above with a shorthand call
	Timers(function()
		print ("Hello. I'm running immediately and then every second thereafter.")
		return 1.0
	end)


	-- A timer which calls a function with a table context
	Timers:CreateTimer(GameMode.someFunction, GameMode)

	-- A timer running every second that starts 5 seconds in the future, respects pauses
	Timers:CreateTimer(5, function()
			print ("Hello. I'm running 5 seconds after you called me and then every second thereafter.")
			return 1.0
		end
	)

	-- 10 second delayed, run once using gametime (respect pauses)
	Timers:CreateTimer({
		endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
			print ("Hello. I'm running 10 seconds after when I was started.")
		end
	})

	-- 10 second delayed, run once regardless of pauses
	Timers:CreateTimer({
		useGameTime = false,
		endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
		callback = function()
			print ("Hello. I'm running 10 seconds after I was started even if someone paused the game.")
		end
	})


	-- A timer running every second that starts after 2 minutes regardless of pauses
	Timers:CreateTimer("uniqueTimerString3", {
		useGameTime = false,
		endTime = 120,
		callback = function()
			print ("Hello. I'm running after 2 minutes and then every second thereafter.")
			return 1
		end
	})

]]



TIMERS_THINK = 0.01

if Timers == nil then
	print ( '[Timers] creating Timers' )
	Timers = {}
	setmetatable(Timers, {
		__call = function(t, ...)
			return t:CreateTimer(...)
		end
	})
	--Timers.__index = Timers
end

function Timers:start()
	Timers = self
	self:InitializeTimers()
	self.nextTickCallbacks = {}
	
	local ent = SpawnEntityFromTableSynchronous("info_target", {targetname="timers_lua_thinker"})
	ent:SetThink("Think", self, "timers", TIMERS_THINK)
end

function Timers:Think()


	local nextTickCallbacks = Timers.nextTickCallbacks
	Timers.nextTickCallbacks = {}
	for _, cb in pairs(nextTickCallbacks) do
		DebugCallFunction(cb)
	end
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return
	end

	-- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
	local now = GameRules:GetGameTime()

	-- Process timers
	self:ExecuteTimers(self.realTimeHeap, Time())
	self:ExecuteTimers(self.gameTimeHeap, GameRules:GetGameTime())

	--self:Think()
	return TIMERS_THINK
end

function Timers:ExecuteTimers(timerList, now)
	--Empty timer, ignore
	if not timerList[1] then return end
	
	--Timers are alr. sorted by end time upon insertion
	local currentTimer = timerList[1]
	
	currentTimer.endTime = currentTimer.endTime or now
	--Check if timer has finished
	if now >= currentTimer.endTime then
		-- Remove from timers list
		timerList:Remove(currentTimer)
		Timers.runningTimer = k
		Timers.removeSelf = false

		-- Run the callback
		local status, nextCall
		if currentTimer.context then
			status, nextCall = xpcall(function() return currentTimer.callback(currentTimer.context, currentTimer) end, function (msg)
										return msg..'\n'..debug.traceback()..'\n'
									end)
		else
			status, nextCall = xpcall(function() return currentTimer.callback(currentTimer) end, function (msg)
										return msg..'\n'..debug.traceback()..'\n'
									end)
		end

		Timers.runningTimer = nil

		-- Make sure it worked
		if status then
			-- Check if it needs to loop
			if nextCall and not Timers.removeSelf then
				-- Change its end time
				
				currentTimer.endTime = currentTimer.endTime + nextCall
				
				timerList:Insert(currentTimer)
			end

			-- Update timer data
			--self:UpdateTimerData()
		else
			-- Nope, handle the error
			Timers:HandleEventError('Timer', k, nextCall)
		end
		--run again!
		self:ExecuteTimers(timerList, now)
	end
end

function Timers:HandleEventError(name, event, err)
	if IsInToolsMode() then
		print(err)
	else
		StatsClient:HandleError(err)
	end

	-- Ensure we have data
	name = tostring(name or 'unknown')
	event = tostring(event or 'unknown')
	err = tostring(err or 'unknown')

	-- Tell everyone there was an error

	--Say(nil, name .. ' threw an error on event '..event, false)
	--Say(nil, err, false)

	-- Prevent loop arounds
	if not self.errorHandled then
		-- Store that we handled an error
		self.errorHandled = true
	end
end

function Timers:CreateTimer(arg1, arg2, context)
	local timer
	local key
	if type(arg1) == "function" then
		if arg2 ~= nil then
			context = arg2
		end
		timer = {callback = arg1}
	elseif type(arg1) == "table" then
		timer = arg1
	elseif type(arg1) == "number" then
		timer = {endTime = arg1, callback = arg2}
	elseif type(arg1) == "string" then
		key = string
		timer = arg2
	end
	if not timer.callback then
		print("Invalid timer created")
		return
	end

	local now = GameRules:GetGameTime()
	local timerHeap = self.gameTimeHeap
	if timer.useGameTime ~= nil and timer.useGameTime == false then
		now = Time()
		timerHeap = self.realTimeHeap
	end

	if timer.endTime == nil then
		timer.endTime = now
	else
		timer.endTime = now + timer.endTime
	end

	timer.context = context

	timerHeap:Insert(timer)

	return key or timer
end

function Timers:NextTick(callback)
	table.insert(Timers.nextTickCallbacks, callback)
end

function Timers:RemoveTimer(name)
	local timerHeap = self.gameTimeHeap
	if name.useGameTime ~= nil and name.useGameTime == false then
		timerHeap = self.realTimeHeap
	end
	
	timerHeap:Remove(name)
	if Timers.runningTimer == name then
		Timers.removeSelf = true
	end
end

function Timers:InitializeTimers()
	self.realTimeHeap = BinaryHeap("endTime")
	print(self.realTimeHeap)
	self.gameTimeHeap = BinaryHeap("endTime")
end

GameRules.Timers = Timers
