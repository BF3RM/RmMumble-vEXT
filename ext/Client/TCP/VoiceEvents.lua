class 'VoiceEvents'

function VoiceEvents:__init()
    self.playersTalkingState = {}
end

function VoiceEvents:HandleStartVoiceEvent(voiceType, who)
    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        return
    end

    if localPlayer.name == who then
        Events:Dispatch('Mumble:OnLocalTalk', voiceType)
    elseif self.playersTalkingState[who] ~= nil then
        if self.playersTalkingState[who].channel == voiceType then
            self.playersTalkingState[who].timer = 1
        else
            self.playersTalkingState[who].channel = voiceType
            Events:Dispatch('Mumble:OnTalk', who, voiceType)
        end
    else
        self.playersTalkingState[who] = { channel = voiceType, timer = 1 }
        Events:Dispatch('Mumble:OnTalk', who, voiceType)
    end
end

function VoiceEvents:Tick(delta)
    for playerName, state in pairs(self.playersTalkingState) do
        state.timer = state.timer - delta
        if state.timer < 0 then
            Events:Dispatch('Mumble:OnTalk', playerName, 0x0)
            self.playersTalkingState[playerName] = nil
        end
    end
end