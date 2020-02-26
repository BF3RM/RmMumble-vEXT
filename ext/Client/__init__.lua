require 'TCP/TCPSocket'
require 'UDP/UDPSocket'

class 'MumbleImplementationClient'

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")

    self:RegisterEvents()

    self.levelLoaded = false
    self.inGame = PlayerManager:GetLocalPlayer() ~= nil

    self.tcpHandler = nil
    self.udpHandler = nil
end 

function MumbleImplementationClient:RegisterEvents()
	Events:Subscribe("Client:LevelLoaded", self, self.OnJoining)
	Events:Subscribe("Engine:Update", self, self.OnUpdate)
end

function MumbleImplementationClient:OnJoining()
	self.levelLoaded = true
end

function MumbleImplementationClient:OnInGame()
    if self.tcpHandler == nil then
        self.tcpHandler = TCPSocket()
    end
    
    if self.udpHandler == nil then
        self.udpHandler = UDPSocket()
    end
end

function MumbleImplementationClient:OnUpdate(delta, simulationDelta)
	if self.levelLoaded and not self.inGame and PlayerManager:GetLocalPlayer() ~= nil then
        self.inGame = true
    end
    
    if self.inGame then
        self:OnInGame()
        self.tcpHandler:Tick(delta)
        self.udpHandler:Tick(delta)
    end
end

gMumbleImplementationClient = MumbleImplementationClient()

