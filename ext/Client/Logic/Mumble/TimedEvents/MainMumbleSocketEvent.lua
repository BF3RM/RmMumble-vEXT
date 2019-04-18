-- Triggered every second to check for incoming messages
class "MainMumbleSocketEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()

function MainMumbleSocketEvent:__init()
    self.Timeout = 0.05 -- Trigger this event every 50ms
    self.RunOnce = false -- Keep running
    self.PACKET_SIZE = 64
    self.LastTrigger = 0
    self.LastConnect = 0
end

function MainMumbleSocketEvent:GetDataSize(Data)
    return string.unpack('<I4', Data)
end

function MainMumbleSocketEvent:TriggerEvent()
    self.LastTrigger = os.time(os.date("!*t"))

    if MumbleManager.MainMumbleSocket.ConnectionStatus ~= SocketConnectionStatus.Success and 
        MumbleManager.MainMumbleSocket.ConnectionStatus ~= SocketConnectionStatus.Unavailable and 
        self.LastTrigger - self.LastConnect > 5 then

        MumbleManager.MainMumbleSocket:Connect()
        if MumbleManager.MainMumbleSocket.ConnectionStatus == 0 then
            self.LastConnect = self.LastTrigger
            print('Connected to mumble!')
        end

        return
    end

    -- Right girls, the socket lib seems to be fuck'd up perhaps it works like this for now
    -- We try to read. If the status code (Res) is 0 then we expect to see some data. 
    -- Whenever Data length is 0 then something is wrong as the right status code would then be 10035 (no data available)

    Data, Res = MumbleManager.MainMumbleSocket.Socket:Read(4)
    if Res ~= SocketConnectionStatus.Unavailable and 
        Res ~= SocketConnectionStatus.Success then

        MumbleManager.MainMumbleSocket:Connect()

        if MumbleManager.MainMumbleSocket.ConnectionStatus == SocketConnectionStatus.Success then
            self.LastConnect = self.LastTrigger
            print('Connected to mumble!')
        end

        return
    end

    if Res == 0 and Data:len() == 0 then
        print('Connection aborted. Trying to connect again')

        MumbleManager.MainMumbleSocket:Connect()

        if MumbleManager.MainMumbleSocket.ConnectionStatus == SocketConnectionStatus.Success then
            self.LastConnect = self.LastTrigger
            print('Connected to mumble!')
        end

        return
    end

    if Data:len() == 4 then
        Data, Res = MumbleManager.MainMumbleSocket.Socket:Read(self:GetDataSize(Data))
        if Data:len() > 0 then
            EventType = string.byte(Data:sub(0, 1))
        end

        EventMessage = nil
        EventSize = Data:len() - 1
        if Data:len() > 1 then
            EventMessage = Data:sub(2)
        end

        MumbleManager:OnEvent(EventType, EventMessage, EventSize)
    end
end

return MainMumbleSocketEvent()