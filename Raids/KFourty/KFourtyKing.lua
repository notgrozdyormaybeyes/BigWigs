
local module, L = BigWigs:ModuleDeclaration("King", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"kingsfury", "darksubservience", "charmingpresence", "trample", "fortify", "usepoticon", "usepotsound", "bosskill"}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

module.defaultDB = {
    kingsfury = true,
    darksubservience = true,
    charmingpresence = true,
    trample = true, 
    fortify = true,
    usepoticon = false,
    usepotsound = false,
}
L:RegisterTranslations("enUS", function() return {
    cmd = "King",
    
    kingsfury_cmd = "KingsFury",
    kingsfury_name = "King's Fury Alert",
    kingsfury_desc = "Warn for King's Fury (hide behind pillars)",
    
    darksubservience_cmd = "DarkSubservience",
    darksubservience_name = "Dark Subservience Alert",
    darksubservience_desc = "Warn for Dark Subservience (bow to the Queen)",
    
    charmingpresence_cmd = "CharmingPresence",
    charmingpresence_name = "Charming Presence Alert",
    charmingpresence_desc = "Warn for Charming Presence (Queen mind control)",
    
    trample_cmd = "Trample",
    trample_name = "Trample Alert",
    trample_desc = "Warning for Trample",
    
    fortify_cmd = "Fortify",
    fortify_name = "Fortify Alert",
    fortify_desc = "Warning for Fortify",
    
    usepoticon_cmd = "UsePotionIcon",
    usepoticon_name = "Use GSPP icon Alert",
    usepoticon_desc = "Warn to use GSPP icon every 2 min",
    
    usepotsound_cmd = "UsePotionSound",
    usepotsound_name = "Use GSPP sound Alert",
    usepotsound_desc = "Warn to use GSPP sound every 2 min",
    
    trigger_invz = "Void Zone's Consumption hits you",
    msg_invz = "You are in a Void Zone! Move out!",
    
    kingsfury_bar = "King's Fury, HIDE OUT OF LOS!",
    
    trigger_darksubservienceYou = "You are afflicted by Dark Subservience", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_darksubservienceOther = "(.+) is afflicted by Dark Subservience",  --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
    trigger_darksubservienceFade = "Dark Subservience fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
    bar_darksubservience = " must bow to the Queen!",
    msg_darksubservienceYou = "RUN to the Queen and bow!",
    soundbow = "Interface\\Addons\\BigWigs\\Sounds\\zeliekobey.mp3",
    soundbowkeda = "Interface\\Addons\\BigWigs\\Sounds\\kedaobey.mp3",
    
    trigger_mcYou = "You are afflicted by Charming Presence",
    trigger_mcOther = "(.+) %(Queen%)is afflicted by Charming Presence", 
    trigger_mcFade = "Charming Presence fades from (.+).", 
    bar_mc = " is Mind Controlled!",
    
    trigger_trample = "(.+) is afflicted by Trample", 
    msg_trampleone = "Trample on ",
    msg_trampletwo = "! Consider switching Knight tank",
    
    trigger_fortify = "Rook gains Fortify ",
    bar_fortify = "Fortify on Rook",
    msg_fortify = "Rook takes reduced damage and reflects",
    
    msg_usepot = "Use GSPP",
    soundgspp = "Interface\\Addons\\BigWigs\\Sounds\\shadowpot.wav",
    
    trigger_engage = "",--CHAT_MSG_MONSTER_YELL
    trigger_queen = "My King, I have come to your aid.",
    
} end )

local king_guid = "" --will be synced in OnEngage()
local queen_guid = "" --will be synced later when she spawns
local kingsfury_id = 51229
local darksubservience_id = 41647

local usepotcounter = 0

local timer = {
    kingsfury = 5,
    darksubservience = 8,
    mc = 60,
    trample = 60,
    fortify = 10,
    usepot = 120,
    usepotsound_pre = 2,
    usepoticon = 10,
}
local icon = {
    kingsfury = "Spell_Holy_HolyNova",
    darksubservience = "Spell_BrokenHeart", 
    mc = "Spell_Shadow_ShadowWordDominate",
    trample = "Ability_WarStomp",
    fortify = "Ability_Warrior_ShieldWall",
    circle = "INV_Jewelry_Ring_03",
    usepot = "spell_shadow_abominationexplosion", 
}
local color = {
    kingsfury = "Red",
    darksubservience = "Pink",
    mc = "Purple",
    trample = "Blue",
    fortify = "Yellow",
    circle = "Purple",
    usepot = "Black",
}
local syncName = {
    bossguid = "BossGuid"..module.revision,
    kingsfury = "KingsFury"..module.revision,
    darksubservience = "DarkSubservience"..module.revision,
    darksubservienceFade = "DarkSubservienceFade"..module.revision,
    mc = "CharmingPresence"..module.revision,
    mcFade = "CharmingPresenceFade"..module.revision,
    trample = "Trample"..module.revision,
}

