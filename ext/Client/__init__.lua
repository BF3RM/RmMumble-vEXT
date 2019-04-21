-- Available events:
--  - Mumble:OnPlayerStartTalking (PlayerName, VoiceChannel)
--  - Mumble:OnPlayerStopTalking (PlayerName, VoiceChannel)
--  - Mumble:OnClientNotAvailable ()
-- 
-- Where VoiceChannel:
--  - 0 == Local
--  - 1 == Squad
--  - 2 == Squad Leader Direct

class 'MumbleImplementationClient'

require "__shared/GlobalVars"

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local MumbleEventManager = require "Logic/Mumble/MumbleEventManager"

local MumblePingEvent = require "Logic/Mumble/TimedEvents/MumblePingEvent"
local MumbleServerCheckEvent = require "Logic/Mumble/TimedEvents/MumbleServerCheckEvent"
local MainMumbleSocketEvent = require "Logic/Mumble/TimedEvents/MainMumbleSocketEvent"
local ThreeDMumbleSocketEvent = require "Logic/Mumble/TimedEvents/ThreeDMumbleSocketEvent"

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")
	--MumbleEventManager:AddEvent(MainMumbleSocketEvent)

	self:RegisterVars()
	self:RegisterEvents()
	-- MainMumbleSocketEvent:__init()
	
	MumbleManager:AddListener(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE, self, self.OnMumbleNotAvailable)
	
	MumbleEventManager:AddEvent(MainMumbleSocketEvent)
	MumbleEventManager:AddEvent(MumblePingEvent)
	MumbleEventManager:AddEvent(MumbleServerCheckEvent)
	MumbleEventManager:AddEvent(ThreeDMumbleSocketEvent)

	self.InGame = false
	self.KeyPressed = false
	self.MuteAndDeaf = true
	self.LevelLoaded = false
end

function MumbleImplementationClient:OnMumbleNotAvailable()
	Events:Dispatch('Mumble:OnClientNotAvailable')
end

function MumbleImplementationClient:RegisterVars()
	--self.m_this = that
end


function MumbleImplementationClient:RegisterEvents()
	Hooks:Install("Input:PreUpdate", 999, self, self.OnPreUpdateInput)
	Events:Subscribe("Client:LevelLoaded", self, self.OnJoining)
	Events:Subscribe("Engine:Update", self, self.OnUpdate)
--	Events:Subscribe("Player:Joining", self, self.OnJoining)
end

function MumbleImplementationClient:OnJoining()
	self.LevelLoaded = true
end

function MumbleImplementationClient:OnLoaded()
	-- Initialize the WebUI
	WebUI:Init()

	-- Show the WebUI
	WebUI:Show()

end

function MumbleImplementationClient:OnPreUpdateInput(p_Hook, p_Cache, p_DeltaTime)
	--[[if p_Cache[InputConceptIdentifiers.ConceptReload] > 0.0 and not self.KeyPressed then 
		--MumbleManager:SetMuteAndDeaf(self.MuteAndDeaf, self.MuteAndDeaf)
		self.MuteAndDeaf = not self.MuteAndDeaf
		self.KeyPressed = true
	elseif p_Cache[InputConceptIdentifiers.ConceptReload] == 0.0 and self.KeyPressed then
		self.KeyPressed = false
	end
	]]
end

function MumbleImplementationClient:OnUpdate(p_Delta, p_SimulationDelta)
	if self.LevelLoaded and not self.InGame and PlayerManager:GetLocalPlayer() ~= nil then
		self.InGame = true
	end
	if self.InGame then
		MumbleManager:Update(p_Delta)
		MumbleEventManager:Update(p_Delta)
		MainMumbleSocketEvent:TriggerEvent() -- Let's trigger it manually at each tick for now
	end
end

return MumbleImplementationClient()

