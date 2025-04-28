
local module, L = BigWigs:ModuleDeclaration("Echo of Medivh", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"gaze", "pyro", "frostnova", "arcaneblast", "flamestrike", "frostbolt", "corruption", "proximity", "usepoticon", "usepotsound", "bosskill"}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

module.defaultDB = {
    gaze = false,
    pyro = false,
    frostnova = false,
    arcaneblast = false,
    flamestrike = false,
    frostbolt = false,
    corruption = true,
    proximity = true, 
    usepoticon = true,
    usepotsound = true,
}
L:RegisterTranslations("enUS", function() return {
	cmd = "Medivh",
    
    gaze_cmd = "Gaze",
    gaze_name = "Gaze Alert",
    gaze_desc = "Warn for Gaze",
    
    pyro_cmd = "Pyroblast",
    pyro_name = "Pyroblast Alert",
    pyro_desc = "Warn for Pyroblast",
    
    frostnova_cmd = "FrostNova",
    frostnova_name = "FrostNova Alert",
    frostnova_desc = "Warn for FrostNova",
    
    arcaneblast_cmd = "ArcaneBlast",
    arcaneblast_name = "ArcaneBlast Alert",
    arcaneblast_desc = "Warn for ArcaneBlast",
    
    flamestrike_cmd = "Flamestrike",
    flamestrike_name = "Flamestrike Alert",
    flamestrike_desc = "Warn for Flamestrike",
    
    frostbolt_cmd = "Frostbolt",
    frostbolt_name = "Frostbolt Alert",
    frostbolt_desc = "Warn for Frostbolt",
    
    corruption_cmd = "Corruption",
    corruption_name = "Corruption Alert",
    corruption_desc = "Warn for Corruption",
    
    proximity_cmd = "Proximity",
    proximity_name = "Proximity Alert",
    proximity_desc = "Warning frame for Proximity",
    
    usepoticon_cmd = "UsePotionIcon",
    usepoticon_name = "Use shadow protection potion icon Alert",
    usepoticon_desc = "Warn for use shadow protection potion icon every 2 min",
	
    usepotsound_cmd = "UsePotionSound",
    usepotsound_name = "Use shadow protection potion sound Alert",
    usepotsound_desc = "Warn for use shadow protection potion sound every 2 min",
    
    pyro_bar = "Pyroblast, KICK!",
    frostnova_bar = "Frost Nova, KICK!",
    arcaneblast_bar = "Arcane Blast, KICK!",
    flamestrike_bar = "Flamestrike, KICK!",
    frostbolt_bar = "Frostbolt, KICK!",
    
    trigger_corruptionYou = "You are afflicted by Corruption of Medivh", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_corruptionOther = "(.+) is afflicted by Corruption of Medivh",  --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	trigger_corruptionFade = "Corruption of Medivh fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
	bar_corruption = " is Corrupted!",
	msg_corruptionYou = "You are Corrupted! Move away from your friends!",
    soundcorrupYou = "Interface\\Addons\\BigWigs\\Sounds\\corruption.mp3",
    
    msg_usepot = "Use GSPP",
	soundgspp = "Interface\\Addons\\BigWigs\\Sounds\\shadowpot.wav",
    
	trigger_engage = "My patience has come to an end. You will not leave this tower alive.",--CHAT_MSG_MONSTER_YELL
} end )

local medivh_guid = "0xF13000F206276A35" --nice name. it is instance dependent. will be synced in OnEngage()
local gaze_id = 51111
local pyro_id = 51112
local frostnova_id = 51114 
local arcaneblast_id = 51116 
local flamestrike_id = 51113
local frostbolt_id = 51118 
local arcanefocus_id = 51115 
local corruption_id = 52674
local doom_id = 40004 -- also 40005 & 40006

local usepotcounter = 0