--module:RegisterYellEngage(L["trigger_engage"]) --since the king doesn't yell anything :(

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event") --trigger_engage
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") 
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "HandleCombatStart")
    
    self:RegisterEvent("CHAT_MSG_SAY", "HandleMessage")
    
    if SUPERWOW_VERSION then -- check if SuperWoW is used. if not, pray that someone has it to sync with you :)
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
        --self:RegisterEvent("UNIT_HEALTH") 
    end
    
    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(5, syncName.kingsfury)
    self:ThrottleSync(3, syncName.darksubservience)
    self:ThrottleSync(3, syncName.darksubservienceFade)
    self:ThrottleSync(3, syncName.mc)
    self:ThrottleSync(3, syncName.mcFade)
    self:ThrottleSync(3, syncName.trample)
    
end

function module:OnSetup()
    self.started = nil
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH") 
end

function module:OnEngage()
    if SUPERWOW_VERSION and IsRaidLeader() then 
        TargetByName("King", true) --enUS hardcoded... should use L["bossname"]
        local _, king_guid = UnitExists("target")
        self:Sync(syncName.bossguid.." "..king_guid)
        TargetLastTarget()
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
    
end

function module:HandleCombatStart()
    self:OnEngage()
end

function module:HandleMessage(msg, sender)
    if tostring(sender) == "Grozdy" and tostring(msg)=="baguette" then
        SendChatMessage("no u","SAY")
    end
end

function module:UNIT_HEALTH(msg)
    if UnitName(msg) == "Keeper Gnarlmoon" then
        healthPct = UnitHealth(msg) * 100 / UnitHealthMax(msg)
        if healthPct >= 69 and lowHp ~= 0 then
            lowHp = 0
        elseif healthPct < 69 and healthPct > 65 and lowHp == 0 then
            self:Sync(syncName.lowHp)
        elseif healthPct < 36 and lowHp == 1 then
            self:Sync(syncName.lowHp)
        elseif healthPct <= 33 and lowHp == 2 then
            lowHp = -1
        end
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == king_guid then
        if spellId == kingsfury_id and eventType == "START" then -- doesn't work because no one targets king
            self:Sync(syncName.kingsfury)
        end
    elseif casterGuid == queen_guid then
    end
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	if (msg == string.format(UNITDIESOTHER, "Rook")) then
        self:Message("Rook is dead, HIDE!")
        self:Sync(syncName.kingsfury)
	elseif (msg == string.format(UNITDIESOTHER, "Knight")) then
        self:Message("Knight is dead, HIDE!")
        self:Sync(syncName.kingsfury)
	elseif (msg == string.format(UNITDIESOTHER, "Bishop")) then
        self:Message("Bishop is dead, HIDE!")
        self:Sync(syncName.kingsfury)
    end
end


function module:Event(msg)
    if string.find(msg, L["trigger_darksubservienceYou"]) then
        self:Sync(syncName.darksubservience .. " " .. UnitName("Player"))
    elseif string.find(msg, L["trigger_darksubservienceOther"]) then
        local _,_, dsPlayer,_ = string.find(msg, L["trigger_darksubservienceOther"])
        self:Sync(syncName.darksubservience .. " " .. dsPlayer)
    elseif string.find(msg, L["trigger_darksubservienceFade"]) then
        local _,_, dsFadePlayer,_ = string.find(msg, L["trigger_darksubservienceFade"])
        if dsFadePlayer == "you" then dsFadePlayer = UnitName("Player") end
        self:Sync(syncName.darksubservienceFade .. " " .. dsFadePlayer)
    elseif string.find(msg, L["trigger_mcYou"]) then
        self:Sync(syncName.mc .. " " .. UnitName("Player"))
    elseif string.find(msg, L["trigger_mcOther"]) then
        local _,_, mcPlayer,_ = string.find(msg, L["trigger_mcOther"])
        self:Sync(syncName.mc .. " " .. mcPlayer)
    elseif string.find(msg, L["trigger_mcFade"]) then
        local _,_, mcFadePlayer,_ = string.find(msg, L["trigger_mcFade"])
        if mcFadePlayer == "you" then mcFadePlayer = UnitName("Player") end
        self:Sync(syncName.mc .. " " .. mcFadePlayer)
    elseif string.find(msg, L["trigger_trample"]) then
        local _,_, trPlayer,_ = string.find(msg, L["trigger_trample"])
        self:Sync(syncName.trample .. " " .. trPlayer)
    elseif string.find(msg, L["trigger_fortify"]) and self.db.profile.fortify then
        self:Fortify()
    elseif string.find(msg, L["trigger_invz"]) then
        self:InVoidZone()
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bossguid then
        medivh_guid = rest
    elseif sync == syncName.kingsfury and self.db.profile.kingsfury then
        self:Kingsfury()
    elseif sync == syncName.darksubservience and rest and self.db.profile.darksubservience then
        self:DarkSubservience(rest)
    elseif sync == syncName.darksubservienceFade and rest and self.db.profile.darksubservience then
        self:DarkSubservienceFade(rest)
    elseif sync == syncName.mc and rest and self.db.profile.charmingpresence then
        self:CharmingPresence(rest)
    elseif sync == syncName.mcFade and rest and self.db.profile.charmingpresence then
        self:CharmingPresenceFade(rest)
    elseif sync == syncName.trample and rest and self.db.profile.trample then
        self:Trample(rest)
    end
