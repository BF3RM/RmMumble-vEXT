class "MumbleUpdatePlayersInfo" 

local MumbleManager = (require "Logic/Mumble/MumbleManager").GetInstance()
local FunctionUtilities = require 'Logic/Utilities/FunctionUtilities'

function MumbleUpdatePlayersInfo:__init()
    self.Timeout = 15 -- Trigger this event every 5 seconds
    self.RunOnce = false -- Keep running

    self.UPDATE_PLAYERS_INFO_EVENT_TYPE = 117
    Events:Subscribe('Player:SquadChange', self, self.OnSquadChange)
end

function MumbleUpdatePlayersInfo:OnSquadChange(p_Player, p_SquadId)
    self:TriggerEvent()
end

function MumbleUpdatePlayersInfo:TriggerEvent()
    Players = PlayerManager:GetPlayers()
    
    -- Total message len (I)- Message type (B) - Number of players (I)
      -- Player Name Len (I) -- PlayerName (z) -- Player Team (I) -- Player Fact (I) -- Is SquadLead (B)
    Payload = ''
    for Key, Player in pairs(Players) do
        IsSquadLeader = 0
        SquadId = -1
        TeamId = -1

        if Player.isSquadLeader == true then IsSquadLeader = 1 end
        if Player.squadId ~= nil then SquadId = Player.squadId end
        if Player.teamId ~= nil then TeamId = Player.teamId end

        Payload = Payload .. string.pack('<I4zi4i4B', Player.name:len(), Player.name, SquadId, TeamId, IsSquadLeader)
    end
    Message = string.pack('<I4BI4', Payload:len() + 5, self.UPDATE_PLAYERS_INFO_EVENT_TYPE, #Players) .. Payload
    NumOfBytes, Status = MumbleManager.MumbleSocket.Socket:Write(Message)
end

Instance = MumbleUpdatePlayersInfo()
return Instance