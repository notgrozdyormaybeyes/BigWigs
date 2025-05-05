
local module, L = BigWigs:ModuleDeclaration("Echo of Medivh", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"gaze", "pyro", "frostnova", "arcaneblast", "flamestrike", "frostbolt", "shadowbolt", "switchflame_to_shadow", "corruption", "doom", "infernal", "proximity", "usepoticon", "usepotsound", "bosskill"}
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
    shadowbolt = false,
    switchflame_to_shadow = true,
    corruption = true,
    doom = false,
    infernal = false,
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
    
    shadowbolt_cmd = "Shadowbolt",
    shadowbolt_name = "Shadowbolt Alert",
    shadowbolt_desc = "Warn for Shadowbolt",
    
    switchflame_to_shadow_cmd = "SwitchFlameToShadowbolt",
    switchflame_to_shadow_name = "Switch Flamestrike To Shadowbolt Alert",
    switchflame_to_shadow_desc = "Warn for Shadowbolt instead of Flamestrike below 50 percent",
    
    corruption_cmd = "Corruption",
    corruption_name = "Corruption Alert",
    corruption_desc = "Warn for Corruption",
    
    doom_cmd = "DoomOfMedivh",
    doom_name = "Doom of Medivh Alert",
    doom_desc = "Warn for Doom of Medivh",
    
    infernal_cmd = "Infernal",
    infernal_name = "Infernal Alert",
    infernal_desc = "Warn for Infernal",
    
    proximity_cmd = "Proximity",
    proximity_name = "Proximity Alert",
    proximity_desc = "Warning frame for Proximity",
    
    usepoticon_cmd = "UsePotionIcon",
    usepoticon_name = "Use GSPP icon Alert",
    usepoticon_desc = "Warn to use GSPP icon every 2 min",
    
    usepotsound_cmd = "UsePotionSound",
    usepotsound_name = "Use GSPP sound Alert",
    usepotsound_desc = "Warn to use GSPP sound every 2 min",
    
    pyro_bar = "Pyroblast!",
    frostnova_bar = "Frost Nova!",
    arcaneblast_bar = "Arcane Blast!",
    flamestrike_bar = "Flamestrike!",
    frostbolt_bar = "Frostbolt!",
    shadowbolt_bar = "Shadowbolt!",
    
    trigger_inflames = "You are afflicted by Flamestrike",
    msg_inflames = "You are in Flamestrike! Move out!",
    
    trigger_corruptionYou = "You are afflicted by Corruption of Medivh", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_corruptionOther = "(.+) is afflicted by Corruption of Medivh",  --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
    trigger_corruptionFade = "Corruption of Medivh fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
    bar_corruption = " is Corrupted!",
    msg_corruptionYou = "You are Corrupted! Move away from your friends!",
    soundcorrupYou = "Interface\\Addons\\BigWigs\\Sounds\\corruption.mp3",
    
    trigger_doom = "You are afflicted by Doom of Medivh", 
    msg_doom = "New Doom of Medivh stack applied!",
    
    msg_infernal = "Infernal incoming soon!",
    
    msg_usepot = "Use GSPP",
    soundgspp = "Interface\\Addons\\BigWigs\\Sounds\\shadowpot.wav",
    
    trigger_engage = "My patience has come to an end. You will not leave this tower alive.",--CHAT_MSG_MONSTER_YELL
    trigger_bossDead = "Your resistance is futile.",
} end )

local medivh_guid = nil --nice name. it is instance dependent. will be synced in OnEngage()
local self_guid = nil
local gaze_id = 51111
local pyro_id = 51112
local frostnova_id = 51114 
local arcaneblast_id = 51116 
local flamestrike_id = 51113
local frostbolt_id = 51118 
local shadowbolt_id = 51122 
local arcanefocus_id = 51115 
local corruption_id = 52674
local doom_id = 40004 -- also 40005 & 40006
local lowHp = 0
local healthPct = 100
local stop_flamestrike = false

