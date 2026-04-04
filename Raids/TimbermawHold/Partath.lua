
local module, L = BigWigs:ModuleDeclaration("Chieftain Partath", "Timbermaw Hold")


module.revision = 30020
module.enabletrigger = "Chieftain Partath"
module.toggleoptions = {"bubble", "ritual", "interrupt"}
module.zonename = "TimbermawHold"


module.defaultDB = {
    bubble = true,
    ritual = true,
    interrupt = true,
}
L:RegisterTranslations("enUS", function() return {
    cmd = "Partath",
    
    bubble_cmd = "Bubble",
    bubble_name = "Bubble Alert",
    bubble_desc = "Warn for Bubble",
        
    ritual_cmd = "Ritual",
    ritual_name = "Ritual Alert",
    ritual_desc = "Warn for Ritual",
        
    interrupt_cmd = "Interrupt",
    interrupt_name = "Interrupt Alert",
    interrupt_desc = "Warn for Interrupt",
        
    ritual_msg = "Adds incoming, cleave them!",
    ritual_bar = "Summoning adds",
    
    bubble_warn = "Partath will soon be immune, bring both adds to him!",
    bubble_bar = "Partath immune",
    bubble_fade = "Shade of the Withermaw fades from Chieftain Partath",
    
    trigger_engage = "You think you can walk through my halls unopposed? So bold of you to bring yourself to me.",--CHAT_MSG_MONSTER_YELL
    trigger_bossDead = "Darkness, the smell of death...",
} end )

local chieftain_guid = nil -- will be synced in OnEngage()
local add1_guid = nil
local add2_guid = nil
local rejuv_id = 34753
local ritual_id = 34742
local lowHp = 0
local healthPct = 100

local bubble_times_counter = 0

local raidmembers  = {}

local timer = {
    bubble = 50, -- -10s each time??
    bubble_warn = 2,
    ritual = 3,
}
local icon = {
    bubble = "Spell_Holy_DivineIntervention",
    ritual = "Ability_Racial_BearForm",
}
local color = {
    bubble = "Pink",
    ritual = "Orange",
}
local syncName = {
    bossguid = "BossGuid"..module.revision,
    add1 = "Add1Guid"..module.revision,
    add2 = "Add2Guid"..module.revision,
    ritual = "SummonRitual"..module.revision,
    interrupt = "Interrupt"..module.revision,
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event") --trigger_engage
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") 
    
    if SUPERWOW_VERSION then -- check if SuperWoW is used. if not, pray that someone has it to sync with you :)
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(20, syncName.add1)
    self:ThrottleSync(20, syncName.add2)
    self:ThrottleSync(3, syncName.ritual)
    self:ThrottleSync(3, syncName.interrupt)
    
end

function module:OnSetup()
    self.started = nil
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            local _, thisPlayerGuid = UnitExists("raid"..i)
            raidmembers[thisPlayerGuid] = UnitName("raid"..i) 
        end
    end
end

function module:OnEngage()
    if SUPERWOW_VERSION and (IsRaidLeader() or IsRaidOfficer()) then
        TargetByName("Chieftain Partath", true)
        local _, guid = UnitExists("target")
        if guid then
            self:Sync(syncName.bossguid.." "..guid)
        end
        
        TargetByName("Withermaw Illuminator", true)
        local _, guid1 = UnitExists("target")
        if guid1 then
            self:Sync(syncName.add1.." "..guid1)
            SetRaidTarget("target", 8)
        end

        TargetByName("Withermaw Illuminator", true) -- TargetNearestEnemy()
        local _, guid2 = UnitExists("target")
        if guid2 and guid2 ~= guid1 then
            self:Sync(syncName.add2.." "..guid2)
            SetRaidTarget("target", 7)
        end
    end
    bubble_times_counter = 0
    if self.db.profile.bubble then
        self:Bubble()
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
    bubble_times_counter = 0
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
        end
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == chieftain_guid and eventType == "START" then
        if spellId == ritual_id then
            self:Sync(syncName.ritual.." "..castTime)
        end
    elseif casterGuid == add1_guid or casterGuid == add2_guid then
        if eventType == "START" and spellId == rejuv_id then
            self:Sync(syncName.interrupt.." "..casterGuid)
        end
    end
end

function module:Event(msg)
    if string.find(msg, L["bubble_fade"]) and self.db.profile.bubble then
        self:Bubble()
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.bossguid then
        chieftain_guid = rest
    elseif sync == syncName.add1 then
        add1_guid = rest
    elseif sync == syncName.add2 then
        add2_guid = rest
    elseif sync == syncName.ritual then
        self:Ritual(rest)
    elseif sync == syncName.interrupt then
        self:InterruptCall(rest)
    end
end

function module:Ritual(rest)
    local casttime = tonumber(rest) / 1000
    if not casttime or casttime <= timer.ritual then
        casttime = timer.ritual
    end
    self:Bar(L["ritual_bar"], casttime, icon.ritual, true, color.ritual)
    self:Sound("Beware")
    if IsRaidLeader() then
        SendChatMessage(L["ritual_msg"], "RAID_WARNING")
    end
end

function module:InterruptCall(guid)
    if not self.lastInterrupt or GetTime() - self.lastInterrupt > 2 then
        self.lastInterrupt = GetTime()
        if guid == add1_guid then
            if (IsRaidLeader() ) then
                SendChatMessage("Interrupt SKULL!", "RAID_WARNING")
            end
            self:Message("Interrupt SKULL!", "Urgent")
            self:Sound("Beware")
        elseif guid == add2_guid then
            if (IsRaidLeader() ) then
                SendChatMessage("Interrupt CROSS!", "RAID_WARNING")
            end
            self:Message("Interrupt CROSS!", "Urgent")
            self:Sound("Beware")
        end
    end
end

function module:Bubble()
    local duration = timer.bubble - bubble_times_counter*10
    if duration < 5 then duration = 5 end
    self:Bar(L["bubble_bar"], duration, icon.bubble, true, color.bubble)
    self:DelayedMessage(duration - timer.bubble_warn, L["bubble_warn"], "Attention")
    bubble_times_counter = bubble_times_counter + 1
end

-- tests
SLASH_PARTATHTEST1 = "/partathtest"
SlashCmdList["PARTATHTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "interrupt" then
        self:InterruptCall(corrupter1_guid or "FAKEGUID1")
    elseif msg == "bubble" then
        self:Bubble()
    elseif msg == "ritual" then
        self:Ritual(6000)
    else
        print("Commands: interrupt, bubble, ritual")
    end
end
