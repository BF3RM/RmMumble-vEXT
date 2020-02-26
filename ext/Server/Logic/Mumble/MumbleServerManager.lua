class 'MumbleServerManager'


function MumbleServerManager:__init()
	self.mumbleServerIp = '127.0.0.1|64738'

    self:SubscribeEvents()
	self:RegisterRCONCommand()
end

function MumbleServerManager:SubscribeEvents()
	NetEvents:Subscribe('MumbleServerManager:GetMumbleServerIp', self, self.OnGetMumbleServerIp)
end

function MumbleServerManager:OnGetMumbleServerIp(player)
    NetEvents:SendToLocal('MumbleServerManager:MumbleServerAddressChanged', player, self.mumbleServerIp)
end

function MumbleServerManager:OnMumbleIpUpdated(default, command, args)
	self.mumbleServerIp = tostring(args[1])
	NetEvents:BroadcastLocal('MumbleServerManager:MumbleServerAddressChanged', self.mumbleServerIp)
	return { 'OK', 'Mumble IP set' }
end

function MumbleServerManager:RegisterRCONCommand()

	commandHandle = RCON:RegisterCommand('RM.MumbleServerIp', RemoteCommandFlag.RequiresLogin, '127.0.0.1|64738', function(default, command, args)
		return self:OnMumbleIpUpdated(default, command, args)
	end)

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