class 'MumbleServerManager'

function MumbleServerManager:__init()
    self:SubscribeEvents()
end

function MumbleServerManager:SubscribeEvents()
    NetEvents:Subscribe('MumbleManager:RequestServerName', self, self.OnRequestServerName)
end

function MumbleServerManager:OnRequestServerName(player)
    print ('player requested server name')
    local settings = ServerSettings(ResourceManager:GetSettings('ServerSettings'))
    print ('sending ') 
    print(settings.serverName)
    NetEvents:SendTo('MumbleManagerServer:RequestServerName', player, settings.serverName)
end

local mumbleServerManager = MumbleServerManager()
return mumbleServerManager