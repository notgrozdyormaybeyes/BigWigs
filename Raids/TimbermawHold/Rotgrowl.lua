local module, L = BigWigs:ModuleDeclaration("Rotgrowl", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Rotgrowl"
module.toggleoptions = {"arrow", "killcommand", "tranq", "fearroar"}
module.zonename = "TimbermawHold"

module.defaultDB = {
    arrow = true,
    killcommand = true,
    tranq = true,
    fearroar = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Rotgrowl",
    arrow_cmd = "FireArrow",
    arrow_name = "Fire-soaked Arrow Alert",
    arrow_desc = "Warn for Fire-soaked Arrow",
    killcommand_cmd = "KillCommand",
    killcommand_name = "Kill Command Alert",
    killcommand_desc = "Warn for Kill Command",
    tranq_cmd = "Tranq",
    tranq_name = "Tranq Alert",
    tranq_desc = "Warn for Tranq",
    fearroar_cmd = "FearfulRoar",
    fearroar_name = "Fearful Roar Alert",
    fearroar_desc = "Warn for Fearful Roar",
    arrow_warning_bar = "Stack on ",
    arrow_warning_RL = "Stack on TRIANGLE ",
    trigger_arrow = "Rotgrowl begins to perform Fire-Soaked Arrow",
    trigger_arrow_aim = "Rotgrowl aims a flaming bolt at ([^!]+)!",
    trigger_tranq = "Kodiak gains Rage of the Ursa",
    tranq_msg = "Tranq shot on Kodiak required!",
    killcommand_bar = "Kill Command on ",
    kc_help = "Shield or HoP the target!",
    kc_targeted = "You are focused!",
    trigger_kc_aim = "Rotgrowl commands Kodiak to kill ([^!]+)!",
    fearroar_bar = "Pet AoE Fear",
    fearroar_help = "Fear soon, Fear Ward & Tremor Totem!",
    trigger_engage = "Destroy them Kodiak, show them no mercy!",
    trigger_bossDead = "I shall... Overcome...",
} end)

local rotgrowl_guid = nil
local kodiak_guid = nil
local arrow_id = 49569
local killcommand_id = 49044
local fearroar_id = 49042
local raidmembers = {}

local timer = {
    arrow = 5,
    killcommand = 10,
    fearroar = 3,
}

local icon = {
    arrow = "Spell_Fire_Fireball02",
    killcommand = "Spell_Nature_Reincarnation",
    tranq = "Ability_Druid_ChallangingRoar",
    fearroar = "Spell_Shadow_PsychicScream",
}

local color = {
    arrow = "Red",
    killcommand = "Orange",
    tranq = "White",
    fearroar = "Blue",
}

local syncName = {
    bossguid = "BossGuid"..module.revision,
    petguid = "PetGuid"..module.revision,
    arrow = "Arrow"..module.revision,
    killcommand = "KillCommand"..module.revision,
    fearroar = "FearRoar"..module.revision,
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")
    self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "OnEmote")
    self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "OnEmote")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
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
    self:ThrottleSync(20, syncName.petguid)
    self:ThrottleSync(3, syncName.arrow)
    self:ThrottleSync(3, syncName.killcommand)
    self:ThrottleSync(3, syncName.fearroar)
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
        TargetByName("Rotgrowl", true)
        local _, bg = UnitExists("target")
        if bg then self:Sync(syncName.bossguid.." "..bg) end

        TargetByName("Kodiak", true)
        local _, pg = UnitExists("target")
        if pg then self:Sync(syncName.petguid.." "..pg) end
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
    if casterGuid == rotgrowl_guid then
        if spellId == arrow_id and eventType == "START" then
            if IsRaidLeader() or IsRaidOfficer() then
                local targetname = raidmembers[targetGuid]
                self:Sync(syncName.arrow.." "..targetname)
            end
        elseif spellId == killcommand_id and eventType == "START" then
            if IsRaidLeader() or IsRaidOfficer() then
                local targetname = raidmembers[targetGuid]
                self:Sync(syncName.killcommand.." "..targetname)
            end
        end
    elseif casterGuid == kodiak_guid then
        if spellId == fearroar_id and eventType == "START" then
            self:Sync(syncName.fearroar.." "..castTime)
        end
    end
