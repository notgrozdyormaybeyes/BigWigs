local module, L = BigWigs:ModuleDeclaration("Ursol", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Ursol"
module.toggleoptions = {
    "twisted", "rumble", "roar", "nightmarefire", "fiends", "mc", "immunity", "bosskill"
}
module.zonename = "Timbermaw Hold"

module.defaultDB = {
    twisted = true,
    rumble = true,
    roar = true,
    nightmarefire = true,
    fiends = true,
    mc = true,
    immunity = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Ursol",

    twisted_cmd = "TwistedLightning",
    twisted_name = "Twisted Lightning interrupt",
    twisted_desc = "Warn to interrupt Withermaw Corrupters.",

    rumble_cmd = "Rumble",
    rumble_name = "Rumble alert",
    rumble_desc = "Show cast bar and warnings for Rumble.",

    roar_cmd = "RoarOfTerror",
    roar_name = "Roar of Terror alert",
    roar_desc = "Warn for Roar of Terror and highlight shamans.",

    nightmarefire_cmd = "NightmareFire",
    nightmarefire_name = "Nightmare Fire tracking",
    nightmarefire_desc = "Track Nightmare Fire debuff on tanks.",

    fiends_cmd = "Fiends",
    fiends_name = "Nightmare Fiends",
    fiends_desc = "Track and mark Nightmare Fiends and Fixate targets.",
    
    fiend_npc_name = "Nightmare Fiend", --"Elder Mottled Boar", --
    
    
    mc_cmd = "MindControl",
    mc_name = "Possess (MC)",
    mc_desc = "Warn and mark mind controlled players.",

    immunity_cmd = "ImmunityPhase",
    immunity_name = "Immunity phase",
    immunity_desc = "Show bar for the immunity phase.",

    -- Yells
    trigger_engage = "Your foolishness knows no bounds. So be it. The nightmare will savor your souls for all eternity!",
    trigger_addSummon = "Scion of mine, come protect your progenitor!",
    trigger_fiendPhase = "Your impudence is vexing me. The desecration of my sanctum will be paid for in your blood!",
    trigger_immunity = "No!! Miserable insects like... like you...!",
    trigger_bossDead = "Oh... These verdant hills... How i have missed them...",

    -- Spells / messages
    twisted_spell = "Twisted Lightning",
    rumble_spell = "Rumble",
    roar_spell = "Roar of Terror",
    nightmarefire_spell = "Nightmare Fire",
    nightmarefire_fade = "Nightmare Fire fades from (.+)",
    fixate_spell = "Fixate",
    possess_spell = "Possess",
    trig_immunity = "You are afflicted by Presence of the Wild God",

    -- Warnings
    twisted_skull = "Interrupt SKULL!",
    twisted_cross = "Interrupt CROSS!",

    rumble_cast_rw = "STOP CASTING!",
    rumble_done_rw = "DECURSE HEALERS!",
    rumble_bar = "Silence",

    roar_rw = "Shamans use Tremor Totem!",
    roar_shaman_msg = "Roar of Terror incoming - drop Tremor Totem!",
    roar_bar = "Roar of Terror",

    fiends_rw = "Focus down adds, don't touch your crawler!",
    fiends_bar = "Nightmare Fiends",

    fixate_say_skull = "SKULL ON ME",
    fixate_say_cross = "CROSS ON ME",
    fixate_say_moon = "MOON ON ME",
    fixate_say_square = "SQUARE ON ME",
    fixate_say_triangle = "TRIANGLE ON ME",
    fixate_say_diamond = "DIAMOND ON ME",
    fixate_say_circle = "CIRCLE ON ME",
    fixate_say_star = "STAR ON ME",
    fixate_nomark = "CRAWLER ON ME",

    mc_rw = "%s is MC'd, focus %s!",
    i_am_mc = " is MC'd, HIT ME",
    immunity_bar = "Everyone immune",
    ursol_immunity_bar = "Ursol is immune",

} end)

-- Spell IDs
local SPELL_TWISTED_LIGHTNING = 37073
local SPELL_RUMBLE = 37081
local SPELL_ROAR = 37087

