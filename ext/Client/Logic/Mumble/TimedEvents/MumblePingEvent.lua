class "MumblePingEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function MumblePingEvent:__init()
    self.Timeout = 5 -- Trigger this event every 5 seconds
    self.RunOnce = false -- Keep running
    
    self.LastConnected = os.time(os.date("!*t"))
    self.Index = 0
    self.PING_EVENT_TYPE = 124
    self.FirstConnection = true
    MumbleManager:AddListener(self.PING_EVENT_TYPE, self, self.OnPing)
end

function MumblePingEvent:OnPing(Message)
    if Message == 'Pong' then
        self.LastConnected = os.time(os.date("!*t"))
    end
end


function MumblePingEvent:TriggerEvent()
    Message = FunctionUtilities:RightPadding(string.format('%c%s', self.PING_EVENT_TYPE, "Ping"), 64, '\0')
    NumOfBytes, Status = MumbleManager.MumbleSocket.Socket:Write(Message)
    if Status == 0 and self.FirstConnection then
        self.FirstConnection = false
        MumbleManager:OnUuidRequested()
    end

    if Status ~= 0 then
        self.FirstConnection = true
    end

    if os.time(os.date("!*t")) - self.LastConnected > 10 then
        self.LastConnected = os.time(os.date("!*t"))
        MumbleManager:OnEvent(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE)
    end
end

Instance = MumblePingEvent()
return Instance