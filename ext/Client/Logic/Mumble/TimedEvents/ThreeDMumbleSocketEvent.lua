class "ThreeDMumbleSocketEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function ThreeDMumbleSocketEvent:__init()
    self.Timeout = 0.2 -- Trigger this event every 200ms
    self.RunOnce = false -- Keep running
    
    self.FirstConnection = true
    -- MumbleManager:AddListener(self.PING_EVENT_TYPE, self, self.OnPing)
end

function ThreeDMumbleSocketEvent:TriggerEvent()
    if MumbleManager.ThreeDMumbleSocket.ConnectionStatus ~= SocketConnectionStatus.Success then
        MumbleManager.ThreeDMumbleSocket:Connect()
    end

    local Player = PlayerManager:GetLocalPlayer()
    if Player ~= nil and Player.soldier ~= nil then
        transform = Player.soldier.worldTransform
        position = transform.trans
        front = transform.forward
        up = transform.up

        -- this happens 5 times per seconds, so keep it tiny
        Message = string.pack('<fffffffff', -position.x, position.y, position.z, -front.x, front.y, front.z, -up.x, up.y, up.z)
        MumbleManager.ThreeDMumbleSocket.Socket:Write(Message)
    end
    --[[
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

    ]]
end

Instance = ThreeDMumbleSocketEvent()
return Instance