class "MumblePingEvent"

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function MumblePingEvent:__init()
    self.Timeout = 3 -- Trigger this event every second
    self.RunOnce = false -- Keep running
    
    self.PING_EVENT_TYPE = 124
    self.FirstConnection = true
    self.FirstPing = true
    MumbleManager:AddListener(self.PING_EVENT_TYPE, self, self.OnPing)
end

function MumblePingEvent:OnPing(Message, Size)
    if Message:gsub('%W','') == 'Pong' then
        self.LastConnected = os.time(os.date("!*t"))
        -- MumbleManager:OnEvent(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE)
    end
end

function MumblePingEvent:TriggerEvent()
    if self.FirstPing then
        self.LastConnected = os.time(os.date("!*t"))
        self.FirstPing = false
    end

    print("ping")

    local Message = "Ping" -- Doesn't have 0x0 but gets appended by z
    Message = string.pack('<I4Bz', (Message:len() + 2), self.PING_EVENT_TYPE, Message)
    local NumOfBytes, Status = MumbleManager.MainMumbleSocket.Socket:Write(Message)
    if Status == SocketConnectionStatus.Success and self.FirstConnection then
        self.FirstConnection = false
        MumbleManager:OnEvent(MumbleManager.EVENT_MUMBLE_AVAILABLE)
        --   MumbleManager:OnUuidRequested()
    end

    if Status ~= SocketConnectionStatus.Success then
        self.FirstConnection = true
    end

    if os.time(os.date("!*t")) - self.LastConnected > 10 then
        self.LastConnected = os.time(os.date("!*t"))
        MumbleManager:OnEvent(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE)
    end
end

return MumblePingEvent()