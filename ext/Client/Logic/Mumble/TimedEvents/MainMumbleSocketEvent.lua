-- Triggered every second to check for incoming messages
class "MainMumbleSocketEvent"

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()

function MainMumbleSocketEvent:__init()
    self.Timeout = 0.05 -- Trigger this event every 50ms
    self.RunOnce = false -- Keep running
    self.PACKET_SIZE = 64
    self.LastTrigger = 0
    self.LastConnect = 0
    self.RetryTimeout = 5
end

function MainMumbleSocketEvent:GetDataSize(Data)
    return string.unpack('<I4', Data)
end

function MainMumbleSocketEvent:TriggerEvent()
    if _G.IsMumbleAvailable == false then
        return
    end

    self.LastTrigger = os.time(os.date("!*t"))

    if MumbleManager.MainMumbleSocket.ConnectionStatus ~= SocketConnectionStatus.Success and
        MumbleManager.MainMumbleSocket.ConnectionStatus ~= SocketConnectionStatus.Unavailable and
        self.LastTrigger - self.LastConnect > self.RetryTimeout then

        print("1")
        MumbleManager.MainMumbleSocket:Connect()
        if MumbleManager.MainMumbleSocket.ConnectionStatus == SocketConnectionStatus.Success then
            self.LastConnect = self.LastTrigger
            print('Connected to mumble!')
        end

        return
    end

    -- Right girls, the socket lib seems to be fuck'd up perhaps it works like this for now
    -- We try to read. If the status code (Res) is 0 then we expect to see some data. 
    -- Whenever Data length is 0 then something is wrong as the right status code would then be 10035 (no data available)

    local Data, Res = MumbleManager.MainMumbleSocket.Socket:Read(4)

    if Res ~= SocketConnectionStatus.Unavailable and
        Res ~= SocketConnectionStatus.Success and
        self.LastTrigger - self.LastConnect > self.RetryTimeout then

        print("2")
        MumbleManager.MainMumbleSocket:Connect()

        if MumbleManager.MainMumbleSocket.ConnectionStatus == SocketConnectionStatus.Success then
            self.LastConnect = self.LastTrigger
            print('Connected to mumble!')
        end

        return
    end

    if Res == 0 and Data:len() == 0 then
        print('Connection aborted. Trying to connect again')

        print("3")
        MumbleManager.MainMumbleSocket:Connect()

        if MumbleManager.MainMumbleSocket.ConnectionStatus == SocketConnectionStatus.Success then
            self.LastConnect = self.LastTrigger
            print('Connected to mumble!')
        end

        return
    end

    if Data:len() == 4 then
        local Data2, Res2 = MumbleManager.MainMumbleSocket.Socket:Read(self:GetDataSize(Data))
        local EventType = nil
        if Data2:len() > 0 then
            EventType = string.byte(Data2:sub(0, 1))
        end

        local EventMessage = nil
        local EventSize = Data2:len() - 1
        if Data2:len() > 1 then
            EventMessage = Data2:sub(2)
        end

        MumbleManager:OnEvent(EventType, EventMessage, EventSize)
    end
end

return MainMumbleSocketEvent()