local raidmembers  = {}

local timer = {
    pyro = 1.6, 
    frostnova = 1.6, 
    arcaneblast = 1.6, 
    flamestrike = 1.6, 
    frostbolt = 1.6, 
    shadowbolt = 2, 
    corruption = 6,
    doom = 5,
    infernal = 5,
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
    shadowbolt = "Spell_Shadow_ShadowBolt", 
    corruption = "spell_shadow_abominationexplosion", --INV_Misc_Bomb_05
    doom = "Classicon_warlock",
    infernal = "Spell_Shadow_SummonInfernal",
    circle = "INV_Jewelry_Ring_03",
    usepot = "spell_shadow_abominationexplosion", 
}
local color = {
    pyro = "Red",
    frostnova = "Blue",
    arcaneblast = "Purple",
    flamestrike = "Red",
    frostbolt = "Blue",
    shadowbolt = "Black",
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
    shadowbolt = "Shadowbolt"..module.revision,
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
    self:RegisterEvent("UNIT_HEALTH") --lowHp
    
    if SUPERWOW_VERSION then -- check if SuperWoW is used. if not, pray that someone has it to sync with you :)
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(5, syncName.pyro)
    self:ThrottleSync(5, syncName.frostnova)
    self:ThrottleSync(5, syncName.arcaneblast)
    self:ThrottleSync(5, syncName.flamestrike)
    self:ThrottleSync(5, syncName.frostbolt)
    self:ThrottleSync(5, syncName.shadowbolt)
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
        TargetLastTarget()
        local _, self_guid = UnitExists("player")
    end
    
    if UnitName("player") == "Grozdy" then
        for i=1,GetNumRaidMembers() do
            TargetByName(UnitName("raid"..i), true)
            local _, member_guid = UnitExists("target")
            raidmembers[member_guid] = UnitName("raid"..i)
            TargetLastTarget()
        end
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
            self:ScheduleRepeatingEvent("bwUsepotsound", function() self:UsePotSound() end, timer.usepot)
        end, timer.usepot)
    end
    stop_flamestrike = false
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
            --print(casterGuid.." "..targetGuid.." "..eventType.." "..spellId.." "..castTime)
        end
        if spellId == pyro_id and eventType == "START" then 
            self:Sync(syncName.pyro.." "..castTime)
        elseif spellId == frostnova_id and eventType == "START" then 
            self:Sync(syncName.frostnova.." "..castTime)
        elseif spellId == arcaneblast_id and eventType == "START" then 
            self:Sync(syncName.arcaneblast.." "..castTime)
        elseif spellId == flamestrike_id and eventType == "START" then 
            self:Sync(syncName.flamestrike.." "..castTime)
        elseif spellId == frostbolt_id and eventType == "START" then 
            self:Sync(syncName.frostbolt.." "..castTime)
        elseif spellId == shadowbolt_id and eventType == "START" then 
            self:Sync(syncName.shadowbolt.." "..castTime)
        end
    end
end

function module:UNIT_HEALTH(msg)
    if UnitName(msg) == "Echo of Medivh" then
        healthPct = UnitHealth(msg) * 100 / UnitHealthMax(msg)
        if lowHp ~= 0 and healthPct >= 84 then
            lowHp = 0
        elseif lowHp == 0 and healthPct < 84 and healthPct > 79 then
            if self.db.profile.infernal then
                self:Message(L["msg_infernal"], "Attention")
                self:WarningSign(icon.infernal, timer.infernal)
            end
            lowHp = 1
        elseif lowHp == 1 and healthPct < 54 and healthPct > 51 then
            if self.db.profile.infernal then
                self:Message(L["msg_infernal"], "Attention")
                self:WarningSign(icon.infernal, timer.infernal)
            end
            lowHp = 2
        elseif healthPct <= 50.9 and healthPct > 49.5 then
            if switchflame_to_shadow and stop_flamestrike == false then
                stop_flamestrike = true
            end
        elseif lowHp == 2 and healthPct < 24 then
            if self.db.profile.infernal then
                self:Message(L["msg_infernal"], "Attention")
                self:WarningSign(icon.infernal, timer.infernal)
            end
            lowHp = 0
        end
    end
