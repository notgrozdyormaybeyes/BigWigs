local module, L = BigWigs:ModuleDeclaration("Archdruid Kronn", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Archdruid Kronn"
module.toggleoptions = {"reform", "hpframe", "corruption"}
module.zonename = "TimbermawHold"

module.defaultDB = {
    reform = true,
    hpframe = true,
    corruption = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Kronn",
    
    reform_cmd = "Reform",
    reform_name = "Reform Alert",
    reform_desc = "Warn for Reform",
    
    hpframe_cmd = "hpframe",
    hpframe_name = "Boss HP Frame",
    hpframe_desc = "Shows a frame with the bosses' HP",
    
    corruption_cmd = "Corruption",
    corruption_name = "Corruption Alert",
    corruption_desc = "Warn for Corruption",
    
    reform_bar = "Bad side reforming",
    
    hp_msg_bad_slowdown = "Slow down on Bad side DPS, heal Good side",
    hp_msg_good_high = "Prepare to kill Bad side, Good side HP over 95%",
    hp_msg_bad_low = "Bad side HP under 5%, keep healing Good side",
    hp_msg_bad_dead = "Bad side dying, keep healing Good side",
    hp_msg_bad_reform = "Bad side rezzing, keep healing Good side",
    
    trigger_corruptionYou = "You are afflicted by Dream Fever",
    trigger_corruptionOther = "(.+) is afflicted by Dream Fever",
    trigger_corruptionFade = "Dream Fever fades from (.+).",
    bar_corruption = " is Poisoned!",
    msg_corruptionYou = "You are Poisoned! Move away from your friends!",
    
    trigger_engage = "Outsiders... you will go no further.",
    trigger_reform = "It changes... nothing...",
    trigger_bossDead = "The whispers... finally... quiet...",
} end)

local bad_guid = nil
local good_guid = nil
local raidmembers = {}

local timer = {
    reform = 10,
    corruption = 60,
}
local icon = {
    reform = "Spell_Holy_FlashHeal",
    corruption = "Spell_Shadow_PlagueCloud",
}
local color = {
    reform = "Blue",
    corruption = "Cyan",
}
local syncName = {
    bad_guid = "BadGuid"..module.revision,
    good_guid = "GoodGuid"..module.revision,
    hpBad = "KronnBadHP"..module.revision,
    hpGood = "KronnGoodHP"..module.revision,
    reform = "Reform"..module.revision,
    corruption = "Corruption"..module.revision,
    corruptionFade = "CorruptionFade"..module.revision,
}

module.proximityCheck = function(unit)
    return CheckInteractDistance(unit, 2)
end
module.proximitySilent = true

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
    
    self.badHp = 100
    self.goodHp = 10
    
    self:ThrottleSync(20, syncName.bad_guid)
    self:ThrottleSync(20, syncName.good_guid)
    self:ThrottleSync(1, syncName.hpBad)
    self:ThrottleSync(1, syncName.hpGood)
    self:ThrottleSync(3, syncName.reform)
    self:ThrottleSync(3, syncName.corruption)
    self:ThrottleSync(3, syncName.corruptionFade)
    
    self:UpdateBossStatusFrame()
end

function module:OnSetup()
    self.started = nil
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            local _, thisPlayerGuid = UnitExists("raid"..i)
            raidmembers[thisPlayerGuid] = UnitName("raid"..i)
        end
    end
end

function module:OnEngage()
    if SUPERWOW_VERSION then
        self:ScheduleRepeatingEvent("ScanKronnBosses", self.ScanBossGuids, 0.5, self)
    end
    self:Proximity()
    if self.db.profile.hpframe then
        self:ScheduleRepeatingEvent("CheckHps", self.CheckHps, 2, self)
    end
end

function module:ScanBossGuids()
    if bad_guid and good_guid then
        self:CancelScheduledEvent("ScanKronnBosses")
        return
    end

    for _, frame in ipairs({WorldFrame:GetChildren()}) do
        if frame.GetName and frame:GetName() then
            local guid = frame:GetName(1)
            if guid then
                local name = UnitName(guid)
                if name == "Archdruid Kronn" and not bad_guid then
                    bad_guid = guid
                    self:Sync(syncName.bad_guid.." "..guid)
                elseif name == "Dreamform of Kronn" and not good_guid then
                    good_guid = guid
                    self:Sync(syncName.good_guid.." "..guid)
                end
            end
        end
    end
end


function module:OnDisengage()
    self:CancelAllScheduledEvents()
    self:RemoveProximity()
    self.badHp = 100
    self.goodHp = 10
    if self.bossStatusFrame then
        self.bossStatusFrame:Hide()
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
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
    elseif string.find(msg, L["trigger_reform"]) and self.db.profile.reform then
        self:Sync(syncName.reform)
    elseif msg == L["trigger_engage"] then
        if not self.started then
            self.started = true
            self:SendEngageSync()
        end
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:OnEmote(msg)
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bad_guid then
        bad_guid = rest
    elseif sync == syncName.good_guid then
        good_guid = rest
    elseif sync == syncName.reform and self.db.profile.reform then
        self:Reform()
    elseif sync == syncName.corruption and rest and self.db.profile.corruption then
        self:Corruption(rest)
    elseif sync == syncName.corruptionFade and rest and self.db.profile.corruption then
        self:CorruptionFade(rest)
    elseif sync == syncName.hpBad then
        local hp = tonumber(rest)
        if hp then
            self.badHp = hp
            self:UpdateBossStatusFrame()
        end
    elseif sync == syncName.hpGood then
        local hp = tonumber(rest)
        if hp then
            self.goodHp = hp
            self:UpdateBossStatusFrame()
        end
    end
