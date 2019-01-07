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

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local MumbleTimerManager = require "Logic/Mumble/MumbleTimerManager"

local PingEvent = require "Logic/Mumble/TimedEvents/MumblePingEvent"
local SocketReceiver = require "Logic/Mumble/TimedEvents/MumbleSocketReceiverEvent"
local ServerCheck = require "Logic/Mumble/TimedEvents/MumbleServerCheckEvent"
local ThreeDLocation = require "Logic/Mumble/TimedEvents/Mumble3DLocationEvent"

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")
	--MumbleTimerManager:AddEvent(SocketReceiver)

	self:RegisterVars()
	self:RegisterEvents()
	SocketReceiver:__init()
	
	MumbleManager:AddListener(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE, self, self.OnMumbleNotAvailable)
	
	MumbleTimerManager:AddEvent(PingEvent)
	MumbleTimerManager:AddEvent(ServerCheck)
	MumbleTimerManager:AddEvent(ThreeDLocation)

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
		MumbleTimerManager:Update(p_Delta)
		SocketReceiver:TriggerEvent() -- Let's trigger it manually at each tick for now
	end
end

g_MumbleImplementationClient = MumbleImplementationClient()