local timer = {
    pyro = 1.6,--confirmed
    frostnova = 1.6, --confirmed
    arcaneblast = 1.6, --confirmed
    flamestrike = 1.6, --confirmed
    frostbolt = 1.6, --confirmed
    corruption = 6,
    usepot = 120,
    usepotsound_pre = 2,
    usepoticon = 10,
}
local icon = {
    pyro = "spell_fire_fireball02",
    frostnova = "Spell_Frost_FrostNova",
    arcaneblast = "Spell_Arcane_StarFire",
    flamestrike = "Spell_Fire_SelfDestruct",
    frostbolt = "Spell_Frost_FrostBolt02",
    corruption = "spell_shadow_abominationexplosion", --INV_Misc_Bomb_05
    circle = "INV_Jewelry_Ring_03",
    usepot = "spell_shadow_abominationexplosion", 
}
local color = {
    pyro = "Red",
    frostnova = "Blue",
    arcaneblast = "Purple",
    flamestrike = "Red",
    frostbolt = "Blue",
	corruption = "Cyan",
    circle = "Purple",
    usepot = "Black",
}
local syncName = {
    bossguid = "BossGuid"..module.revision,
	pyro = "Pyroblast"..module.revision,
	frostnova = "FrostNova"..module.revision,
	arcaneblast = "ArcaneBlast"..module.revision,
	flamestrike = "Flamestrike"..module.revision,
	frostbolt = "Frostbolt"..module.revision,
    corruption = "Corruption"..module.revision,
    corruptionFade = "CorruptionFade"..module.revision,
}

module.proximityCheck = function(unit)
	return CheckInteractDistance(unit, 2)
end

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event") --trigger_engage
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") 
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") 
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") 
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") 
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") 
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") 
    
    if SUPERWOW_VERSION then -- check if SuperWoW is used. if not, pray that someone has it to sync with you :)
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
	self:ThrottleSync(20, syncName.bossguid)
	self:ThrottleSync(5, syncName.pyro)
	self:ThrottleSync(5, syncName.frostnova)
	self:ThrottleSync(5, syncName.arcaneblast)
	self:ThrottleSync(5, syncName.flamestrike)
	self:ThrottleSync(5, syncName.frostbolt)
	self:ThrottleSync(3, syncName.corruption)
	self:ThrottleSync(3, syncName.corruptionFade)
    
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
    if SUPERWOW_VERSION and UnitClass("Player") == "Hunter" then -- hunter chads helping healer chads
        TargetByName("Echo of Medivh", true) --enUS hardcoded... should use L["bossname"]
        local _, medivh_guid = UnitExists("target")
        self:Sync(syncName.bossguid.." "..medivh_guid)
    end
    
	if self.db.profile.proximity then
		self.Proximity(module)
	end
    if self.db.profile.usepoticon then
        self:ScheduleRepeatingEvent("bwUsepoticon", function() self:UsePotIcon() end, timer.usepot)
    end
    if self.db.profile.usepotsound then
        self:ScheduleEvent("FirstEvent", function()
            self:UsePotSound()
            self:ScheduleRepeatingEvent("RepeatingEvent", function() self:UsePotSound() end, timer.usepot)
        end, timer.usepot)
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
	if (IsRaidLeader() or IsRaidOfficer()) then
		for i=1,GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
		end
	end
	if self.db.profile.proximity then
		self:RemoveProximity()
	end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == medivh_guid then
        if eventType == "START" then 
        end
        if spellId == pyro_id and eventType == "START" then 
            self:Sync(syncName.pyro)
        elseif spellId == frostnova_id and eventType == "START" then 
            self:Sync(syncName.frostnova)
        elseif spellId == arcaneblast_id and eventType == "START" then 
            self:Sync(syncName.arcaneblast)
        elseif spellId == flamestrike_id and eventType == "START" then 
            self:Sync(syncName.flamestrike)
        elseif spellId == frostbolt_id and eventType == "START" then 
            self:Sync(syncName.frostbolt)
        end
    end
end