-- Marks:
-- 1 = Star, 2 = Circle, 3 = Diamond, 4 = Triangle, 5 = Moon, 6 = Square, 7 = Cross, 8 = Skull
-- We'll use:
-- 8 (Skull) and 7 (Cross) for Withermaw Corrupters
-- 3–8 for fiends (we'll cycle 3,4,5,6,7,8)
-- 1–2 for MC targets
local fixateTexts = {
    [8] = L["fixate_say_skull"],
    [7] = L["fixate_say_cross"],
    [6] = L["fixate_say_square"],
    [5] = L["fixate_say_moon"],
    [4] = L["fixate_say_triangle"],
    [3] = L["fixate_say_diamond"],
    [2] = L["fixate_say_circle"],
    [1] = L["fixate_say_star"],
    [0] = L["fixate_nomark"],
}

local ursol_guid = nil
local corrupter1_guid = nil
local corrupter2_guid = nil
local fiends = {}
local player_guid
local fiendGuids = {}          -- guid -> mark
local fiendMarks = {}          -- mark -> guid
local fiendWaveCount = 0
local fiendSpawnActive = false

local mcPlayers = {}           -- playerName -> mark
local nightmareFireTargets = {} -- playerName -> true

local raidGuidsToNames = {}    -- guid -> name
local raidNamesToGuids = {}    -- name -> guid

local timers = {
    rumbleCast = 3,
    roarCast = 5,
    fiendWave = 15,
    nightmareFire = 24,
    immunity = 30,
    ursol_immune = 95,
}

local icons = {
    twisted = "Spell_Nature_Lightning",
    rumble = "Spell_Nature_Earthquake",
    nightmareFire = "Spell_Fire_Immolation",
    roar = "Ability_Druid_ChallangingRoar",
    tremor = "Spell_Nature_TremorTotem",
    fiend = "Spell_Shadow_Shadowfiend",
    mc = "Spell_Shadow_ShadowWordDominate",
    immunity = "Spell_Holy_DivineIntervention",
}

local colors = {
    rumble = "Red",
    nightmareFire = "Red",
    roar = "Orange",
    fiend = "Green",
    mc = "Purple",
    immunity = "White",
}

local syncName = {
    bossGuid = "UrsolBossGuid"..module.revision,
    corrupter1 = "UrsolCorr1Guid"..module.revision,
    corrupter2 = "UrsolCorr2Guid"..module.revision,

    twisted = "UrsolTwisted"..module.revision,
    rumbleStart = "UrsolRumbleStart"..module.revision,
    rumbleEnd = "UrsolRumbleEnd"..module.revision,
    roarStart = "UrsolRoarStart"..module.revision,

    fiendSpawn = "UrsolFiendSpawn"..module.revision,
    fiendFixate = "UrsolFiendFixate"..module.revision,
    fiendDeath = "UrsolFiendDeath"..module.revision,

    nightmareFireGain = "UrsolNightmareFireGain"..module.revision,
    nightmareFireFade = "UrsolNightmareFireFade"..module.revision,

    possessGain = "UrsolPossessGain"..module.revision,
    possessFade = "UrsolPossessFade"..module.revision,

    immunityStart = "UrsolImmunityStart"..module.revision,
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "OnYell")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "OnCombatLog")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "OnCombatLog")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "OnCombatLog")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "OnCombatLog")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "OnCombatLog")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "OnCombatLog")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "OnCombatLog")


    if SUPERWOW_VERSION then
        self:RegisterEvent("UNIT_CASTEVENT", "OnCastEvent")
        _, player_guid = UnitExists("player")
        self:ScheduleRepeatingEvent("CheckFiendTargets", self.CheckTargets, 0.2, self)
    end


    self:ThrottleSync(10, syncName.bossGuid)
    self:ThrottleSync(10, syncName.corrupter1)
    self:ThrottleSync(10, syncName.corrupter2)

    self:ThrottleSync(2, syncName.twisted)
    self:ThrottleSync(2, syncName.rumbleStart)
    self:ThrottleSync(2, syncName.rumbleEnd)
    self:ThrottleSync(2, syncName.roarStart)

    --self:ThrottleSync(3, syncName.fiendSpawn)
    --self:ThrottleSync(1, syncName.fiendFixate)
    --self:ThrottleSync(1, syncName.fiendDeath)

    self:ThrottleSync(1, syncName.nightmareFireGain)
    self:ThrottleSync(1, syncName.nightmareFireFade)
    
    self:ThrottleSync(5, syncName.immunityStart)
