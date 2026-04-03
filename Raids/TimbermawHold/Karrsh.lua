local module, L = BigWigs:ModuleDeclaration("Karrsh the Sentinel", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Karrsh"
module.toggleoptions = {"maul", "felstomp", "corruption"}
module.zonename = nil

module.defaultDB = {
    maul = true,
    felstomp = true,
    corruption = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Karrsh",
    maul_cmd = "CrushingMaul",
    maul_name = "Crushing Maul Alert",
    maul_desc = "Warn for Crushing Maul",
    felstomp_cmd = "FelStomp",
    felstomp_name = "Fel Stomp Alert",
    felstomp_desc = "Warn for Fel Stomp",
    corruption_cmd = "Corruption",
    corruption_name = "Corruption Alert",
    corruption_desc = "Warn for Corruption",
    maul_bar = "Crushing Maul ",
    maul_help = "Shield or HoP the target!",
    maul_targeted = "You are focused! Kite the boss!",
    felstomp_bar = "Melee move out",
    trigger_corruptionYou = "You are afflicted by Seed of Corruption",
    trigger_corruptionOther = "(.+) is afflicted by Seed of Corruption",
    trigger_corruptionFade = "Seed of Corruption fades from (.+).",
    bar_corruption = " is Corrupted!",
    msg_corruptionYou = "You are Corrupted! Move away from your friends!",
    trigger_engage = "Outsiders... you will go no further.",
    trigger_bossDead = "The whispers... finally... quiet...",
} end)

local karrsh_guid = nil
local maul_id = 33034
local felstomp_id = 33048
local corruption_id = 33046
local raidmembers = {}

local timer = {
    maul = 2,
    maultarget = 5,
    felstomp = 3,
    corruption = 12,
}

local icon = {
    maul = "Ability_Druid_Maul",
    felstomp = "Spell_Nature_ThunderClap",
    corruption = "spell_shadow_abominationexplosion",
}

local color = {
    maul = "Red",
    felstomp = "Blue",
    corruption = "Cyan",
}

local syncName = {
    bossguid = "BossGuid"..module.revision,
    maul = "Maul"..module.revision,
    maultarget = "MaulTarget"..module.revision,
    felstomp = "FelStomp"..module.revision,
    corruption = "Corruption"..module.revision,
    corruptionFade = "CorruptionFade"..module.revision,
}

module.proximityCheck = function(unit)
    return CheckInteractDistance(unit, 2)
end

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")
    self:RegisterEvent("UNIT_HEALTH")

    if SUPERWOW_VERSION then
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end

    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(3, syncName.maul)
    self:ThrottleSync(3, syncName.maultarget)
    self:ThrottleSync(3, syncName.felstomp)
    self:ThrottleSync(3, syncName.corruption)
    self:ThrottleSync(3, syncName.corruptionFade)
end

function module:OnSetup()
    self.started = nil
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            local _, guid = UnitExists("raid"..i)
            raidmembers[guid] = UnitName("raid"..i)
        end
    end
end

function module:OnEngage()
    if SUPERWOW_VERSION and (IsRaidLeader() or IsRaidOfficer() or UnitClass("player") == "Warrior") then
        TargetByName("Karrsh the Sentinel", true)
        local _, guid = UnitExists("target")
        if guid then
            self:Sync(syncName.bossguid.." "..guid)
        end
    end

    if self.db.profile.proximity then
        self:Proximity()
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
        end
    end
    if self.db.profile.proximity then
        self:RemoveProximity()
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == karrsh_guid then
        if spellId == maul_id and eventType == "START" then
            self:Sync(syncName.maul.." "..castTime)
            if IsRaidLeader() or IsRaidOfficer() then
                local targetname = raidmembers[targetGuid]
                self:Sync(syncName.maultarget.." "..targetname)
            end
        elseif spellId == felstomp_id and eventType == "START" then
            self:Sync(syncName.felstomp.." "..castTime)
        end
    end
end

function module:UNIT_HEALTH(msg)
end

