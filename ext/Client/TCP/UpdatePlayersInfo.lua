class 'UpdatePlayersInfo'

function UpdatePlayersInfo:__init(socket)
    self.socket = socket
    self.updatePlayersInfoDelta = 0.0
end

function UpdatePlayersInfo:Tick(delta)
    self.updatePlayersInfoDelta = self.updatePlayersInfoDelta + delta

    if self.updatePlayersInfoDelta >= 5.0 then
        players = PlayerManager:GetPlayers()
    
        -- Total message len (I)- Message type (B) - Number of players (I)
          -- Player Name Len (I) -- PlayerName (z) -- Player Team (I) -- Player Fact (I) -- Is SquadLead (B)
        payload = ''
        for Key, player in pairs(players) do
            isSquadLeader = 0
            squadId = -1
            teamId = -1
    
            if player.isSquadLeader == true then isSquadLeader = 1 end
            if player.squadId ~= nil then squadId = player.squadId end
            if player.teamId ~= nil then teamId = player.teamId end
    
            payload = payload .. string.pack('<I4zi4i4B', player.name:len(), player.name, squadId, teamId, isSquadLeader)
        end
        message = string.pack('<I4BI4', payload:len() + 5, 117, #players) .. payload
        self.socket:Write(message)
        self.updatePlayersInfoDelta = 0.0
    end
end