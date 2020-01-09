class "MumbleManager"

local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

local MetaTable = { __index = nil }

-- Now since lua is shit here we have our event that can't be used from outside

function MumbleManager:__init()
end

function MumbleManager:InternalInit()
    self:RegisterEvents()
    self.EVENT_TALKING = 'ET'
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
    self.SET_MUMBLE_IP = 126
    
-- These are the events that you should hook to
    self.LOCAL_TALKING = 0
    self.SQUAD_TALKING = 1
    self.SL_TALKING = 2
--

    self.Listeners = {}
    self.Player = nil
    self.MumbleSocket = require 'Logic/Mumble/MumbleSocket'
    self.PlayersTalkingState = {}
    self.LastDelta = 0
    self.MumbleIP = '0.0.0.0|0000'

    self:AddListener(self.IDENTITY_REQUEST, self, self.OnIdentityRequested)
    self:AddListener(self.GET_UUID_TYPE, self, self.OnUuidRequested)
    self:AddListener(self.START_TALKING, self, self.OnStartTalking)
    self:AddListener(self.STOP_TALKING, self, self.OnStopTalking)

    self:AddListener(self.LOCAL_TALKING, self, self.OnLocalTalking)
    self:AddListener(self.SQUAD_TALKING, self, self.OnSquadTalking)
    self:AddListener(self.SL_TALKING, self, self.OnSquadLeaderTalking)
    NetEvents:Subscribe('MumbleServerManager:OnServerUuid', self, self.OnUuidReceived)
    NetEvents:Subscribe('MumbleServerManager:OnMumbleIpUpdated', self, self.OnMumbleIpUpdated)
    Events:Subscribe('Player:SquadChange', self, self.SquadChange)
    Events:Subscribe('Player:TeamChange', self, self.TeamChange)
    Events:Subscribe('Extension:Unloading', self, self.OnExtensionUnloading)
    Events:Subscribe('Engine:Update', self, self.OnUpdate)
end

function MumbleManager:SquadChange(p_Player, p_SquadId)
    if p_Player == nil then
        return
    end
    
    local s_LocalPlayer = PlayerManager:GetLocalPlayer()

    if s_LocalPlayer ~= nil and s_LocalPlayer.name == p_Player.name then
        self:OnContextChange(p_Player.squadId, p_Player.teamId, p_Player.isSquadLeader)
    end
end

function MumbleManager:TeamChange(p_Player, p_TeamId, p_SquadId)
    if p_Player == nil then
        return
    end
    
    local s_LocalPlayer = PlayerManager:GetLocalPlayer()

    if s_LocalPlayer ~= nil and s_LocalPlayer.name == p_Player.name then
        self:OnContextChange(p_Player.squadId, p_Player.teamId, p_Player.isSquadLeader)
    end
end

function MumbleManager:OnUpdate(p_Delta, p_SimulationDelta)
    --self.LastDelta = self.LastDelta + p_Delta
--
    --if self.LastDelta < 0.2 then
    --    return
    --end

    for playerName, state in pairs(self.PlayersTalkingState) do
        state.timer = state.timer - p_Delta
        if state.timer < 0 then

            --call eevent
            Events:Dispatch('Mumble:OnTalk', playerName, 0x0)
            self.PlayersTalkingState[playerName] = nil
        end
    end

    --self.LastDelta = 0
end

function MumbleManager:OnExtensionUnloading(Player)
    if self.MumbleSocket and self.MumbleSocket.Socket then
        print ('MumbleManager:OnExtensionUnloading: Sending goodbye to mumble')
        self.MumbleSocket.Socket:Write(string.pack('<I4B', 1, self.SHUTDOWN))
        self.MumbleSocket.Socket:Destroy()
    else
        print ('MumbleManager:OnExtensionUnloading: Socket or Socket Manager not alive at this point')
    end
end

function MumbleManager:OnIdentityRequested()
    print('Identity Requested')
    print('Sending cached context to mumble ' .. Context)
    Message = string.pack('<I4Bz', (self.Context:len() + 2), self.UPDATE_CONTEXT, self.Context)
    self.MumbleSocket.Socket:Write(Message)
end

function MumbleManager:OnContextChange(SquadId, TeamId, IsSquadLeader)
    SquadId = math.floor(SquadId+0.1)
    TeamId = math.floor(TeamId+0.1)

    IsSquadLeaderBool = 0
    if IsSquadLeader then
        IsSquadLeaderBool = 1
    end

    if SquadId == nil or TeamId == nil then
        return
    end

    Context = tostring(TeamId) .. '~~' .. tostring(SquadId) .. '~~' .. tostring(IsSquadLeaderBool) -- Doesn't have 0x0 but gets appended by z 
    print('Sending context to mumble ' .. Context)
    Message = string.pack('<I4Bz', (Context:len() + 2), self.UPDATE_CONTEXT, Context)
    self.MumbleSocket.Socket:Write(Message)
    self.Context = Context
