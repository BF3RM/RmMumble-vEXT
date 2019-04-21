class "Mumble3DLocationEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function Mumble3DLocationEvent:__init()
    self.Timeout = 0.2 -- Trigger this event every 5 seconds
    self.RunOnce = false -- Keep running
    
    self.Index = 0
    self.PING_EVENT_TYPE = 124
    self.FirstConnection = true
    self.IsConnected = false
    MumbleManager:AddListener(self.PING_EVENT_TYPE, self, self.OnPing)
end

function Mumble3DLocationEvent:Connect()
    if self.Socket ~= nil then
        self.Socket:Destroy()
        self.Socket = nil
    end
    
    self.Socket = Net:Socket(NetSocketFamily.INET, NetSocketType.Datagram)
    self.IsConnected = self.Socket:Connect('127.0.0.1', 55778)
    
    return self.IsConnected
end

function Mumble3DLocationEvent:TriggerEvent()
    if self.IsConnected ~= 0 then
        self:Connect()
        return
    end

    local Player = PlayerManager:GetLocalPlayer()
    if Player ~= nil and Player.soldier ~= nil then
        transform = Player.soldier.worldTransform
        position = transform.trans
        front = transform.forward
        up = transform.up

        Message = string.pack('<fffffffff', -position.x, position.y, position.z, -front.x, front.y, front.z, -up.x, up.y, up.z)
        self.Socket:Write(Message)
    end
end

Instance = Mumble3DLocationEvent()
return Instance