class 'VoiceEvents'

local bit32 = require "__shared/Util/bit32"

local MAX_TALKING_RADIUS = 75
local MAX_TALKING_RADIUS_POW = MAX_TALKING_RADIUS*MAX_TALKING_RADIUS

function VoiceEvents:__init()
    self.playersTalkingState = {}
end

function VoiceEvents:HandleStartVoiceEvent(voiceType, who)
	local channels = self:DecodeVoiceChannels(voiceType)

    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        return
    end
	
    if localPlayer.name == who then
        Events:Dispatch('Mumble:OnLocalTalk', channels)
	else
		speakingPlayer = PlayerManager:GetPlayerByName(who)
	
		if speakingPlayer == nil then
			return
		end
		
		for _, channel in pairs(channels) do
			if channel == VoiceChannelType.Local then
				local localSoldier = localPlayer.soldier or localPlayer.corpse
				local speakingSoldier = speakingPlayer.soldier or speakingPlayer.corpse

				local localPlayerIsDeadDead = true
				local speakingPlayerIsDeadDead = true
				
				if localSoldier then
					localPlayerIsDeadDead = localSoldier.isDead
				end
				if speakingSoldier then
					speakingPlayerIsDeadDead = speakingSoldier.isDead
				end
				
				if not localPlayerIsDeadDead and not speakingPlayerIsDeadDead then
				
					-- Alive, we check the distance
					local dx = speakingSoldier.transform.trans.x - localSoldier.transform.trans.x
					local dz = speakingSoldier.transform.trans.z - localSoldier.transform.trans.z
					
					if dx*dx + dz*dz > MAX_TALKING_RADIUS_POW then
						return
					end
				elseif localPlayerIsDeadDead ~= speakingPlayerIsDeadDead then
					return
				end
			end
		end
		
		if self.playersTalkingState[who] ~= nil then
			if self.playersTalkingState[who].channel == channels then
			else
				self.playersTalkingState[who].channel = channels
				Events:Dispatch('Mumble:OnTalk', who, channels)
			end
		else
			self.playersTalkingState[who] = { channel = channels }
			Events:Dispatch('Mumble:OnTalk', who, channels)
		end
	end
end

function VoiceEvents:DecodeVoiceChannels(p_VoiceChannelsByte)
	local s_VoiceChannels = {}
	--Type is 0x0 stopped talking, 0x2 local, 0x4 squad, 0x8 SL

	if p_VoiceChannelsByte == 0x0 then
		table.insert(s_VoiceChannels, VoiceChannelType.NotTalking)
		goto continue
	end

	if bit32.btest(p_VoiceChannelsByte, 0x2) then
		table.insert(s_VoiceChannels, VoiceChannelType.Local)
	end

	if bit32.btest(p_VoiceChannelsByte, 0x4) then
		table.insert(s_VoiceChannels, VoiceChannelType.Squad)
	end

	if bit32.btest(p_VoiceChannelsByte, 0x8) then
		table.insert(s_VoiceChannels, VoiceChannelType.HQ)
	end

	::continue::

	return s_VoiceChannels
end

function VoiceEvents:Tick(delta)
end