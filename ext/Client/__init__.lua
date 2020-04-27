require 'TCP/TCPSocket'
require 'UDP/UDPSocket'

class 'MumbleImplementationClient'

function MumbleImplementationClient:__init()
	print("Initializing MumbleImplementationClient")

    self:RegisterEvents()

    self.levelLoaded = false
    self.inGame = false

    self.tcpHandler = nil
    self.udpHandler = nil
    self.targetServer = '127.0.0.1|64738'
end 

function MumbleImplementationClient:RegisterEvents()
	Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)
	Events:Subscribe("Engine:Update", self, self.OnUpdate)
    NetEvents:Subscribe('MumbleServerManager:MumbleServerAddressChanged', self, self.OnMumbleServerAddressChanged)
    Events:Subscribe("Player:Connected", self, self.OnPlayerConnected)
    Events:Subscribe('Level:Destroy', self, self.OnLevelDestroyed)
end

function MumbleImplementationClient:OnLevelDestroyed()
    self.levelLoaded = false
    self.inGame = false
    self.tcpHandler = nil
    self.udpHandler = nil
end

function MumbleImplementationClient:OnMumbleServerAddressChanged(mumbleServerAddress)
    -- Ignore if it hasnt changed.
    if mumbleServerAddress == self.targetServer then
        return
    end
    print("Got new murmur ip")
    self.targetServer = mumbleServerAddress

    if self.tcpHandler then
        self.tcpHandler:OnMumbleServerAddressChanged(mumbleServerAddress)
    end
end

function MumbleImplementationClient:OnPlayerConnected(player)
    if player == nil then
        return
    end
    if player == PlayerManager:GetLocalPlayer() then
        NetEvents:SendLocal('MumbleServerManager:GetMumbleServerIp')
    end
end

function MumbleImplementationClient:OnLevelLoaded()
	self.levelLoaded = true
end

function MumbleImplementationClient:OnInGame()
    if self.tcpHandler == nil then
        print("LevelLoaded, creating TCPSocket.")
        self.tcpHandler = TCPSocket(self.targetServer)
    end
    
    if self.udpHandler == nil then
        print("LevelLoaded, creating UDPSocket.")
        self.udpHandler = UDPSocket()
    end
end

function MumbleImplementationClient:OnUpdate(delta, simulationDelta)
	if self.levelLoaded and not self.inGame and PlayerManager:GetLocalPlayer() ~= nil then
        self.inGame = true
        self:OnInGame()
    end
    
    if self.inGame then
        self.tcpHandler:Tick(delta)
        self.udpHandler:Tick(delta)
    end
end

gMumbleImplementationClient = MumbleImplementationClient()

