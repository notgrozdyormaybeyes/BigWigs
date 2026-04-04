local module, L = BigWigs:ModuleDeclaration("Ormanos the Cracked", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Ormanos the Cracked"
module.toggleoptions = {"rampaging", "crush", "erosion"}
module.zonename = "TimbermawHold"

module.defaultDB = {
    rampaging = true,
    crush = true,
    erosion = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Ormanos",
    rampaging_cmd = "RampagingEarth",
    rampaging_name = "Rampaging Earth Alert",
    rampaging_desc = "Warn for Rampaging Earth",
    crush_cmd = "CrushEarth",
    crush_name = "Crush Earth Alert",
    crush_desc = "Warn for Crush Earth",
    erosion_cmd = "Erosion",
    erosion_name = "Erosion Alert",
    erosion_desc = "Warn for Erosion (only for RL & assists)",
    rampaging_warning_bar = "Run away!!",
    rampaging_warning_msg = "Charge on YOU! Run away from the boss!",
    rampaging_warning_RL = "must run away from the boss, stack on DIAMOND!",
    trigger_rampaging = "Ormanos is preparing to charge ([^%s]+)!",
    crush_bar = "Crush incoming",
    crush_duration_bar = "Watchout for crushed earth",
    trigger_erosionYou = "You are afflicted by Erosion %((.+)%).",
    trigger_erosionOther = "(.+) is afflicted by Erosion %((.+)%).",
    trigger_erosionFade = "Erosion fades from (.+).",
    msg_erosioncount = "% increased damage",
    msg_manyerosion = " erosion applied, consider switching tanks.",
    msg_erosionfaded = "You dropped all stacks of Erosion.",
    trigger_engage = "Rock and Stone...",
    trigger_bossDead = "The cracks begin to show...",
} end)

local ormanos_guid = nil
local crush_guid = 49026
local warn_erosion_stacks = 3
local raidmembers = {}

local timer = {
    rampaging = 6,
    crush = 2.5,
    crush_duration = 10,
    erosion = 30,
}

local icon = {
    rampaging = "Ability_Warrior_Charge",
    crush = "Spell_Nature_Earthquake",
    erosion = "Ability_Warrior_Sunder",
}

local color = {
    rampaging = "Yellow",
    crush = "White",
    erosion = "Orange",
}

local syncName = {
    bossguid = "BossGuid"..module.revision,
    rampaging = "Rampaging"..module.revision,
    crush = "Crush"..module.revision,
    erosion = "Erosion"..module.revision,
    erosionFade = "ErosionFade"..module.revision,
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")
    self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "OnEmote")
    self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "OnEmote")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")

    if SUPERWOW_VERSION then
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end

    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(3, syncName.rampaging)
    self:ThrottleSync(3, syncName.crush)
    self:ThrottleSync(1, syncName.erosion)
    self:ThrottleSync(3, syncName.erosionFade)
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
        TargetByName("Ormanos the Cracked", true)
        local _, guid = UnitExists("target")
        if guid then
            self:Sync(syncName.bossguid.." "..guid)
        end
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
        end
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == ormanos_guid and spellId == crush_guid and eventType == "START" then
        self:Sync(syncName.crush.." "..castTime)
    end
end

function module:Event(msg)
    if string.find(msg, L["trigger_erosionYou"]) then
        local _, _, qty = string.find(msg, L["trigger_erosionYou"])
        if UnitName("target") == "Ormanos the Cracked" and UnitName("targettarget") == UnitName("player") then
            self:Sync(syncName.erosion.." "..UnitName("player").." "..qty)
        end
    elseif string.find(msg, L["trigger_erosionOther"]) then
        local _, _, player, qty = string.find(msg, L["trigger_erosionOther"])
        self:Sync(syncName.erosion.." "..player.." "..qty)
    elseif string.find(msg, L["trigger_erosionFade"]) then
        self:Sync(syncName.erosionFade)
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:OnEmote(msg)
    if string.find(msg, L["trigger_rampaging"]) and self.db.profile.rampaging then
        local _, _, target = string.find(msg, L["trigger_rampaging"])
        self:Sync(syncName.rampaging.." "..target)
    end
end

function module:BigWigs_RecvSync(sync, rest)
    if sync == syncName.bossguid then
        ormanos_guid = rest
    elseif sync == syncName.rampaging and self.db.profile.rampaging then
        self:Rampaging(rest)
    elseif sync == syncName.crush and self.db.profile.crush then
        self:Crush(rest)
    elseif sync == syncName.erosion and rest and self.db.profile.erosion then
        self:Erosion(rest)
    elseif sync == syncName.erosionFade and self.db.profile.erosion then
        self:ErosionFade()
    end
end

function module:Rampaging(target)
    if IsRaidLeader() then
        SendChatMessage(target.." "..L["rampaging_warning_RL"], "RAID_WARNING")
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == target then
                SetRaidTarget("raid"..i, 3)
            end
        end
    end
    if UnitName("player") == target then
        self:Bar(L["rampaging_warning_bar"], timer.rampaging, icon.rampaging, true, color.rampaging)
        self:Message(L["rampaging_warning_msg"], "Urgent")
    end
end

function module:Crush(rest)
    local casttime = tonumber(rest) / 1000
    if not casttime or casttime <= timer.crush then
        casttime = timer.crush
    end
    self:Bar(L["crush_bar"], casttime, icon.crush, true, color.crush)
    self:DelayedBar(casttime, L["crush_duration_bar"], timer.crush_duration, icon.crush, true, color.crush)
    self:Sound("Beware")
end

function module:Erosion(rest)
    local player = string.sub(rest, 1, string.find(rest, " ") - 1)
    local qty = tonumber(string.sub(rest, string.find(rest, " ") + 1))
    local current = qty * 10

    if IsRaidLeader() or IsRaidOfficer() or UnitName("player") == player then
        for i = 10, 200, 10 do
            self:RemoveBar(player.." has "..i..L["msg_erosioncount"])
        end
        self:Bar(player.." has "..current..L["msg_erosioncount"], timer.erosion, icon.erosion, true, color.erosion)
        if qty >= warn_erosion_stacks then
            self:Message(player.." has "..qty..L["msg_manyerosion"], "Attention")
        end
    end
end

function module:ErosionFade()
    self:Message(L["msg_erosionfaded"])
end

-- tests
SLASH_ORMANOSTEST1 = "/ormanostest"
SlashCmdList["ORMANOSTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "rampaging" then
        self:Rampaging(UnitName("player"))
    elseif msg == "crush" then
        self:Crush(4000)
    elseif msg == "erosion" then
        self:Erosion(UnitName("player").." 21")
    else
        print("Commands: rampaging, crush, erosion")
    end
end