end

function module:UNIT_HEALTH(msg)
end

function module:Event(msg)
    if string.find(msg, L["trigger_arrow"]) and self.db.profile.arrow then
        self:Sync(syncName.arrow.." "..UnitName("player"))
    elseif string.find(msg, L["trigger_tranq"]) and self.db.profile.tranq then
        self:Tranq()
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:OnEmote(msg)
    if string.find(msg, L["trigger_arrow_aim"]) and self.db.profile.arrow then
        local _, _, p = string.find(msg, L["trigger_arrow_aim"])
        self:Sync(syncName.arrow.." "..p)
    elseif string.find(msg, L["trigger_kc_aim"]) and self.db.profile.killcommand then
        local _, _, p = string.find(msg, L["trigger_kc_aim"])
        self:Sync(syncName.killcommand.." "..p)
    end
end

function module:BigWigs_RecvSync(sync, rest)
    if sync == syncName.bossguid then
        rotgrowl_guid = rest
    elseif sync == syncName.petguid then
        kodiak_guid = rest
    elseif sync == syncName.arrow and self.db.profile.arrow then
        self:Arrow(rest)
    elseif sync == syncName.killcommand and self.db.profile.killcommand then
        self:KillCommand(rest)
    elseif sync == syncName.fearroar and self.db.profile.fearroar then
        self:FearRoar(rest)
    end
end

function module:RemoveCastbars()
    self:RemoveBar(L["fearroar_bar"])
end

function module:Arrow(rest)
    if IsRaidLeader() then
        SendChatMessage(L["arrow_warning_RL"]..rest, "RAID_WARNING")
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 4)
            end
        end
    end
    self:Bar(L["arrow_warning_bar"]..rest, timer.arrow, icon.arrow, true, color.arrow)
    self:Sound("Beware")
end

function module:KillCommand(rest)
    self:Bar(L["killcommand_bar"]..rest, timer.killcommand, icon.killcommand, true, color.killcommand)
    if rest == UnitName("player") then
        self:Message(L["kc_targeted"], "Urgent")
    elseif UnitClass("player") == "Paladin" or UnitClass("player") == "Priest" then
        self:Bar("> Click to target "..rest.." <", timer.killcommand, icon.killcommand, true, color.killcommand)
        self:SetCandyBarOnClick("BigWigsBar ".."> Click to target "..rest.." <", function(name, button, extra) TargetByName(extra, true) end, rest)
        self:Message(L["kc_help"], "Normal")
    end
end

function module:FearRoar(rest)
    local casttime = tonumber(rest) / 1000
    if not casttime or casttime <= timer.fearroar then casttime = timer.fearroar end
    if UnitClass("player") == "Shaman" or UnitClass("player") == "Priest" then
        self:Bar(L["fearroar_bar"], casttime, icon.fearroar, true, color.fearroar)
        self:Message(L["fearroar_help"], "Normal")
        self:Sound("Beware")
    end
end

function module:Tranq()
    if IsRaidLeader() or IsRaidOfficer() or UnitClass("player") == "Hunter" then
        self:Message(L["tranq_msg"], "Urgent")
        self:WarningSign(icon.tranq, 1)
    end
end

-- tests
SLASH_ROTGROWLTEST1 = "/rotgrowltest"
SlashCmdList["ROTGROWLTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "fearroar" then
        self:FearRoar(3000)
    elseif msg == "kc" then
        self:KillCommand(UnitName("player"))
    elseif msg == "arrow" then
        self:Arrow(UnitName("player"))
    elseif msg == "tranq" then
        self:Tranq()
    else
        print("Commands: tranq, fearroar, arrow, kc")
    end
end
