class 'MumbleServerManager'

function MumbleServerManager:__init()
    self:SubscribeEvents()
end

function MumbleServerManager:SubscribeEvents()
    NetEvents:Subscribe('MumbleServerManager:RequestServerUuid', self, self.OnRequestServerUuid)
    Events:Subscribe('Engine:Message', self, self.OnEngineMessage)
end

function MumbleServerManager:OnRequestServerUuid(player)
    NetEvents:SendTo('MumbleServerManager:OnServerUuid', player, tostring(RCON:GetServerGUID()))
end

function MumbleServerManager:OnEngineMessage(p_Message)
    if p_Message.type == MessageType.ServerPlayerSquadLeaderStatusChangedMessage then 
        --self:OnContextChange()
    end
end


local mumbleServerManager = MumbleServerManager()
return mumbleServerManager