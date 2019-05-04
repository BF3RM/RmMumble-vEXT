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
end

Instance = ThreeDMumbleSocketEvent()
return Instance