end

function module:InVoidZone()
    self:Message(L["msg_invz"], "Urgent")
    self:WarningSign(icon.circle, 3)
    self:Sound("RunAway")
end

function module:KingsFury()
    self:Bar(L["kingsfury_bar"], timer.kingsfury, icon.kingsfury, true, color.kingsfury)
    self:WarningSign(icon.kingsfury, timer.kingsfury)
    self:Sound("RunAway")
end

function module:DarkSubservience(rest)
    if IsRaidLeader() then
        SendChatMessage(rest..L["bar_darksubservience"],"RAID_WARNING")
        --self:Bar(rest..L["bar_darksubservience"], timer.darksubservience, icon.darksubservience, true, color.darksubservience)
    end
    if rest == UnitName("Player") then
        --self:Bar(rest..L["bar_darksubservience"], timer.darksubservience, icon.darksubservience, true, color.darksubservience)
        SendChatMessage(UnitName("Player")..L["bar_darksubservience"],"SAY")
        self:Message(L["msg_darksubservienceYou"], "Urgent") --, false, nil, false)
        self:WarningSign(icon.darksubservience, timer.darksubservience)
        PlaySoundFile(L["soundbow"])
        self:Bar("> Click Me to Bow <", timer.darksubservience, icon.darksubservience, true, "White")
        self:SetCandyBarOnClick("BigWigsBar > Click Me to Bow <", function(name, button, extra) 
                TargetByName(extra, true) 
                DoEmote("bow")
                DoEmote("kneel")
            end, "Queen")
        --self:Sound("RunAway")
    end
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 4)
            end
        end
    end
end

function module:DarkSubservienceFade(rest)
    self:RemoveBar(rest..L["bar_darksubservience"])
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 0)
            end
        end
    end
end

function module:CharmingPresence(rest)
    if IsRaidLeader() then
        SendChatMessage(rest..L["bar_mc"],"RAID_WARNING")
        --self:Bar(rest..L["bar_mc"], timer.mc, icon.mc, true, color.mc)
    end
    if rest == UnitName("Player") then
        self:Bar(rest..L["bar_mc"], timer.mc, icon.mc, true, color.mc)
        SendChatMessage(UnitName("Player")..L["bar_mc"],"SAY")
        self:Message(L["msg_mcYou"], "Urgent") --, false, nil, false)
        self:WarningSign(icon.mc, timer.mc)
    end
    self:Bar("> Click to target MC'd <", timer.mc, icon.mc, true, "White")
    self:SetCandyBarOnClick("BigWigsBar > Click to target MC'd <", function(name, button, extra) 
            TargetByName(extra, true) 
        end, rest)
    BigWigsBars:EmphasizeBar(self, "BigWigsBar > Click to target MC'd <")
    self:Sound("Beware")
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 8)
            end
        end
    end
end

function module:CharmingPresenceFade(rest)
    self:RemoveBar(rest..L["bar_mc"])
    self:RemoveBar("> Click to target MC'd <")
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 0)
            end
        end
    end
end

function module:Trample(rest)
    if IsRaidLeader() or IsRaidOfficer() then
        self:Message(L["msg_trampleone"]..rest..L["msg_trampletwo"], "Attention")
        self:Bar(L["msg_trampleone"]..rest, timer.trample, icon.trample, true, color.trample)
    end
    if rest == UnitName("Player") then
        self:Bar(L["msg_trampleone"]..rest, timer.trample, icon.trample, true, color.trample)
        self:WarningSign(icon.trample, timer.trample)
        self:Sound("Beware")
    end
    --if (IsRaidLeader() or IsRaidOfficer()) then
    --    for i=1,GetNumRaidMembers() do
    --        if UnitName("raid"..i) == rest then
    --            SetRaidTarget("raid"..i, 4)
    --        end
    --    end
    --end
end

function module:Fortify()    
    self:Message(L["msg_fortify"], "Attention")
    self:Bar(L["bar_fortify"], timer.fortify, icon.fortify, true, color.fortify)
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