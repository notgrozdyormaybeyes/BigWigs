local module, L = BigWigs:ModuleDeclaration("Trioch the Devourer", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Trioch"
module.toggleoptions = {"icicle"}
module.zonename = "TimbermawHold"

module.defaultDB = {
    icicle = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Trioch",
    icicle_cmd = "Icicle",
    icicle_name = "Icicle Alert",
    icicle_desc = "Warn for Icicle",
    icicle_warning_bar = "Stack on boss!",
    icicle_warning_msg = "Icicle on YOU! Stack on boss!",
    icicle_warning_RL = "TRIANGLE and MOON stack on boss",
    trigger_icicles = "Trioch targets ([^%s]+) and ([^%s]+) with giant icicles!",
} end)

local trioch_guid = nil
local raidmembers = {}

local timer = {
    icicle = 3,
}

local icon = {
    icicle = "Spell_Frost_FrostBlast",
}

local color = {
    icicle = "Blue",
}

local syncName = {
    bossguid = "BossGuid"..module.revision,
    icicle = "Icicle"..module.revision,
}

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
    self:ThrottleSync(3, syncName.icicle)
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
        TargetByName("Trioch the Devourer", true)
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
end

function module:UNIT_HEALTH(msg)
end

function module:Event(msg)
end

function module:OnEmote(msg)
    if string.find(msg, L["trigger_icicles"]) and self.db.profile.icicle then
        local _, _, p1, p2 = string.find(msg, L["trigger_icicles"])
        self:Sync(syncName.icicle.." "..p1.." "..p2)
    end
end

function module:BigWigs_RecvSync(sync, rest)
    if sync == syncName.bossguid then
        trioch_guid = rest
    elseif sync == syncName.icicle and self.db.profile.icicle then
        local p1, p2 = rest:match("([^%s]+)%s+([^%s]+)")
        self:Icicle(p1, p2)
    end
end

function module:RemoveCastbars()
end

function module:Icicle(playerOne, playerTwo)
    if IsRaidLeader() then
        SendChatMessage(L["icicle_warning_RL"], "RAID_WARNING")
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == playerOne then
                SetRaidTarget("raid"..i, 4)
            end
            if UnitName("raid"..i) == playerTwo then
                SetRaidTarget("raid"..i, 5)
            end
        end
    end

    if UnitName("player") == playerOne or UnitName("player") == playerTwo then
        self:Bar(L["icicle_warning_bar"], timer.icicle, icon.icicle, true, color.icicle)
        self:Message(L["icicle_warning_msg"], "Urgent")
    end
end
