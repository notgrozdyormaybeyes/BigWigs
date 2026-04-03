local module, L = BigWigs:ModuleDeclaration("Selenaxx Foulheart", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Ursol"
module.toggleoptions = {"taint", "hptrack", "marksatyrs"}
module.zonename = "TimbermawHold"

module.defaultDB = {
    taint = true,
    hptrack = true,
    marksatyrs = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Selenaxx",
    
    taint_cmd = "TaintOfTheSatyr",
    taint_name = "Taint of the Satyr Alert",
    taint_desc = "Warn for Taint of the Satyr (only for RL & assists)",
    
    hptrack_cmd = "HPTrack",
    hptrack_name = "HP Track Alert",
    hptrack_desc = "Warn for HP",
    
    marksatyrs_cmd = "MarkSatyrs",
    marksatyrs_name = "Mark Satyr Adds Alert",
    marksatyrs_desc = "Auto marks summonned Satyr adds",
    
    trigger_taintYou = "You are afflicted by Taint of the Satyr %((.+)%).",
    trigger_taintOther = "(.+) is afflicted by Taint of the Satyr %((.+)%).",
    trigger_taintFade = "Taint of the Satyr fades from (.+).",
    msg_taintcount = "% increased damage",
    msg_manytaint = " stacks applied, consider switching tanks.",
    msg_taintfaded = "You dropped all stacks of Taint of the Satyr.",
    
    hp_warn_msg = "Adds soon, dispell tanks, Interrupt satyrs and AOE imps!",
    
    trigger_engage = "The master's plan shall not be interrupted!",
    trigger_bossDead = "My purpose, my manifestations, all brought to nothing, all brought to ruin!",
} end)

local selenaxx_guid = nil
local lowHp = 0
local healthPct = 100

local warn_taint_stacks = 20

local marked = {}
local icons = {8, 7, 6, 5, 4}
local hpPhases = {83, 63, 43, 23}
local phaseTriggered = {}

local raidmembers = {}

