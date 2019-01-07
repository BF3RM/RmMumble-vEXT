class "MumblePingEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function MumblePingEvent:__init()
    self.Timeout = 1 -- Trigger this event every 5 seconds
    self.RunOnce = false -- Keep running
    
    self.Index = 0
    self.PING_EVENT_TYPE = 124
    self.FirstConnection = true
    self.FirstPing = true
    MumbleManager:AddListener(self.PING_EVENT_TYPE, self, self.OnPing)
end

function MumblePingEvent:OnPing(Message, Size)
    if Message:gsub('%W','') == 'Pong' then
        self.LastConnected = os.time(os.date("!*t"))
    end
end

function MumblePingEvent:TriggerEvent()
    if self.FirstPing then
        self.LastConnected = os.time(os.date("!*t"))
        self.FirstPing = false
    end

    Message = "Ping" -- Doesn't have 0x0 but gets appended by z 
    Message = string.pack('<I4Bz', (Message:len() + 2), self.PING_EVENT_TYPE, Message)
    NumOfBytes, Status = MumbleManager.MumbleSocket.Socket:Write(Message)
    if Status == 0 and self.FirstConnection then
        self.FirstConnection = false
     --   MumbleManager:OnUuidRequested()
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