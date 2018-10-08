class 'MumbleImplementationClient'

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local MumbleTimerManager = require "Logic/Mumble/MumbleTimerManager"

local PingEvent = require "Logic/Mumble/TimedEvents/MumblePingEvent"
local SocketReceiver = require "Logic/Mumble/TimedEvents/MumbleSocketReceiverEvent"
local ServerCheck = require "Logic/Mumble/TimedEvents/MumbleServerCheckEvent"

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")

	MumbleManager:AddListener(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE, self, self.OnMumbleNotAvailable)
	
	MumbleTimerManager:AddEvent(PingEvent)
	--MumbleTimerManager:AddEvent(SocketReceiver)
	MumbleTimerManager:AddEvent(ServerCheck)

	self:RegisterVars()
	self:RegisterEvents()
	SocketReceiver:__init()

	self.InGame = false
end 

function MumbleImplementationClient:OnMumbleNotAvailable()
	print("Mumble not available (10 secs)!")
end

function MumbleImplementationClient:RegisterVars()
	--self.m_this = that
end


function MumbleImplementationClient:RegisterEvents()
	Events:Subscribe("Engine:Update", self, self.OnUpdate)
	Events:Subscribe("Player:Connected", self, self.OnJoining)
end

function MumbleImplementationClient:OnJoining()
	self.InGame = true
end

function MumbleImplementationClient:OnLoaded()
	-- Initialize the WebUI
	WebUI:Init()

	-- Show the WebUI
	WebUI:Show()

end

function MumbleImplementationClient:OnUpdate(p_Delta, p_SimulationDelta)
	if self.InGame then
		MumbleManager:Update(p_Delta)
		MumbleTimerManager:Update(p_Delta)
		SocketReceiver:TriggerEvent() -- Let's trigger it manually at each tick for now
	end
end

g_MumbleImplementationClient = MumbleImplementationClient()