end

function module:RemoveCastbars()
end

function module:Reform()
    if IsRaidLeader() then
        SendChatMessage(L["hp_msg_bad_reform"], "RAID_WARNING")
    end
    self:Bar(L["reform_bar"], timer.reform, icon.reform, true, color.reform)

    self.badHp = 30
    self:ScheduleEvent("RescanKronnHP", function()
        self:CheckHps()
    end, 1)
end


local lastWarn = 0

function module:UpdateBossStatusFrame()
    if not self.db.profile.hpframe then
        return
    end

    if not self.bossStatusFrame then
        self.bossStatusFrame = CreateFrame("Frame", "KronnFrame", UIParent)
        self.bossStatusFrame:SetWidth(160)
        self.bossStatusFrame:SetHeight(50)
        self.bossStatusFrame:ClearAllPoints()
        self.bossStatusFrame:SetPoint("CENTER", UIParent, "CENTER", -480, 200)
        self.bossStatusFrame:EnableMouse(true)
        self.bossStatusFrame:SetMovable(true)
        self.bossStatusFrame:RegisterForDrag("LeftButton")
        self.bossStatusFrame:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
        self.bossStatusFrame:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
        self.bossStatusFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        self.bossStatusFrame:SetBackdropColor(0, 0, 0, 1)
        local font = "Fonts\\FRIZQT__.TTF"
        self.bossStatusFrame.bad = self.bossStatusFrame:CreateFontString(nil, "ARTWORK")
        self.bossStatusFrame.bad:SetFont(font, 11)
        self.bossStatusFrame.bad:SetPoint("TOPLEFT", self.bossStatusFrame, "TOPLEFT", 10, -10)
        self.bossStatusFrame.good = self.bossStatusFrame:CreateFontString(nil, "ARTWORK")
        self.bossStatusFrame.good:SetFont(font, 11)
        self.bossStatusFrame.good:SetPoint("TOPLEFT", self.bossStatusFrame, "TOPLEFT", 10, -28)
    end
    if not bad_guid or not good_guid then
        self.bossStatusFrame:Hide()
        return
    end
    self.bossStatusFrame:Show()
    self.bossStatusFrame.bad:SetText("BAD:   "..self.badHp.."%")
    self.bossStatusFrame.good:SetText("GOOD:  "..self.goodHp.."%")
    

    if GetTime() - lastWarn < 5 then return end -- cooldown 5s
    lastWarn = GetTime()
    
    if IsRaidLeader() then
        if self.badHp <= 25 and self.goodHp <= 80 then
            SendChatMessage(L["hp_msg_bad_slowdown"], "RAID_WARNING")
        elseif self.badHp <= 2 and self.goodHp >= 95 then
            SendChatMessage(L["hp_msg_bad_dead"], "RAID_WARNING")
        elseif self.badHp <= 5 then
            SendChatMessage(L["hp_msg_bad_low"], "RAID_WARNING")
        elseif self.goodHp >= 95 then
            SendChatMessage(L["hp_msg_good_high"], "RAID_WARNING")
        end
    end
end

---function module:CheckHps()
---    local meanHp, niceHp
---
---    for i = 1, GetNumRaidMembers() do
---        local unit = "raid"..i.."target"
---        local _, guid = UnitExists(unit)
---
---        if guid then
---            if guid == bad_guid and not meanHp then
---                meanHp = math.ceil(UnitHealth(unit) / UnitHealthMax(unit) * 100)
---            elseif guid == good_guid and not niceHp then
---                niceHp = math.ceil(UnitHealth(unit) / UnitHealthMax(unit) * 100)
---            end
---        end
---
---        if meanHp and niceHp then break end
---    end
---
---    if meanHp then self.badHp = meanHp end
---    if niceHp then self.goodHp = niceHp end
---
---    self:UpdateBossStatusFrame()
---end

function module:CheckHps()
    local meanHp, niceHp

    -- Scan nameplates (SuperWoW)
    for _, frame in ipairs({WorldFrame:GetChildren()}) do
        if frame.GetName and frame:GetName() then
            local guid = frame:GetName(1)
            if guid then
                if guid == bad_guid then
                    meanHp = math.ceil(UnitHealth(guid) / UnitHealthMax(guid) * 100)
                elseif guid == good_guid then
                    niceHp = math.ceil(UnitHealth(guid) / UnitHealthMax(guid) * 100)
                end
            end
        end
    end

    if meanHp then self.badHp = meanHp end
    if niceHp then self.goodHp = niceHp end
    if meanHp then
        self:Sync(syncName.hpBad.." "..meanHp)
    end

    if niceHp then
        self:Sync(syncName.hpGood.." "..niceHp)
    end

    self:UpdateBossStatusFrame()
end



function module:Corruption(rest)
    self:Bar(rest..L["bar_corruption"], timer.corruption, icon.corruption, true, color.corruption)
    if rest == UnitName("player") then
        SendChatMessage(UnitName("player").." is Poisoned!", "SAY")
        self:Message(L["msg_corruptionYou"], "Urgent")
        self:WarningSign(icon.corruption, timer.corruption)
        self:Sound("RunAway")
    end
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 4)
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
SLASH_KRONNTEST1 = "/kronntest"
SlashCmdList["KRONNTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "corruption" then
        self:Corruption(UnitName("player"))
    elseif msg == "hp" then
        self.goodHp = 69
        self.badHp = 22
        self:CheckHps()
    elseif msg == "reform" then
        self:Reform()
    else
        print("Commands: corruption, hp, reform")
    end
end
