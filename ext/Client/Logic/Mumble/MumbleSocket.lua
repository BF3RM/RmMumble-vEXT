class "MumbleSocket"

function MumbleSocket:__init()
	print("Initializing MumbleSocket")
end

function MumbleSocket:Update(Delta)
    --print("Update spam")
end

local MumbleSocketManager = MumbleSocket()
return MumbleSocketManager