function module:Event(msg)
    if string.find(msg, L["trigger_corruptionYou"]) and self.db.profile.corruption then
        self:Sync(syncName.corruption.." "..UnitName("player"))
    elseif string.find(msg, L["trigger_corruptionOther"]) and self.db.profile.corruption then
        local _, _, corrPlayer = string.find(msg, L["trigger_corruptionOther"])
        self:Sync(syncName.corruption.." "..corrPlayer)
    elseif string.find(msg, L["trigger_corruptionFade"]) and self.db.profile.corruption then
        local _, _, corrFadePlayer = string.find(msg, L["trigger_corruptionFade"])
        if string.lower(corrFadePlayer) == "you" then
            corrFadePlayer = UnitName("player")
        end
        self:Sync(syncName.corruptionFade.." "..corrFadePlayer)
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:BigWigs_RecvSync(sync, rest)
    if sync == syncName.bossguid then
        karrsh_guid = rest
    elseif sync == syncName.maul and self.db.profile.maul then
        self:Maul(rest)
    elseif sync == syncName.maultarget and self.db.profile.maul then
        self:MaulTarget(rest)
    elseif sync == syncName.felstomp and self.db.profile.felstomp then
        self:FelStomp(rest)
    elseif sync == syncName.corruption and rest and self.db.profile.corruption then
        self:Corruption(rest)
    elseif sync == syncName.corruptionFade and rest and self.db.profile.corruption then
        self:CorruptionFade(rest)
    end
end

function module:RemoveCastbars()
    self:RemoveBar(L["maul_bar"])
    self:RemoveBar(L["felstomp_bar"])
end

function module:Maul(rest)
    local casttime = tonumber(rest) / 1000
    if not casttime or casttime <= timer.maul then
        casttime = timer.maul
    end
    self:Bar(L["maul_bar"], casttime, icon.maul, true, color.maul)
    self:Sound("Beware")
end

function module:MaulTarget(rest)
    if rest == UnitName("player") then
        self:Message(L["maul_targeted"], "Urgent")
    elseif UnitClass("player") == "Paladin" or UnitClass("player") == "Priest" then
        self:Bar("> Click to target "..rest.." <", timer.maultarget, icon.maul, true, color.maul)
        self:SetCandyBarOnClick("BigWigsBar ".."> Click to target "..rest.." <", function(name, button, extra) TargetByName(extra, true) end, rest)
        self:Message(L["maul_help"], "Normal")
    end
end

function module:FelStomp(rest)
    local casttime = tonumber(rest) / 1000
    if not casttime or casttime <= timer.felstomp then
        casttime = timer.felstomp
    end
    self:Bar(L["felstomp_bar"], casttime, icon.felstomp, true, color.felstomp)
    self:Sound("Beware")
end

function module:Corruption(rest)
    self:Bar(rest..L["bar_corruption"], timer.corruption, icon.corruption, true, color.corruption)
    if IsRaidLeader() then
        SendChatMessage(rest.." is Corrupted! Do not dispell", "RAID_WARNING")
    end
    if rest == UnitName("player") then
        SendChatMessage(UnitName("player").." is Corrupted!", "SAY")
        self:Message(L["msg_corruptionYou"], "Urgent")
        self:WarningSign(icon.corruption, timer.corruption)
        self:Sound("RunAway")
    end
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 8)
            end
        end
    end
end

function module:CorruptionFade(rest)
    self:RemoveBar(rest..L["bar_corruption"])
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 0)
            end
        end
    end
end

-- tests
SLASH_KARRSHTEST1 = "/karrshtest"
SlashCmdList["KARRSHTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "felstomp" then
        self:FelStomp(3000)
    elseif msg == "corruption" then
        self:Corruption(UnitName("player"))
    elseif msg == "maul" then
        self:Maul(3000)
    elseif msg == "mault" then
        self:MaulTarget("Grozdy")
        --self:Arrow(UnitName("player"))
    elseif msg == "tranq" then
        self:Tranq()
    else
        print("Commands: corruption, maul, mault, felstomp")
    end
end
