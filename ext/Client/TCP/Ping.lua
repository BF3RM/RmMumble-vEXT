class 'Ping'

function Ping:__init(socket)
    self.socket = socket
    self.pingDelta = 0.0
end

function Ping:Tick(delta)
    self.pingDelta = self.pingDelta + delta

    if self.pingDelta >= 1.0 then
        message = "Ping" -- Doesn't have 0x0 but gets appended by z 
        message = string.pack('<I4Bz', (message:len() + 2), 124, message)
        self.socket:Write(message)
        self.pingDelta = 0
    end
end