-- Triggered every second to check for incoming messages
class "MumbleSocketReceiverEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()

function MumbleSocketReceiverEvent:__init()
    self.Timeout = 0.05 -- Trigger this event every second
    self.RunOnce = false -- Keep running
    self.PACKET_SIZE = 64
    self.LastTrigger = 0
    self.LastConnect = 0
end

function MumbleSocketReceiverEvent:GetDataSize(Data)
    return string.unpack('<I4', Data)
end

function MumbleSocketReceiverEvent:TriggerEvent()
    self.LastTrigger = os.time(os.date("!*t"))

    if MumbleManager.MumbleSocket.IsConnected ~= 0 and MumbleManager.MumbleSocket.IsConnected ~= 10035 and self.LastTrigger - self.LastConnect > 5 then
        MumbleManager.MumbleSocket.IsConnected = MumbleManager.MumbleSocket:Connect()
        if MumbleManager.MumbleSocket.IsConnected == 0 then
            self.LastConnect = LastTrigger
            print('Connected to mumble!')
        end
        return
    end

    -- Right girls, the socket lib seems to be fuck'd up perhaps it works like this for now
    -- We try to read. If the status code (Res) is 0 then we expect to see some data. 
    -- Whenever Data length is 0 then something is wrong as the right status code would then be 10035 (no data available)

    Data, Res = MumbleManager.MumbleSocket.Socket:Read(4)
    if Res ~= 10035 and Res ~= 0 then
        MumbleManager.MumbleSocket.IsConnected = MumbleManager.MumbleSocket:Connect()
        if MumbleManager.MumbleSocket.IsConnected == 0 then
            self.LastConnect = LastTrigger
            print('Connected to mumble!')
        end
        return
    end

    if Res == 0 and Data:len() == 0 then
        print('Connection aborted. Trying to connect again')
        MumbleManager.MumbleSocket.IsConnected = MumbleManager.MumbleSocket:Connect()
        if MumbleManager.MumbleSocket.IsConnected == 0 then
            self.LastConnect = LastTrigger
            print('Connected to mumble!')
        end
        return
    end

    if Data:len() == 4 then
        Data, Res = MumbleManager.MumbleSocket.Socket:Read(self:GetDataSize(Data))
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

Instance = MumbleSocketReceiverEvent()
return Instance