end

function module:OnSetup()
    self.started = nil
    ursol_guid = nil
    corrupter1_guid = nil
    corrupter2_guid = nil

    fiendGuids = {}
    fiendMarks = {}
    fiendWaveCount = 0
    fiendSpawnActive = false

    mcPlayers = {}
    nightmareFireTargets = {}

    raidGuidsToNames = {}
    raidNamesToGuids = {}

    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            local unit = "raid"..i
            local _, guid = UnitExists(unit)
            local name = UnitName(unit)
            if guid and name then
                raidGuidsToNames[guid] = name
                raidNamesToGuids[name] = guid
            end
        end
    end
end

function module:OnEngage()
    if SUPERWOW_VERSION then
        self:RegisterEvent("UNIT_DIED", "OnUnitDied")
    end
    if SUPERWOW_VERSION and (IsRaidLeader() or IsRaidOfficer()) then
        -- Try to get Ursol GUID
        TargetByName("Ursol", true)
        local _, bguid = UnitExists("target")
        if bguid then
            ursol_guid = bguid
            self:Sync(syncName.bossGuid.." "..bguid)
        end

        -- Mark initial Withermaw Corrupters (Skull and Cross)
        -- handled by automarker
        -- TargetByName("Withermaw Corrupter", true)
        -- local _, guid1 = UnitExists("target")
        -- if guid1 then
        --     corrupter1_guid = guid1
        --     self:Sync(syncName.corrupter1.." "..guid1)
        --     SetRaidTarget("target", 8) -- Skull
        -- end
        -- 
        -- TargetByName("Withermaw Corrupter", true)
        -- local _, guid2 = UnitExists("target")
        -- if guid2 and guid2 ~= guid1 then
        --     corrupter2_guid = guid2
        --     self:Sync(syncName.corrupter2.." "..guid2)
        --     SetRaidTarget("target", 7) -- Cross
        -- end
        for i=1,GetNumRaidMembers() do
            local _, thisPlayerGuid = UnitExists("raid"..i)
            raidmembers[thisPlayerGuid] = UnitName("raid"..i) 
            if corrupter1_guid == nil and GetRaidTargetIndex("raid"..i.."target") == 8 then
                local _, guid1 = UnitExists("raid"..i.."target")
                corrupter1_guid = guid1
            end
            if corrupter2_guid == nil and GetRaidTargetIndex("raid"..i.."target") == 7 then
                local _, guid2 = UnitExists("raid"..i.."target")
                corrupter2_guid = guid2
            end
        end

        ClearTarget()
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
    fiendSpawnActive = false
end

------------------------------------------------
-- Events
------------------------------------------------

function module:OnYell(msg)
    if string.find(msg, L["trigger_engage"]) then
        -- handled by RegisterYellEngage
    elseif string.find(msg, L["trigger_addSummon"]) then
        -- Boss summons a Withermaw Corrupter
        if SUPERWOW_VERSION and (IsRaidLeader() or IsRaidOfficer()) then
            self:ScheduleEvent("UrsolScanNewCorrupter", self.ScanNewCorrupter, 0.5, self)
        end
    elseif string.find(msg, L["trigger_fiendPhase"]) then
        -- Start fiend phase
        fiendSpawnActive = true
        fiendWaveCount = 0
        self:Sync(syncName.fiendSpawn.." start")
        if self.db.profile.fiends then
            if IsRaidLeader() then
                SendChatMessage(L["fiends_rw"], "RAID_WARNING")
            end
            self:Bar(L["fiends_bar"], timers.fiendWave, icons.fiend, true, colors.fiend)
        end
        self:ScheduleRepeatingEvent("UrsolFiendWaveTimer", self.FiendWave, timers.fiendWave, self)
    elseif string.find(msg, L["trigger_immunity"]) then
        self:Sync(syncName.immunityStart)
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:OnCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    local _, source = UnitExists(casterGuid)
    if not source then return end

    if UnitName(source) == L["fiend_npc_name"] and not fiends[source] then
        fiends[source] = {}
    end
    if eventType ~= "START" then return end

    if spellId == SPELL_TWISTED_LIGHTNING then
        self:Sync(syncName.twisted.." "..casterGuid)
    elseif spellId == SPELL_RUMBLE then
        self:Sync(syncName.rumbleStart.." "..castTime)
    elseif spellId == SPELL_ROAR then
        self:Sync(syncName.roarStart.." "..castTime)
    end
