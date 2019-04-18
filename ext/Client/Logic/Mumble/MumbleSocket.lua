class "MumbleSocket"

function MumbleSocket:__init(p_SocketName, p_NetSocketFamily, p_NetSocketType, p_Port)
    print("Initializing MumbleSocket")
    self.Socket = nil
    self.ConnectionStatus = -1
    -- self:Connect()
    self.NetSocketFamily = p_NetSocketFamily
    self.NetSocketType = p_NetSocketType
    self.SocketName = p_SocketName
    self.SocketPort = p_Port
end

function MumbleSocket:Connect()
    if self.Socket ~= nil then
        self.Socket:Destroy()
        self.Socket = nil
    end
    
    self.Socket = Net:Socket(self.NetSocketFamily, self.NetSocketType)
    self.ConnectionStatus = self.Socket:Connect(Constants.LocalHostIP, self.SocketPort)
    print("Connecting to socket " .. self.SocketName .. " at localhost:" .. tostring(self.SocketPort))
end

function MumbleSocket:Update(Delta)
    --print("Update spam")
end

return MumbleSocket
