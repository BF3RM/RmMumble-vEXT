class "MumblePingEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()

function MumblePingEvent:__init()
    self.Timeout = 5 -- Trigger this event every 5 seconds
    self.RunOnce = false -- Keep running
    
    self.LastConnected = 0 -- In seconds

    self.MUMBLE_PORT = 64304
    
    self.Socket = nil
    self.IsConnected = self:Connect() == 0
end

function MumblePingEvent:Connect()
    if self.Socket ~= nil then
        --self.Socket:Destroy()
        --self.Socket = nil
    else 
        self.Socket = Net:Socket(NetSocketFamily.INET, NetSocketType.Stream)
    end
    return self.Socket:Connect('127.0.0.1', self.MUMBLE_PORT)
end

function MumblePingEvent:TriggerEvent()
    if self.LastConnected > 9 then
        MumbleManager:OnEvent(MumbleManager.EVENT_MUMBLE_NOT_AVAILABLE)
        self.LastConnected = 0
    end

    self.LastConnected = self.LastConnected + self.Timeout

    if not self.IsConnected and self:Connect() ~= 0 then
        return
    else
        self.IsConnected = true
    end

    numberOfBytes, responseCode = self.Socket:Write('ping')

    if responseCode ~= 0 then -- Failed to send data (probably not connected)
        print('Mumble\'s ping request returned code ' .. tostring(responseCode) .. '. Trying to connect again...')
        status = self:Connect()
        if status > 0 then -- Failed to connect
            print('Connecting to the Mumble\'s ping service returned ' .. tostring(status))
            return
        end
    end

    response, numberOfBytes = self.Socket:Read(4)
    print('Mumble\'s pong response received (' .. response .. ')')
    if response == 'pong' then
        self.LastConnected = 0
    end
end

Instance = MumblePingEvent()
return Instance