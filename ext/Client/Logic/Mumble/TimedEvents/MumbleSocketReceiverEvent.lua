-- Triggered every second to check for incoming messages
class "MumbleSocketReceiverEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()

function MumbleSocketReceiverEvent:__init()
    self.Timeout = 0.05 -- Trigger this event every second
    self.RunOnce = false -- Keep running
    self.PACKET_SIZE = 64
end

function MumbleSocketReceiverEvent:TriggerEvent()
    if MumbleManager.MumbleSocket.IsConnected ~= 0 and MumbleManager.MumbleSocket.IsConnected ~= 10035 then
        MumbleManager.MumbleSocket:Connect()
        return
    end

    -- Right girls, the socket lib seems to be fuck'd up perhaps it works like this for now
    -- We try to read. If the status code (Res) is 0 then we expect to see some data. 
    -- However is Data length is 0 then something is wrong as the right status code would then be 10035 (no data available)

    Data, Res = MumbleManager.MumbleSocket.Socket:Read(64)
    if Res ~= 10035 and Res ~= 0 then
        MumbleManager.MumbleSocket:Connect()
        return
    end

    if Res == 0 and Data:len() == 0 then
        print('Connection aborted. Trying to connect again')
        MumbleManager.MumbleSocket:Connect()
        return
    end

    if Data:len() > 0 then
        EventType = string.byte(string.sub(Data, 1, 1))
        EventMessage = string.sub(Data, 2)
        MumbleManager:OnEvent(EventType, EventMessage:gsub('%W',''))
    end
end

Instance = MumbleSocketReceiverEvent()
return Instance