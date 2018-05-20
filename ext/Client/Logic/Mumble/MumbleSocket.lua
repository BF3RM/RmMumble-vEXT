class "MumbleSocket"

function MumbleSocket:__init()
    print("Initializing MumbleSocket")
    self.Socket = nil
    Connected = self:Connect()
    self.MUMBLE_PORT = 64304
    self.IsConnected = false
end

function MumbleSocket:Connect()
    if self.Socket ~= nil then
        self.Socket:Destroy()
        self.Socket = nil
    end
    
    self.Socket = Net:Socket(NetSocketFamily.INET, NetSocketType.Stream)
    self.IsConnected = self.Socket:Connect('127.0.0.1', self.MUMBLE_PORT)
    
    return self.IsConnected
end

function MumbleSocket:Update(Delta)
    --print("Update spam")
end

local MumbleSocketManager = MumbleSocket()
return MumbleSocketManager
