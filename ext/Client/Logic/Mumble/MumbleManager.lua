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
    self.STOP_TALKING = 121
    self.START_TALKING = 122
    self.GET_UUID_TYPE = 123
    self.Listeners = {}
    self.MumbleSocket = require 'Logic/Mumble/MumbleSocket'

    self:AddListener(self.GET_UUID_TYPE, self, self.OnUuidRequested)
    self:AddListener(self.START_TALKING, self, self.OnStartTalking)
    self:AddListener(self.STOP_TALKING, self, self.OnStopTalking)
    NetEvents:Subscribe('MumbleServerManager:OnServerUuid', self, self.OnUuidReceived)
end

function MumbleManager:OnStartTalking(Who)
    print(Who .. " is talking")
end

function MumbleManager:OnStopTalking(Who)
    print(Who .. " is not talking anymore")
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
    if math.floor((DeltaTime / 2)) * 2 == math.floor(DeltaTime) then
        --self:OnEvent(self.EVENT_TALKING)
    end
end

function MumbleManager:OnUuidRequested()
    NetEvents:SendLocal('MumbleServerManager:RequestServerUuid')
end

function MumbleManager:OnUuidReceived(Uuid)
    if PlayerManager ~= nil and PlayerManager:GetLocalPlayer() ~= nil and PlayerManager:GetLocalPlayer().name ~= nil then
        Message = FunctionUtilities:RightPadding(string.format('%c%s|%s', self.GET_UUID_TYPE, Uuid, PlayerManager:GetLocalPlayer().name:sub(0, 27)), 64, '\0')
        self.MumbleSocket.Socket:Write(Message)
    end
end

local Instance = MumbleManager()
return Instance
