class 'MumbleServerManager'

local mumbleIP = '0.0.0.0|0000'

function MumbleServerManager:__init()
	self:RegisterVars()
    self:SubscribeEvents()
	self:RegisterRCONCommand()
end
function MumbleServerManager:RegisterVars()
end

function MumbleServerManager:SubscribeEvents()
    NetEvents:Subscribe('MumbleServerManager:RequestServerUuid', self, self.OnRequestServerUuid)
    Events:Subscribe('Engine:Message', self, self.OnEngineMessage)
    Events:Subscribe('Player:Authenticated', self, self.OnPlayerAuthenticated)
	Events:Subscribe('Level:LoadResources', self, self.OnLoadResources)

end

function MumbleServerManager:OnRequestServerUuid(player)
    NetEvents:SendToLocal('MumbleServerManager:OnServerUuid', player, tostring(RCON:GetServerGUID()))
    NetEvents:SendToLocal('MumbleServerManager:OnMumbleIpUpdated', player, mumbleIP)
end

function MumbleServerManager:OnEngineMessage(p_Message)
    if p_Message.type == MessageType.ServerPlayerSquadLeaderStatusChangedMessage then 
        --self:OnContextChange()
    end
end

function MumbleServerManager:OnPlayerAuthenticated(player)
	NetEvents:SendToLocal('MumbleServerManager:OnMumbleIpUpdated', player, mumbleIP)
end

function MumbleServerManager:OnLoadResources()
	NetEvents:BroadcastLocal('MumbleServerManager:OnMumbleIpUpdated', mumbleIP)
end

function MumbleServerManager:OnMumbleIpUpdated(command, args, loggedIn)
	print('Set mumble IP')
	mumbleIP = tostring(args[1])
	NetEvents:BroadcastLocal('MumbleServerManager:OnMumbleIpUpdated', mumbleIP)
	return { 'OK', 'Mumble IP set' }
end

function MumbleServerManager:RegisterRCONCommand()

	commandHandle = RCON:RegisterCommand('RM.MumbleIP', RemoteCommandFlag.RequiresLogin, '0.0.0.0|0000', self.OnMumbleIpUpdated)

	if commandHandle == 0 then
		-- This means that a command with the same name already exists
		print('Failed to register RCON command')
	else
		print('Registered new RCON command')
		print(commandHandle)
	end
end

local mumbleServerManager = MumbleServerManager()
return mumbleServerManager