end

function module:OnCombatLog(msg)
    if type(msg) ~= "string" then return end
    if string.find(msg, " ") then
        -- Nightmare Fire gain
        if string.find(msg, L["nightmarefire_spell"]) and string.find(msg, "afflicted by") then
            local _, _, player = string.find(msg, "^(.+) is afflicted by " .. L["nightmarefire_spell"])
            if player then
                self:Sync(syncName.nightmareFireGain .. " " .. player)
            end
            return
        end
        -- Nightmare Fire fade
        local _, _, fadeTarget = string.find(msg, L["nightmarefire_fade"])
        if fadeTarget then
            self:Sync(syncName.nightmareFireFade .. " " .. fadeTarget)
            return
        end
        -- Fixate gain
        if string.find(msg, L["fixate_spell"]) and string.find(msg, "afflicted by") then
            local _, _, player = string.find(msg, "^(.+) is afflicted by " .. L["fixate_spell"])
            if player then
                self:Sync(syncName.fiendFixate .. " " .. player)
            end
            return
        end
        -- Possess gain
        if string.find(msg, L["possess_spell"]) and string.find(msg, "afflicted by") then
            local _, _, player = string.find(msg, "^(.+) is afflicted by " .. L["possess_spell"])
            local _, _, playerme = string.find(msg, "^(.+) are afflicted by " .. L["possess_spell"])
            if player then
                self:Sync(syncName.possessGain .. " " .. player)
            elseif playerme == "You" then
                self:Sync(syncName.possessGain .. " " .. UnitName("player"))
            end
            return
        end
        -- Possess fade
        if string.find(msg, L["possess_spell"]) and string.find(msg, "fades from") then
            local _, _, player = string.find(msg, L["possess_spell"] .. " fades from (.+)")
            if player then
                self:Sync(syncName.possessFade .. " " .. player)
            end
            return
        end
        -- Immune phase
        if string.find(msg, L["trig_immunity"]) then
            self:Sync(syncName.immunityStart)
            return
        end
    end
end


function module:OnUnitDied(guid)
    if fiendGuids[guid] then
        self:Sync(syncName.fiendDeath.." "..guid)
    end
end

------------------------------------------------
-- Sync handling
------------------------------------------------

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bossGuid then
        ursol_guid = rest

    elseif sync == syncName.corrupter1 then
        corrupter1_guid = rest

    elseif sync == syncName.corrupter2 then
        corrupter2_guid = rest

    elseif sync == syncName.twisted and self.db.profile.twisted then
        self:HandleTwisted(rest)

    elseif sync == syncName.rumbleStart and self.db.profile.rumble then
        self:HandleRumbleStart(rest)

    elseif sync == syncName.rumbleEnd and self.db.profile.rumble then
        -- Not used explicitly here, but kept for extensibility

    elseif sync == syncName.roarStart and self.db.profile.roar then
        self:HandleRoarStart(rest)

    elseif sync == syncName.fiendSpawn and self.db.profile.fiends then
        -- rest can be "start" or wave number, but we handle locally via FiendWave()
        

    elseif sync == syncName.fiendFixate and self.db.profile.fiends then
        self:HandleFiendFixate(rest)
    
    elseif sync == syncName.nightmareFireGain and self.db.profile.nightmarefire then
        self:HandleNightmareFireGain(rest)
    
    elseif sync == syncName.nightmareFireFade and self.db.profile.nightmarefire then
        self:HandleNightmareFireFade(rest)

    elseif sync == syncName.possessGain and self.db.profile.mc then
        self:HandlePossessGain(rest)

    elseif sync == syncName.possessFade and self.db.profile.mc then
        self:HandlePossessFade(rest)

    elseif sync == syncName.immunityStart and self.db.profile.immunity then
        self:HandleImmunityStart()
    end
end

------------------------------------------------
-- Corrupters / Twisted Lightning
------------------------------------------------

