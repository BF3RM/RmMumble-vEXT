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
    self.Listeners = {}
end

function MumbleManager:GetInstance()
    local Instance = {}
    if MetaTable.__index == nil then
        MetaTable.__index = MumbleManager()
        MetaTable.__index:InternalInit()
    end 
    setmetatable(Instance, MetaTable)
    print(Instance)
    return Instance
end

function MumbleManager:RegisterEvents()
    Events:Subscribe('MumbleManagerServer:RequestServerName', self, self.OnServerNameReceived)
    Events:Subscribe('Player:Connected', self, self.OnPlayerConnected)
end

function MumbleManager:OnServerNameReceived(serverName)
    print('Received ServerName: ' + serverName)
end

function MumbleManager:OnPlayerConnected()
    NetEvents:SendLocal('MumbleManager:RequestServerName')
end

function MumbleManager:AddListener(Event, Listener)
    if FunctionUtilities:IsFunction(Listener) then
        self.Listeners[Event] = self.Listeners[Event] or {}
        table.insert(self.Listeners[Event], Listener)
    else
        print("MumbleManager::AddListener: The passed argument is not a valid function")
    end
end

function MumbleManager:OnEvent(Event, ...)
    for Key, Callback in pairs(self.Listeners[Event]) do
        Callback(...)
    end
end

function MumbleManager:Update(DeltaTime)
    if math.floor((DeltaTime / 2)) * 2 == math.floor(DeltaTime) then
        --self:OnEvent(self.EVENT_TALKING)
    end
end

local Instance = MumbleManager()
return Instance
