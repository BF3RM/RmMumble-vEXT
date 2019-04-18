class "MumbleServerCheckEvent" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function MumbleServerCheckEvent:__init()
    self.Timeout = 15 -- Trigger this event every 15 seconds
    self.RunOnce = false -- Keep running
end

function MumbleServerCheckEvent:TriggerEvent()
--   MumbleManager:OnUuidRequested()
end

Instance = MumbleServerCheckEvent()
return Instance