end

function module:Event(msg)
    if string.find(msg, L["trigger_corruptionYou"]) and self.db.profile.corruption then
        self:Sync(syncName.corruption .. " " .. UnitName("Player"))
    elseif string.find(msg, L["trigger_corruptionOther"]) and self.db.profile.corruption  then
        local _,_, corrPlayer,_ = string.find(msg, L["trigger_corruptionOther"])
        self:Sync(syncName.corruption .. " " .. corrPlayer)
    elseif string.find(msg, L["trigger_corruptionFade"]) and self.db.profile.corruption  then
        local _,_, corrFadePlayer,_ = string.find(msg, L["trigger_corruptionFade"])
        if corrFadePlayer == "you" then corrFadePlayer = UnitName("Player") end
        self:Sync(syncName.corruptionFade .. " " .. corrFadePlayer)
    elseif string.find(msg, L["trigger_doom"]) and self.db.profile.doom then
        self:DoomOfMedivh()
    elseif string.find(msg, L["trigger_inflames"]) then
        self:InFlamestrike()
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bossguid then
        medivh_guid = rest
    elseif sync == syncName.pyro and self.db.profile.pyro then
        self:Pyro(rest)
    elseif sync == syncName.frostnova and self.db.profile.frostnova then
        self:FrostNova(rest)
    elseif sync == syncName.arcaneblast and self.db.profile.arcaneblast then
        self:ArcaneBlast(rest)
    elseif sync == syncName.flamestrike and self.db.profile.flamestrike then
        if stop_flamestrike == false then 
            self:Flamestrike(rest) 
        end
    elseif sync == syncName.frostbolt and self.db.profile.frostbolt then
        self:Frostbolt(rest)
    elseif sync == syncName.shadowbolt and (self.db.profile.shadowbolt or self.db.profile.switchflame_to_shadow) then
        self:Shadowbolt(rest)
    elseif sync == syncName.corruption and rest and self.db.profile.corruption then
        self:Corruption(rest)
    elseif sync == syncName.corruptionFade and rest and self.db.profile.corruption then
        self:CorruptionFade(rest)
    end
end

function module:Pyro(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.pyro then casttime = timer.pyro end
    self:Bar(L["pyro_bar"], casttime, icon.pyro, true, color.pyro)
    self:Sound("Beware")
end

function module:FrostNova(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.frostnova then casttime = timer.frostnova end
    self:Bar(L["frostnova_bar"], casttime, icon.frostnova, true, color.frostnova)
    self:Sound("Beware")
end

function module:ArcaneBlast(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.arcaneblast then casttime = timer.arcaneblast end
    self:Bar(L["arcaneblast_bar"], casttime, icon.arcaneblast, true, color.arcaneblast)
    self:Sound("Beware")
end

function module:Flamestrike(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.flamestrike then casttime = timer.flamestrike end
    self:Bar(L["flamestrike_bar"], casttime, icon.flamestrike, true, color.flamestrike)
    self:Sound("Beware")
end

function module:InFlamestrike()
    self:Message(L["msg_inflames"], "Urgent")
    self:WarningSign(icon.flamestrike, 3)
    self:Sound("RunAway")
end

function module:Frostbolt(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.frostbolt then casttime = timer.frostbolt end
    self:Bar(L["frostbolt_bar"], casttime, icon.frostbolt, true, color.frostbolt)
    self:Sound("Beware")
end

function module:Shadowbolt(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.shadowbolt then casttime = timer.shadowbolt end
    self:Bar(L["shadowbolt_bar"], casttime, icon.shadowbolt, true, color.shadowbolt)
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

function module:DoomOfMedivh()
    self:Message(L["msg_doom"], "Attention")
    self:WarningSign(icon.doom, timer.doom)
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