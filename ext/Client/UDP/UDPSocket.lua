class 'UDPSocket'

function UDPSocket:__init()
	print("Initializing UDPSocket")

    self.socket = Net:Socket(NetSocketFamily.INET, NetSocketType.Datagram)
    self.playerPositionUpdateDelta = 0.0
    self.socketOpen = false

    self:SetupSocket()
end 

function UDPSocket:SetupSocket()
    if self.socket:Connect('127.0.0.1', 55778) == 0 then -- this will always happen to be true
        print('UDPSocket connected')
        self.socketOpen = true
    else
        print('Couldn\'t connect UDPSocket, retrying in 5 seconds... if it was implemented')
        self.socketOpen = false
    end
end

function UDPSocket:Tick(delta)
    self.playerPositionUpdateDelta = self.playerPositionUpdateDelta + delta

    if self.playerPositionUpdateDelta < 0.1 then
        return
    else
        self.playerPositionUpdateDelta = 0.0
    end

    if self.socketOpen then
        local transform = ClientUtils:GetCameraTransform()
        if transform ~= nil then
            position = transform.trans
            front = transform.forward
            up = transform.up
    
            message = string.pack('<fffffffff', -position.x, position.y, position.z, -front.x, front.y, front.z, -up.x, up.y, up.z)
            self.socket:Write(message)
        end
    end
end