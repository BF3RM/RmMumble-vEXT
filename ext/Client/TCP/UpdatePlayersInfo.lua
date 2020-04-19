class 'UpdatePlayersInfo'

function UpdatePlayersInfo:__init(socket)
    self.socket = socket
    self.updatePlayersInfoDelta = 0.0
end

function UpdatePlayersInfo:Tick(delta)
    self.updatePlayersInfoDelta = self.updatePlayersInfoDelta + delta

    if self.updatePlayersInfoDelta >= 5.0 then
        local players = PlayerManager:GetPlayers()
    
        -- Total message len (I)- Message type (B) - Number of players (I)
          -- Player Name Len (I) -- PlayerName (z) -- Player Team (I) -- Player Fact (I) -- Is SquadLead (B)
        local payload = ''
        for _, player in pairs(players) do
            if player == nil or player.name == nil then
                goto continue
            end
            local isSquadLeader = 0
            local squadId = -1
            local teamId = -1
    
            if player.isSquadLeader == true then isSquadLeader = 1 end
            if player.squadId ~= nil then squadId = player.squadId end
            if player.teamId ~= nil then teamId = player.teamId end
    
            payload = payload .. string.pack('<I4zi4i4B', player.name:len(), player.name, squadId, teamId, isSquadLeader)

            ::continue::
        end
        local message = string.pack('<I4BI4', payload:len() + 5, 117, #players) .. payload
        self.socket:Write(message)
        self.updatePlayersInfoDelta = 0.0
    end
end