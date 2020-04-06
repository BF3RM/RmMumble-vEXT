require 'TCP/Ping'
require 'TCP/UpdatePlayersInfo'
require 'TCP/PlayerContext'
require 'TCP/VoiceEvents'

class 'TCPSocket'

function TCPSocket:__init()
	print("Initializing TCPSocket")

    self.socket = Net:Socket(NetSocketFamily.INET, NetSocketType.Stream)
    self.socketOpen = false
    self.isConnecting = false
    self.targetServer = '127.0.0.1|64738'
    self.reconnectionDelta = 0.0

    NetEvents:Subscribe('MumbleServerManager:MumbleServerAddressChanged', self, self.OnMumbleServerAddressChanged)
    Events:Subscribe('Extension:Unloading', self, self.OnExtensionUnloading)
    Events:Subscribe('Player:Connected', self, self.OnPlayerConnected)

    self.pingHandler = Ping(self.socket)
    self.updatePlayersInfoHandler = UpdatePlayersInfo(self.socket)
    self.playerContextHandler = PlayerContext(self.socket)
    self.voiceEventsHandler = VoiceEvents()
    self:SetupSocket()
end 

function TCPSocket:OnPlayerConnected(player)
    -- force player name update here
    self:SendNickname()
end

function TCPSocket:OnMumbleServerAddressChanged(mumbleServerAddress)
    self.targetServer = mumbleServerAddress
    if self.socketOpen then
      self:SendNickname()
      message = string.pack('<I4Bz', (self.targetServer:len() + 2), 126, self.targetServer)
      self.socket:Write(message)
    end
end

function TCPSocket:SetupSocket()
    if not self:AttemptConnection() then
        print('Coulnd\'t connect to mumble. Is mumble up and running? Retrying in 5 seconds...')
    end
end

function TCPSocket:OnExtensionUnloading(player)
    if self.socketOpen then
        print ('TCPSocket:OnExtensionUnloading: Sending goodbye to mumble')
        self.socket:Write(string.pack('<I4B', 1, 118))
        self.socket:Destroy()
    else
        print ('TCPSocket:OnExtensionUnloading: Socket or Socket Manager not alive at this point')
    end
end

function TCPSocket:AttemptConnection()
    local connectResult = self.socket:Connect('127.0.0.1', 64304)
    if connectResult == 0 then
        print('Connected to mumble')
        self.socketOpen = true
        self.reconnectionDelta = 0.0
        return true
    elseif connectResult == 10035 then -- connecting
        self.isConnecting = false
        return false
    elseif connectResult == 10022 then --  WSAEINVAL
        print('Connect returned WSAEINVAL')
        return false
    elseif connectResult == 10037 then -- WSAEALREADY
        self.isConnecting = true
        self.reconnectionDelta = 0.0
        return true
    elseif connectResult == 10056 then -- WSAEISCONN
        print('Connected to mumble')
        self.socketOpen = true
        self.isConnecting = false
        self.reconnectionDelta = 0.0
        self:OnConnected()
        return true
    else
        print('Coulnd\'t connect to mumble. Is mumble up and running?')
        self.socketOpen = false
        return false
    end
end

function TCPSocket:SendNickname()
    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        print('Local player was nil for some reason. Cannot send nickname.')
        return
    end

    local uuidAndNick = 'Uuid' .. '|' .. localPlayer.name:sub(0, 27) -- Doesn't have 0x0 but gets appended by z 
    Message = string.pack('<I4Bz', (uuidAndNick:len() + 2), 123, uuidAndNick)
    self.socket:Write(Message)
end

function TCPSocket:OnConnected()
    self:SendNickname()

    NetEvents:SendLocal('MumbleServerManager:GetMumbleServerIp')
end

function TCPSocket:HandlePacket(packet)
    eventType = packet:byte(1)

    if eventType == 122 then
        voiceType = packet:byte(2)
        who = packet:sub(3):gsub('%W','')
        self.voiceEventsHandler:HandleStartVoiceEvent(voiceType, who)
    end
end

function TCPSocket:HandleRead()
    if not self.socketOpen then
        return
    end

    local data, statusCode = self.socket:Read(4)
    if statusCode == 10035 then -- WSAEWOULDBLOCK - no data available
        return
    elseif statusCode ~= 0 then -- socket deaded, rip
        print('Connection deaded. Rest in pepperoni mumble.')
        self.socket:Destroy()
        self.socket = Net:Socket(NetSocketFamily.INET, NetSocketType.Stream)
        self.pingHandler.socket = self.socket
        self.updatePlayersInfoHandler.socket = self.socket
        self.playerContextHandler.socket = self.socket
        self.socketOpen = false
    elseif data == nil then
        return
    elseif data:len() == 0 then -- if data len == 0 and status code == 0, socket has been gracefully closed
        print('Connection has been gracefully closed.')
        self.socketOpen = false
    elseif data:len() > 0 then -- data available
        local packetSize = string.unpack('<I4', data)
        --print('received ' .. data:len() .. ' bytes. Packet size: ' .. packetSize)
        data, statusCode = self.socket:Read(packetSize) -- pretending data will always be ok
        self:HandlePacket(data)
    end
end

function TCPSocket:HandleConnection()
    if not self.isConnecting then
        return
    else
        self:AttemptConnection()
    end
end

function TCPSocket:Tick(delta)
    if not self.socketOpen then
        self.reconnectionDelta = self.reconnectionDelta + delta
    end

    if self.reconnectionDelta >= 5.0 then
        self.isConnecting = false
        self.reconnectionDelta = 0.0
        self:SetupSocket()
    end

    -- self:HandleConnection()
    self:HandleRead()

    self.voiceEventsHandler:Tick(delta)

    if self.socketOpen then
        self.pingHandler:Tick(delta)
        self.updatePlayersInfoHandler:Tick(delta)
    end
end
