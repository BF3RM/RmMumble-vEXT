class 'MumbleImplementationClient'

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local MumbleTimerManager = require "Logic/Mumble/MumbleTimerManager"
local PingEvent = require "Logic/Mumble/TimedEvents/MumblePingEvent"
local SocketReceiver = require "Logic/Mumble/TimedEvents/MumbleSocketReceiverEvent"

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")

	MumbleManager:AddListener(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE, self, self.OnMumbleNotAvailable)
	MumbleTimerManager:AddEvent(PingEvent)
	MumbleTimerManager:AddEvent(SocketReceiver)

	self:RegisterVars()
	self:RegisterEvents()
end 

function MumbleImplementationClient:OnMumbleNotAvailable()
	print("Mumble not available (10 secs)!")
end

function MumbleImplementationClient:RegisterVars()
	--self.m_this = that
end


function MumbleImplementationClient:RegisterEvents()
	Events:Subscribe("Engine:Update", self, self.OnUpdate)
end

function MumbleImplementationClient:OnLoaded()
	-- Initialize the WebUI
	WebUI:Init()

	-- Show the WebUI
	WebUI:Show()

end

function MumbleImplementationClient:OnUpdate(p_Delta, p_SimulationDelta)
	MumbleManager:Update(p_Delta)
	MumbleTimerManager:Update(p_Delta)
end

g_MumbleImplementationClient = MumbleImplementationClient()