end

-- Debug only
function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end
--

function MumbleManager:SetMuteAndDeaf(Mute, Deaf)
    MuteByte = 0
    DeafByte = 0
    if Mute then MuteByte = 1 end
    if Deaf then DeafByte = 1 end

    Message = FunctionUtilities:RightPadding(string.format('%c%c%c', self.MUTE_AND_DEAF, MuteByte, DeafByte), 64, '\0')
    self.MumbleSocket.Socket:Write(Message)
end

function MumbleManager:OnLocalTalking(Who, Begin)
--    state = 'started'
    if Begin == false then 
--        state = 'stopped' end
        Events:Dispatch("Mumble:OnPlayerStopTalking", Who, 0)
    else
        Events:Dispatch("Mumble:OnPlayerStartTalking", Who, 0)
    end
    --print (Who .. ' ' .. state .. ' talking locally')
end

function MumbleManager:OnSquadTalking(Who, Begin)
--    state = 'started'
    if Begin == false then 
    --        state = 'stopped' end
        Events:Dispatch("Mumble:OnPlayerStopTalking", Who, 1)
    else
        Events:Dispatch("Mumble:OnPlayerStartTalking", Who, 1)
    end
    --print (Who .. ' ' .. state .. ' talking on squad voice')
end

function MumbleManager:OnSquadLeaderTalking(Who, Begin)
--    state = 'started'
    if Begin == false then 
    --        state = 'stopped' end
        Events:Dispatch("Mumble:OnPlayerStopTalking", Who, 2)
    else
        Events:Dispatch("Mumble:OnPlayerStartTalking", Who, 2)
    end
    --print (Who .. ' ' .. state .. ' talking on direct SL')
end

function MumbleManager:OnStartTalking(Message)
    Type = Message:byte(1)
    Who = Message:sub(2):gsub('%W','') 

    local s_LocalPlayer = PlayerManager:GetLocalPlayer()

    if s_LocalPlayer == nil then
        return
    end

    if s_LocalPlayer.name == Who then
        Events:Dispatch('Mumble:OnLocalTalk', Type)
        return
    end

    if self.PlayersTalkingState[Who] ~= nil then

        -- Player is still talking, reset timer
        if self.PlayersTalkingState[Who].channel == Type then
            self.PlayersTalkingState[Who].timer = 1

        -- Player is talking on a new channel, update it
        else
            self.PlayersTalkingState[Who].channel = Type
            Events:Dispatch('Mumble:OnTalk', Who, Type)
        end
    else
        --Player started talking
        self.PlayersTalkingState[Who] = { channel = Type, timer = 1 }
        Events:Dispatch('Mumble:OnTalk', Who, Type)
    end

    self:OnEvent(Event, Who, true)
end

function MumbleManager:OnStopTalking(Message)
    Type = Message:byte(2)
    Who = Message:sub(3):gsub('%W','') 
    Event = -1

    if Type == 0x0 then
        Event = self.LOCAL_TALKING
    elseif Type == 0x1 then
        Event = self.SQUAD_TALKING
    elseif Type == 0x2 then
        Event = self.SL_TALKING
    end

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
        print("MumbleManager::AddListener: The passed argument is not a valid function")
    end
end

function MumbleManager:OnEvent(Event, ...)
    self.Listeners[Event] = self.Listeners[Event] or {}
    for Key, Listener in pairs(self.Listeners[Event]) do
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
    local s_LocalPlayer = PlayerManager:GetLocalPlayer()
    if s_LocalPlayer == nil then
    	return
    end

    print('Sending server\'s UUID to mumble (' .. Uuid .. ')')
    uuidAndNick = Uuid .. '|' .. s_LocalPlayer.name:sub(0, 27) -- Doesn't have 0x0 but gets appended by z 
    Message = string.pack('<I4Bz', (uuidAndNick:len() + 2), self.GET_UUID_TYPE, uuidAndNick)
    self.MumbleSocket.Socket:Write(Message)

    local mumbleIpAndPort = self.MumbleIP
    local mumbleIpMessage = string.pack('<I4Bz', (mumbleIpAndPort:len() + 2), self.SET_MUMBLE_IP, mumbleIpAndPort)
    self.MumbleSocket.Socket:Write(mumbleIpMessage)
end

function MumbleManager:OnMumbleIpUpdated(MumbleIP)
    self.MumbleIP = MumbleIP
end


local Instance = MumbleManager()
return Instance