function module:ScanNewCorrupter()
    if not (IsRaidLeader() or IsRaidOfficer()) then return end

    for _, frame in ipairs({WorldFrame:GetChildren()}) do
        if frame.GetName and frame:GetName() then
            local guid = frame:GetName(1)
            if guid then
                local name = UnitName(guid)
                if name == "Withermaw Corrupter" then
                    if not corrupter1_guid then
                        corrupter1_guid = guid
                        self:Sync(syncName.corrupter1.." "..guid)
                        SetRaidTarget(guid, 8, true)
                    elseif not corrupter2_guid and guid ~= corrupter1_guid then
                        corrupter2_guid = guid
                        self:Sync(syncName.corrupter2.." "..guid)
                        SetRaidTarget(guid, 7, true)
                    end
                end
            end
        end
    end
end

function module:HandleTwisted(casterGuid)
    if not casterGuid then return end

    local markText = nil
    if casterGuid == corrupter1_guid then
        markText = "SKULL"
        if IsRaidLeader() then
            SendChatMessage(L["twisted_skull"], "RAID_WARNING")
        end
        self:Message(L["twisted_skull"], "Urgent")
    elseif casterGuid == corrupter2_guid then
        markText = "CROSS"
        if IsRaidLeader() then
            SendChatMessage(L["twisted_cross"], "RAID_WARNING")
        end
        self:Message(L["twisted_cross"], "Urgent")
    else
        -- Could be a newly summoned corrupter not yet mapped; ignore or extend logic
        self:Message("Interrupt corrupter!", "Urgent")
    end

    self:Sound("Beware")
end

------------------------------------------------
-- Rumble
------------------------------------------------

function module:HandleRumbleStart(castTimeMs)
    local castTime = tonumber(castTimeMs) and tonumber(castTimeMs) / 1000 or timers.rumbleCast

    if IsRaidLeader() then
        SendChatMessage(L["rumble_cast_rw"], "RAID_WARNING")
    end
    self:Message(L["rumble_cast_rw"], "Important")
    self:Sound("Beware")

    self:Bar(L["rumble_bar"], castTime, icons.rumble, true, colors.rumble)

    -- After cast finishes, send decurse warning
    self:ScheduleEvent("UrsolRumbleDone", function()
        if IsRaidLeader() then
            SendChatMessage(L["rumble_done_rw"], "RAID_WARNING")
        end
        self:Message(L["rumble_done_rw"], "Attention")
    end, castTime)
end

------------------------------------------------
-- Roar of Terror
------------------------------------------------

function module:HandleRoarStart(castTimeMs)
    local castTime = tonumber(castTimeMs) and tonumber(castTimeMs) / 1000 or timers.roarCast

    if IsRaidLeader() then
        SendChatMessage(L["roar_rw"], "RAID_WARNING")
    end
    self:Message(L["roar_rw"], "Important")
    self:Bar(L["roar_bar"], castTime, icons.roar, true, colors.roar)

    -- Extra visual + sound for shamans
    local _, class = UnitClass("player")
    if class == "SHAMAN" then
        self:Message(L["roar_shaman_msg"], "Attention", false, nil, true)
        self:Sound("Alert")
        -- Optional: local bar/icon just for shamans
        self:Bar(L["roar_bar"], castTime, icons.tremor, true, colors.roar)
    end
end

------------------------------------------------
-- Nightmare Fire tracking
------------------------------------------------

function module:HandleNightmareFireGain(player)
    nightmareFireTargets[player] = GetTime() + timers.nightmareFire

    if IsRaidLeader() or IsRaidOfficer() then
        self:Message("Nightmare Fire on "..player, "Important")
    end

    self:Bar("Nightmare Fire: "..player, timers.nightmareFire, icons.nightmareFire, true, colors.nightmareFire)
end

function module:HandleNightmareFireFade(player)
    nightmareFireTargets[player] = nil

    if IsRaidLeader() or IsRaidOfficer() then
        self:Message("Nightmare Fire faded from "..player, "Positive")
    end

end


------------------------------------------------
-- Fiends / Fixate / waves
------------------------------------------------


function module:FiendWave()
    if not fiendSpawnActive then return end

    fiendWaveCount = fiendWaveCount + 1

    if IsRaidLeader() then
        SendChatMessage(L["fiends_rw"], "RAID_WARNING")
    end

    if self.db.profile.fiends then
        self:Bar(L["fiends_bar"], timers.fiendWave, icons.fiend, true, colors.fiend)
    end

end

