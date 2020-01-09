class 'MumbleImplementationServer'

local MumbleServerManager = require 'Logic/Mumble/MumbleServerManager'

function MumbleImplementationServer:__init()
	print("Initializing MumbleImplementationServer")
	self:RegisterVars()
	self:RegisterEvents()
end

function MumbleImplementationServer:RegisterVars()
end


function MumbleImplementationServer:RegisterEvents()
end

g_MumbleImplementationServer = MumbleImplementationServer()

