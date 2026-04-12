local module, L = BigWigs:ModuleDeclaration("Trioch the Devourer", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Trioch the Devourer"
module.toggleoptions = {"icicle"}
module.zonename = "Timbermaw Hold"

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

    trigger_icicles = "Trioch targets ([%w%-]+) and ([%w%-]+) with giant icicles",
} end)

-- according to my logs
local trioch_guid = "0xF13000F5E2279930"

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

    if SUPERWOW_VERSION then
        self:ScheduleRepeatingEvent("ScanTriochBoss", self.ScanBossGuid, 0.5, self)
    end

    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(3, syncName.icicle)
end

function module:OnSetup()
    self.started = nil
end

function module:OnEngage()
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
    if IsRaidLeader() then
        for i = 1, GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
        end
    end
end

function module:ScanBossGuid()
    if trioch_guid then
        self:CancelScheduledEvent("ScanTriochBoss")
        return
    end

    for _, frame in ipairs({WorldFrame:GetChildren()}) do
        if frame.GetName and frame:GetName() then
            local guid = frame:GetName(1)
            if guid then
                local name = UnitName(guid)
                if name == "Trioch the Devourer" then
                    trioch_guid = guid
                    self:Sync(syncName.bossguid.." "..guid)
                    break
                end
            end
        end
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
end

function module:Event(msg)
end

function module:OnEmote(msg)
    if not self.db.profile.icicle then return end
    local p1, p2 = string.match(msg, L["trigger_icicles"])
    if p1 and p2 then
        self:Sync(syncName.icicle.." "..p1.." "..p2)
    end
end

function module:BigWigs_RecvSync(sync, rest)
    if sync == syncName.bossguid then
        trioch_guid = rest

    elseif sync == syncName.icicle and self.db.profile.icicle then
        local p1, p2 = rest:match("(.+)%s+(.+)")
        if p1 and p2 then
            self:Icicle(p1, p2)
        end
    end
end

function module:Icicle(playerOne, playerTwo)
    if IsRaidLeader() then
        SendChatMessage(L["icicle_warning_RL"], "RAID_WARNING")
        for i = 1, GetNumRaidMembers() do
            local name = UnitName("raid"..i)
            if name == playerOne then
                SetRaidTarget("raid"..i, 4)
            elseif name == playerTwo then
                SetRaidTarget("raid"..i, 5)
            end
        end
    end

    local me = UnitName("player")
    if me == playerOne or me == playerTwo then
        self:Bar(L["icicle_warning_bar"], timer.icicle, icon.icicle, true, color.icicle)
        self:Message(L["icicle_warning_msg"], "Urgent")
    end
end
