class "MumbleManager"

local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'
local MumbleSocket = require 'Logic/Mumble/MumbleSocket'

local MetaTable = { __index = nil }

-- Now since lua is shit here we have our event that can't be used from outside

function MumbleManager:__init()
end

function MumbleManager:InternalInit()
    self:RegisterEvents()
    self.EVENT_TALKING = 'ET'
    self.EVENT_MUMBLE_AVAILABLE = 'EMA'
    self.EVENT_MUMBLE_NOT_AVAILABLE = 'EMNA'
    self.EVENT_MUMBLE_NOT_CONNECTED = 'EMNC'
    self.EVENT_CANNOT_GET_SERVER_INFO = 'ECGSI'

    self.SHUTDOWN = 118
    self.IDENTITY_REQUEST = 119
    self.UPDATE_CONTEXT = 120
    self.STOP_TALKING = 121
    self.START_TALKING = 122
    self.GET_UUID_TYPE = 123
    self.MUTE_AND_DEAF = 125

    self.MAIN_MUMBLE_SOCKET_PORT = 64304
    self.THREE_D_MUMBLE_SOCKET_PORT = 55778
    
-- These are the events that you should hook to
    self.LOCAL_TALKING = 0
    self.SQUAD_TALKING = 1
    self.SL_TALKING = 2
--

    self.Listeners = {}
    self.Player = nil
    self.MainMumbleSocket = MumbleSocket("MainSocket", NetSocketFamily.INET, NetSocketType.Stream, self.MAIN_MUMBLE_SOCKET_PORT)
    self.ThreeDMumbleSocket = MumbleSocket("ThreeDSocket", NetSocketFamily.INET, NetSocketType.Datagram, self.THREE_D_MUMBLE_SOCKET_PORT)

    -- self.MainMumbleSocket:Connect()
    -- self.ThreeDMumbleSocket:Connect()

    self:AddListener(self.IDENTITY_REQUEST, self, self.OnIdentityRequested)
    self:AddListener(self.GET_UUID_TYPE, self, self.OnUuidRequested)
    self:AddListener(self.START_TALKING, self, self.OnStartTalking)
    self:AddListener(self.STOP_TALKING, self, self.OnStopTalking)

    self:AddListener(self.LOCAL_TALKING, self, self.OnLocalTalking)
    self:AddListener(self.SQUAD_TALKING, self, self.OnSquadTalking)
    self:AddListener(self.SL_TALKING, self, self.OnSquadLeaderTalking)
    NetEvents:Subscribe('MumbleServerManager:OnServerUuid', self, self.OnUuidReceived)
    Events:Subscribe('Player:SquadChange', self, self.OnSquadChange)
    Events:Subscribe('Player:TeamChange', self, self.OnTeamChange)
    Events:Subscribe('Extension:Unloading', self, self.OnExtensionUnloading)
end

function MumbleManager:OnExtensionUnloading(Player)
    if self.MainMumbleSocket and self.MainMumbleSocket.Socket then
        print ('MumbleManager:OnExtensionUnloading: Destroying Main Socket')
        self.MainMumbleSocket.Socket:Write(string.pack('<I4B', 1, self.SHUTDOWN))
        self.MainMumbleSocket.Socket:Destroy()
    else
        error('MumbleManager:OnExtensionUnloading: Socket or Socket Manager not alive at this point')
    end

    if self.ThreeDMumbleSocket and self.ThreeDMumbleSocket.Socket then
        print ('MumbleManager:OnExtensionUnloading: Destroying 3D Pos Socket')
        self.ThreeDMumbleSocket.Socket:Destroy()
    else
        error('MumbleManager:OnExtensionUnloading: Socket or Socket Manager not alive at this point')
    end
end

function MumbleManager:OnIdentityRequested()
    print('Identity Requested')
    print('Sending cached context to mumble ' .. self.Context)
    local s_Message = string.pack('<I4Bz', (self.Context:len() + 2), self.UPDATE_CONTEXT, self.Context)
    self.MainMumbleSocket.Socket:Write(s_Message)
end

function MumbleManager:OnSquadChange(p_Player, p_SquadID)
    if p_Player == nil then
        return
    end
    
    local s_LocalPlayer = PlayerManager:GetLocalPlayer()

    if s_LocalPlayer ~= nil and s_LocalPlayer.name == p_Player.name then
        self:OnContextChange(p_Player.squadID, p_Player.teamID, p_Player.isSquadLeader)
    end
end

function MumbleManager:OnTeamChange(p_Player, p_TeamID, p_SquadID)
    if p_Player == nil then
        return
    end
    
    local s_LocalPlayer = PlayerManager:GetLocalPlayer()

    if s_LocalPlayer ~= nil and s_LocalPlayer.name == p_Player.name then
        self:OnContextChange(p_Player.squadID, p_Player.teamID, p_Player.isSquadLeader)
    end
end

function MumbleManager:OnContextChange(SquadId, TeamId, IsSquadLeader)
    SquadId = math.floor(SquadId)
    TeamId = math.floor(TeamId)

    local s_IsSquadLeaderBool = 0

    if IsSquadLeader then
        s_IsSquadLeaderBool = 1
    end

    if SquadId == nil or TeamId == nil then
        return
    end

    local s_Context = tostring(TeamId) .. '~~' .. tostring(SquadId) .. '~~' .. tostring(s_IsSquadLeaderBool) -- Doesn't have 0x0 but gets appended by z 
    print('Sending context to mumble ' .. s_Context)
    local s_Message = string.pack('<I4Bz', (s_Context:len() + 2), self.UPDATE_CONTEXT, s_Context)
    self.MainMumbleSocket.Socket:Write(s_Message)
    self.Context = s_Context