local timer = {
    taint = 30,
}
local icon = {
    taint = "Spell_Shadow_AuraOfDarkness",
}
local color = {
    taint = "Yellow",
}
local syncName = {
    bossguid = "BossGuid"..module.revision,
    taint = "Taint"..module.revision,
    taintFade = "TaintFade"..module.revision,
    addGUID = "AddGUID"..module.revision,
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
    self:RegisterEvent("UNIT_HEALTH")
    
    if SUPERWOW_VERSION then
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(3, syncName.taint)
    self:ThrottleSync(3, syncName.taintFade)
    self:ThrottleSync(3, syncName.addGUID)
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
    if SUPERWOW_VERSION and (IsRaidLeader() or IsRaidOfficer() or UnitClass("Player") == "Warrior") then
        TargetByName("Selenaxx Foulheart", true)
        local _, boss_guid = UnitExists("target")
        if boss_guid then
            self:Sync(syncName.bossguid.." "..boss_guid)
        end
    end
    self.healthPct = 100
    if self.db.profile.hptrack then
        self:ScheduleRepeatingEvent("CheckHp", self.CheckHp, 2, self)
    end
    if self.db.profile.marksatyrs then
        self:RegisterEvent("UNIT_TARGET")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
    if IsRaidLeader() or IsRaidOfficer() then
        for i = 1, GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
        end
    end
    self.healthPct = 100
    self:UnregisterEvent("UNIT_TARGET")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
end

function module:UNIT_HEALTH(unit)
    if unit ~= "target" then return end
    local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
    for _, threshold in ipairs(hpPhases) do
        if hp <= threshold and not phaseTriggered[threshold] then
            phaseTriggered[threshold] = true
        end
    end
end

function module:UNIT_TARGET(unit)
    self:CheckUnitTarget(unit)
end

function module:PLAYER_TARGET_CHANGED()
    self:CheckUnitTarget("player")
end

function module:Event(msg)
    if string.find(msg, L["trigger_taintYou"]) then
        local _, _, stQty = string.find(msg, L["trigger_taintYou"])
        if UnitName("target") and UnitName("targettarget") then
            if UnitName("target") == "Selenaxx Foulheart" and UnitName("targettarget") == UnitName("Player") then
                local stPlayerAndQty = UnitName("Player").." "..stQty
                self:Sync(syncName.taint.." "..stPlayerAndQty)
            end
        end
    elseif string.find(msg, L["trigger_taintOther"]) then
        local _, _, stPlayer, stQty = string.find(msg, L["trigger_taintOther"])
        local stPlayerAndQty = stPlayer.." "..stQty
        self:Sync(syncName.taint.." "..stPlayerAndQty)
    elseif string.find(msg, L["trigger_taintFade"]) then
        self:Sync(syncName.taintFade)
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:OnEmote(msg)
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bossguid then
        selenaxx_guid = rest
    elseif sync == syncName.taint and rest and self.db.profile.taint then
        self:Taint(rest)
    elseif sync == syncName.taintFade and self.db.profile.taint then
        self:TaintFade()
    elseif sync == syncName.addGUID and rest and self.db.profile.marksatyrs then
        self:TryMarkGuid(rest)
    end
end

function module:RemoveCastbars()
end

function module:Taint(rest)
    local stPlayer = strsub(rest, 0, strfind(rest, " ") - 1)
    local stQty = tonumber(strsub(rest, strfind(rest, " "), strlen(rest)))
    local currentIncrease = stQty * 10
    if IsRaidLeader() or IsRaidOfficer() or UnitName("Player") == stPlayer then
        for i = 10, 200, 10 do
            self:RemoveBar(stPlayer.." has "..i..L["msg_taintcount"])
        end
        self:Bar(stPlayer.." has "..currentIncrease..L["msg_taintcount"], timer.taint, icon.taint, true, color.taint)
        if stQty >= warn_taint_stacks then
            self:Message(stPlayer.." has "..stQty..L["msg_manytaint"], "Attention", false, nil, false)
        end
    end
end

function module:TaintFade()
    self:Message(L["msg_taintfaded"])
end

function module:CheckHp()
    local selenaxxHp
    for i = 1, GetNumRaidMembers() do
        local targetString = "raid"..i.."target"
        local targetName = UnitName(targetString)
        if targetName == "Selenaxx Foulheart" and not selenaxxHp then
            selenaxxHp = math.ceil((UnitHealth(targetString) / UnitHealthMax(targetString)) * 100)
        end
        if selenaxxHp then
            break
        end
    end
    if not selenaxxHp then return end
    if (selenaxxHp <= 83 and selenaxxHp >= 81)
        or (selenaxxHp <= 63 and selenaxxHp >= 61)
        or (selenaxxHp <= 43 and selenaxxHp >= 41)
        or (selenaxxHp <= 23 and selenaxxHp >= 21) then
        self:Message(L["hp_warn_msg"], "Attention")
        self:Sound("Beware")
        marked = {}
        icons = {8, 7, 6, 5, 4}
    end
end

function module:CheckUnitTarget(unit)
    if not self.db.profile.marksatyrs then return end
    if not SUPERWOW_VERSION then return end
    local target = unit.."target"
    local exists, guid = UnitExists(target)
    if not exists or not guid then return end
    if marked[guid] then return end
    if UnitName(target) ~= "Foulheart Warlock" then return end
    if not (IsRaidLeader() or IsRaidOfficer()) then return end
    if icons == 0 then return end
    local iconId = icons[1]
    SetRaidTarget(target, iconId)
    marked[guid] = true
    table.remove(icons, 1)
    self:Sync(syncName.addGUID.." "..guid)
end

function module:TryMarkGuid(guid)
    if marked[guid] then return end
    if not SUPERWOW_VERSION then return end
    local units = {"target", "focus", "mouseover"}
    for i = 1, GetNumRaidMembers() do
        table.insert(units, "raid"..i.."target")
    end
    for _, unit in ipairs(units) do
        local exists, uguid = UnitExists(unit)
        if exists and uguid == guid and UnitName(unit) == "Foulheart Warlock" then
            if icons == 0 then return end
            local iconId = icons[1]
            SetRaidTarget(unit, iconId)
            marked[guid] = true
            table.remove(icons, 1)
            return
        end
    end
end