function module:HandleFiendFixate(player)
    if not player then return end

    if UnitName("player") ~= player then return end

    local correctMark = nil
    
    local _, myGUID = UnitExists("player")
    
    
    for i = 1, GetNumRaidMembers() do
        GetRaidTargetIndex("raid"..i.."target")
        if UnitName("raid"..i.."targettarget") == UnitName("player") then
            correctMark = GetRaidTargetIndex("raid"..i.."target")
            local sayText = fixateTexts[correctMark] or "CRAWLER ON ME"
            SendChatMessage(sayText, "SAY")
        end
    end

end


function module:CheckTargets()
    for guid, data in pairs(fiends) do
        local _, target = UnitExists(guid.."target")
        if target == player_guid and not data.warned then
            data.warned = true
            local numMark = GetRaidTargetIndex(guid)
            local sayText = fixateTexts[numMark] or L["fixate_nomark"]
            local first = string.match(sayText, "^(%S+)")
            SendChatMessage(sayText, "SAY")
            self:Message(first.." is targeting YOU!", "Important", true, "Alarm")
        end
    end
end

------------------------------------------------
-- Possess (MC)
------------------------------------------------

local mcMarks = {1, 2}

local function GetFreeMcMark()
    for _, mark in ipairs(mcMarks) do
        local used = false
        for _, m in pairs(mcPlayers) do
            if m == mark then
                used = true
                break
            end
        end
        if not used then
            return mark
        end
    end
    return nil
end

function module:HandlePossessGain(player)
    if not player then return end

    local mark = GetFreeMcMark() or 1
    mcPlayers[player] = mark

    if IsRaidLeader() then
        local markName = (mark == 1 and "STAR") or (mark == 2 and "CIRCLE") or "MARK"
        local msg = string.format(L["mc_rw"], player, markName)
        SendChatMessage(msg, "RAID_WARNING")
    end

    self:Message(player.." is mind controlled!", "Important")
    self:Sound("Beware")
    
    if UnitName("player") == player then
        SendChatMessage(player..L["i_am_mc"], "SAY")
    end
    
    if IsRaidLeader() or IsRaidOfficer() then
        -- Try to mark the player
        for i = 1, GetNumRaidMembers() do
            local unit = "raid"..i
            if UnitName(unit) == player then
                SetRaidTarget(unit, mark)
                break
            end
        end
    end
end

function module:HandlePossessFade(player)
    if not player then return end

    local mark = mcPlayers[player]
    if mark then
        mcPlayers[player] = nil
        if (IsRaidLeader() or IsRaidOfficer()) then
            for i = 1, GetNumRaidMembers() do
                local unit = "raid"..i
                if UnitName(unit) == player then
                    SetRaidTarget(unit, 0)
                    break
                end
            end
        end
    end
end

------------------------------------------------
-- Immunity phase
------------------------------------------------

function module:HandleImmunityStart()
    self:Message("Everyone is immune for 30 seconds!", "Positive")
    -- Stop fiends
    fiendSpawnActive = false
    self:CancelScheduledEvent("UrsolFiendWaveTimer")
    -- Remove bars
    self:RemoveBar(L["fiends_bar"])
    self:RemoveBar(L["rumble_bar"])
    self:RemoveBar(L["roar_bar"])
    -- Add immunity bars
    self:Bar(L["immunity_bar"], timers.immunity, icons.immunity, true, colors.immunity)
    self:Bar(L["ursol_immunity_bar"], timers.ursol_immune + timers.immunity, icons.immunity, true, colors.immunity)
end


-- tests
SLASH_URSOLTEST1 = "/ursoltest"
SlashCmdList["URSOLTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "twisted" then
        self:HandleTwisted(corrupter1_guid or "FAKEGUID1")
    elseif msg == "rumble" then
        self:HandleRumbleStart(3000)
    elseif msg == "roar" then
        self:HandleRoarStart(5000)
    elseif msg == "nf" then
        self:HandleNightmareFireGain("Player")
    elseif msg == "fiend" then
        self:HandleFiendFixate(UnitName("player"))
    elseif msg == "mc" then
        self:HandlePossessGain(UnitName("player"))
    elseif msg == "immune" then
        self:HandleImmunityStart()
    else
        print("Commands: twisted, rumble, roar, nf, fiend, mc, immune")
    end
end