end

function MumbleManager:SetMuteAndDeaf(Mute, Deaf)
    local MuteByte = 0
    local DeafByte = 0
    if Mute then MuteByte = 1 end
    if Deaf then DeafByte = 1 end

    local Message = FunctionUtilities:RightPadding(string.format('%c%c%c', self.MUTE_AND_DEAF, MuteByte, DeafByte), 64, '\0')
    self.MainMumbleSocket.Socket:Write(Message)
end

function MumbleManager:OnLocalTalking(Who, Begin)
--    state = 'started'
    if Begin == false then
--        state = 'stopped' end
        print("player " .. Who.name .. " stopped talking on local")
        Events:Dispatch("Mumble:OnPlayerStopTalking", Who, 0)
    else
        print("player " .. Who.name .. " started talking on local")
        Events:Dispatch("Mumble:OnPlayerStartTalking", Who, 0)
    end
    --print (Who .. ' ' .. state .. ' talking locally')
end

function MumbleManager:OnSquadTalking(Who, Begin)
--    state = 'started'
    if Begin == false then
    --        state = 'stopped' end
        print("player " .. Who.name .. " stopped talking on squad")
        Events:Dispatch("Mumble:OnPlayerStopTalking", Who, 1)
    else
        print("player " .. Who.name .. " started talking on squad")
        Events:Dispatch("Mumble:OnPlayerStartTalking", Who, 1)
    end
    --print (Who .. ' ' .. state .. ' talking on squad voice')
end

function MumbleManager:OnSquadLeaderTalking(Who, Begin)
--    state = 'started'
    if Begin == false then
    --        state = 'stopped' end
        print("player " .. Who.name .. " stopped talking on SL comms")
        Events:Dispatch("Mumble:OnPlayerStopTalking", Who, 2)
    else
        print("player " .. Who.name .. " started talking on SL comms")
        Events:Dispatch("Mumble:OnPlayerStartTalking", Who, 2)
    end
    --print (Who .. ' ' .. state .. ' talking on direct SL')
end

function MumbleManager:OnStartTalking(Message)
    local Type = Message:byte(2)
    local Who = Message:sub(3):gsub('%W','')
    local Event = -1

    if Type == 0x0 then
        Event = self.LOCAL_TALKING
    elseif Type == 0x1 then
        Event = self.SQUAD_TALKING
    elseif Type == 0x2 then
        Event = self.SL_TALKING
    end

    print("MumbleManager:OnStartTalking")
    self:OnEvent(Event, Who, true)
end

function MumbleManager:OnStopTalking(Message)
    local Type = Message:byte(2)
    local Who = Message:sub(3):gsub('%W','') 
    local Event = -1

    if Type == 0x0 then
        Event = self.LOCAL_TALKING
    elseif Type == 0x1 then
        Event = self.SQUAD_TALKING
    elseif Type == 0x2 then
        Event = self.SL_TALKING
    end

    print("MumbleManager:OnStopTalking")
    self:OnEvent(Event, Who, false)
end

function MumbleManager:GetInstance()
    local Instance = {}
    if MetaTable.__index == nil then
        MetaTable.__index = MumbleManager()
        MetaTable.__index:InternalInit()
    end
    setmetatable(Instance, MetaTable)
    return Instance
end

function MumbleManager:RegisterEvents()
    Events:Subscribe('Player:Connected', self, self.OnPlayerConnected)
end

function MumbleManager:OnPlayerConnected()
end

function MumbleManager:AddListener(Event, Instance, Callback)
    if FunctionUtilities:IsFunction(Callback) then
        self.Listeners[Event] = self.Listeners[Event] or {}
        table.insert(self.Listeners[Event], {Instance=Instance, Callback=Callback})
    else
        error("MumbleManager:AddListener: The passed argument is not a valid function")
    end
end

function MumbleManager:OnEvent(Event, ...)
    self.Listeners[Event] = self.Listeners[Event] or {}
    for _, Listener in pairs(self.Listeners[Event]) do
        Listener.Callback(Listener.Instance, ...)
    end
end

function MumbleManager:Update(DeltaTime)
    --self:OnContextChange()
    if math.floor((DeltaTime / 2)) * 2 == math.floor(DeltaTime) then
        --self:OnEvent(self.EVENT_TALKING)
    end
end

function MumbleManager:OnUuidRequested()
    print('Retrieving server\'s UUID')
    NetEvents:SendLocal('MumbleServerManager:RequestServerUuid')
end

function MumbleManager:OnUuidReceived(Uuid)
    print('Sending server\'s UUID to mumble (' .. Uuid .. ')')
    local s_UuidAndNick = Uuid .. '|' .. PlayerManager:GetLocalPlayer().name:sub(0, 27) -- Doesn't have 0x0 but gets appended by z 
    local s_Message = string.pack('<I4Bz', (s_UuidAndNick:len() + 2), self.GET_UUID_TYPE, s_UuidAndNick)
    self.MainMumbleSocket.Socket:Write(s_Message)
end

return MumbleManager()
