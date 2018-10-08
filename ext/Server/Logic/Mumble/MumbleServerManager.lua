class 'MumbleServerManager'

function MumbleServerManager:__init()
    self:SubscribeEvents()
end

function MumbleServerManager:SubscribeEvents()
    NetEvents:Subscribe('MumbleServerManager:RequestServerUuid', self, self.OnRequestServerUuid)
end

function MumbleServerManager:OnRequestServerUuid(player)
    NetEvents:SendTo('MumbleServerManager:OnServerUuid', player, tostring(RCON:GetServerGUID()))
end

local mumbleServerManager = MumbleServerManager()
return mumbleServerManager