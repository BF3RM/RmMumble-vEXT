class 'MumbleImplementationClient'

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local MumbleEventManager = require "Logic/Mumble/MumbleEventManager"
local PingEvent = require "Logic/Mumble/Event/MumblePingEvent"

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")

	MumbleManager:AddListener(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE, self.OnMumbleNotAvailable)
	MumbleEventManager:AddEvent(PingEvent)

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
	MumbleEventManager:Update(p_Delta)
end

g_MumbleImplementationClient = MumbleImplementationClient()