function module:Event(msg)
    if string.find(msg, L["trigger_corruptionYou"]) then
		self:Sync(syncName.corruption .. " " .. UnitName("Player"))
	elseif string.find(msg, L["trigger_corruptionOther"]) then
		local _,_, corrPlayer,_ = string.find(msg, L["trigger_corruptionOther"])
		self:Sync(syncName.corruption .. " " .. corrPlayer)
	elseif string.find(msg, L["trigger_corruptionFade"]) then
		local _,_, corrFadePlayer,_ = string.find(msg, L["trigger_corruptionFade"])
		if corrFadePlayer == "you" then corrFadePlayer = UnitName("Player") end
		self:Sync(syncName.corruptionFade .. " " .. corrFadePlayer)
		
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bossguid then
        medivh_guid = rest
    elseif sync == syncName.pyro and self.db.profile.pyro then
        self:Pyro()
    elseif sync == syncName.frostnova and self.db.profile.frostnova then
        self:FrostNova()
    elseif sync == syncName.arcaneblast and self.db.profile.arcaneblast then
        self:ArcaneBlast()
    elseif sync == syncName.flamestrike and self.db.profile.flamestrike then
        self:Flamestrike()
    elseif sync == syncName.frostbolt and self.db.profile.frostbolt then
        self:Frostbolt()
    elseif sync == syncName.corruption and rest and self.db.profile.corruption then
		self:Corruption(rest)
	elseif sync == syncName.corruptionFade and rest and self.db.profile.corruption then
		self:CorruptionFade(rest)
    end
end

function module:Pyro()
    self:Bar(L["pyro_bar"], timer.pyro, icon.pyro, true, color.pyro)
	self:Sound("Beware")
end

function module:FrostNova()
    self:Bar(L["frostnova_bar"], timer.frostnova, icon.frostnova, true, color.frostnova)
	self:Sound("Beware")
end

function module:ArcaneBlast()
    self:Bar(L["arcaneblast_bar"], timer.arcaneblast, icon.arcaneblast, true, color.arcaneblast)
	self:Sound("Beware")
end

function module:Flamestrike()
    self:Bar(L["flamestrike_bar"], timer.flamestrike, icon.flamestrike, true, color.flamestrike)
	self:Sound("Beware")
end

function module:Frostbolt()
    self:Bar(L["frostbolt_bar"], timer.frostbolt, icon.frostbolt, true, color.frostbolt)
	self:Sound("Beware")
end

function module:Corruption(rest)
	if IsRaidLeader() then
        SendChatMessage(rest.." is Corrupted!","RAID_WARNING")
        self:Bar(rest..L["bar_corruption"], timer.corruption, icon.corruption, true, color.corruption)
    end
	if rest == UnitName("Player") then
        self:Bar(rest..L["bar_corruption"], timer.corruption, icon.corruption, true, color.corruption)
        SendChatMessage(UnitName("Player").." is Corrupted!","SAY")
        self:Message(L["msg_corruptionYou"], "Urgent") --, false, nil, false)
		self:WarningSign(icon.corruption, timer.corruption)
        PlaySoundFile(L["soundcorrupYou"])
		--self:Sound("RunAway")
	end
	if (IsRaidLeader() or IsRaidOfficer()) then
		for i=1,GetNumRaidMembers() do
			if UnitName("raid"..i) == rest then
				SetRaidTarget("raid"..i, 8)
			end
		end
	end
end

function module:CorruptionFade(rest)
	self:RemoveBar(rest..L["bar_corruption"])
	if (IsRaidLeader() or IsRaidOfficer()) then
		for i=1,GetNumRaidMembers() do
			if UnitName("raid"..i) == rest then
				SetRaidTarget("raid"..i, 0)
			end
		end
	end
end

function module:UsePotIcon()
    if IsRaidLeader() then 
        SendChatMessage(L["msg_usepot"],"RAID_WARNING")
    end
    self:WarningSign(icon.usepot, timer.usepoticon)
end

function module:UsePotSound()
    PlaySoundFile(L["soundgspp"])
end