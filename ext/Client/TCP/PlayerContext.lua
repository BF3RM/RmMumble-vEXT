class 'PlayerContext'

function PlayerContext:__init(socket)
    self.socket = socket

    Events:Subscribe('Player:SquadChange', self, self.SquadChange)
    Events:Subscribe('Player:TeamChange', self, self.TeamChange)
end


function PlayerContext:SquadChange(player, squadId)
    if player == nil then
        return
    end
    
    local localPlayer = PlayerManager:GetLocalPlayer()

    if localPlayer ~= nil and localPlayer.name == player.name then
        self:OnContextChange(player.squadId, player.teamId, player.isSquadLeader)
    end
end

function PlayerContext:TeamChange(player, teamId, squadId)
    if player == nil then
        return
    end
    
    local localPlayer = PlayerManager:GetLocalPlayer()

    if localPlayer ~= nil and localPlayer.name == player.name then
        self:OnContextChange(player.squadId, player.teamId, player.isSquadLeader)
    end
end

function PlayerContext:OnContextChange(squadId, teamId, isSquadLeader)
    squadId = math.floor(squadId + 0.1) -- idk what this shit is
    teamId = math.floor(teamId + 0.1)

    isSquadLeaderBool = 0
    if isSquadLeader then
        isSquadLeaderBool = 1
    end

    if squadId == nil or teamId == nil then
        return
    end

    context = tostring(teamId) .. '~~' .. tostring(squadId) .. '~~' .. tostring(isSquadLeaderBool) -- Doesn't have 0x0 but gets appended by z 
    print('Sending context to mumble ' .. context)
    message = string.pack('<I4Bz', (context:len() + 2), 120, context)
    self.socket:Write(message)
end

function PlayerContext:Tick(delta)
end