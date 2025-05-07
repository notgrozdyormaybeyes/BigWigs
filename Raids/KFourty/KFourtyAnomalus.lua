
local module, L = BigWigs:ModuleDeclaration("Anomalus", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"strikes", "bomb", "circle", "dampening", "usepoticon", "usepotsound", "bosskill"}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

module.defaultDB = {
    strikes = true,
    bomb = true,
    circle = true,
    dampening = true,
    usepoticon = false,
    usepotsound = false,
}
L:RegisterTranslations("enUS", function() return {
    cmd = "Anomalus",

    strikes_cmd = "ManaboundStrikes",
    strikes_name = "Manabound Strikes Alert",
    strikes_desc = "Warn for Manabound Strikes (only for RL & assists)",
    
    bomb_cmd = "ArcaneOverload",
    bomb_name = "Arcane Overload Alert",
    bomb_desc = "Warn for Arcane Overload",
    
    circle_cmd = "UnstableMagic",
    circle_name = "Unstable Magic Alert",
    circle_desc = "Warn for Unstable Magic",
    
    dampening_cmd = "ArcaneDampening",
    dampening_name = "Arcane Dampening Alert",
    dampening_desc = "Warn for Arcane Dampening",
    
    usepoticon_cmd = "UsePotionIcon",
    usepoticon_name = "Use arcane protection potion icon Alert",
    usepoticon_desc = "Warn for use arcane protection potion icon every 2 min",
    
    usepotsound_cmd = "UsePotionSound",
    usepotsound_name = "Use arcane protection potion sound Alert",
    usepotsound_desc = "Warn for use arcane protection potion sound every 2 min",
    
    msg_engage = "Hoping everyone has 230+ AR :)",
    
    trigger_strikesYou = "You are afflicted by Manabound Strikes %((.+)%).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_strikesOther = "(.+) is afflicted by Manabound Strikes %((.+)%).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE // CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
    trigger_strikesFade = "Manabound Strikes fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
    msg_strikescount = "% increased damage from Arcane Claws",
    msg_manystrikes = " strikes applied, consider switching tanks.",
    msg_strikesfaded = "You dropped all stacks of Manabound Strikes.",
    
    trigger_bombYou = "You are afflicted by Arcane Overload ", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_bombOther = "(.+) is afflicted by Arcane Overload ", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
    trigger_bombFade = "Arcane Overload fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
    bar_nextbomb = "Next bomb",
    bar_bomb = " Bomb!",
    msg_bomb = " is the Bomb!",
    
    bar_circle = "Next circle",
    active_circle = "Circle blow up",
    
    trigger_dampening = "You are afflicted by Arcane Dampening (1).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_dampeningFade = "Arcane Dampening fades from you.", --CHAT_MSG_SPELL_AURA_GONE_SELF 
    msg_dampening = "You have Arcane Damepening! Go to the circle alone!",
    msg_dampeningFade = "Arcane Damepening faded! Don't go to the circle!",
    
    msg_usepot = "Use GAPP",
    
    soundarcanepot0 = "Interface\\Addons\\BigWigs\\Sounds\\arcane_potion.wav",
    soundarcanepot1 = "Interface\\Addons\\BigWigs\\Sounds\\arcane-pot.mp3",
    soundarcanepot3 = "Interface\\Addons\\BigWigs\\Sounds\\arcane_potion3.wav",
    
    trigger_engage = "Power Overwhelming.", --CHAT_MSG_MONSTER_YELL
    trigger_bossDead = "Release...", --CHAT_MSG_MONSTER_YELL
    
} end )

local warn_strikes_stacks = 10 -- 10 stacks but can be changed
local last_tank_strikes = ""
local usepotcounter = 0
local pot_ontimer = false

local timer = {
    strikes = 60,
    firstbomb = 7,
    nextbomb = 15,
    bomb = 15, 
    firstcircle = 24,
    nextcircle = 22, -- not yet used
    circle = 8,
    usepot = 120,
    usepotsound_pre = 2,
    usepoticon = 10,
}
local icon = {
    strikes = "Ability_GhoulFrenzy",
    bomb = "Spell_Shadow_MindBomb",
    circle = "INV_Jewelry_Ring_03",
    usepot = "INV_Potion_102", 
}
local color = {
    strikes = "White",
    bomb = "Cyan",
    circle = "Purple",
}
local syncName = {
    strikes = "ManaboundStrikes"..module.revision,
    strikesFade = "ManaboundStrikesFade"..module.revision,
    bomb = "Bomb"..module.revision,
    bombFade = "BombFade"..module.revision,
    dampening = "ArcaneDampening"..module.revision,
    dampeningFade = "ArcaneDampeningFade"..module.revision,
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event") --trigger_engage
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_strikesYou, bombYou, dampening
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") --trigger_strikesOther, bombOther 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") --trigger_strikesOther, bombOther 
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") --trigger_strikesFade, bombFade, dampeningFade
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") --trigger_strikesFade, bombFade
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") --trigger_strikesFade, bombFade
    
    self:ThrottleSync(1, syncName.strikes)
    self:ThrottleSync(3, syncName.strikesFade)
    self:ThrottleSync(1, syncName.bomb)
    self:ThrottleSync(1, syncName.bombFade)
end

function module:OnSetup()
    self.started = nil
end

function module:OnEngage()
    self:Bar(L["bar_circle"], timer.firstcircle, icon.circle, true, color.circle)
    self:DelayedBar(timer.firstcircle, L["active_circle"], timer.circle, icon.circle, true, color.circle)
    self:Bar(L["bar_nextbomb"], timer.firstbomb, icon.bomb, true, color.bomb)
    usepotcounter = 0
    if self.db.profile.usepoticon then
        self:ScheduleRepeatingEvent("bwUsepoticon", function() self:UsePotIcon() end, timer.usepot)
    end
    if self.db.profile.usepotsound then
        self:ScheduleEvent("FirstEvent", function()
            self:UsePotSound()
            self:ScheduleRepeatingEvent("RepeatingEvent", function() self:UsePotSound() end, timer.usepot)
        end, timer.usepot - timer.usepotsound_pre)
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

function module:Event(msg)
    if string.find(msg, L["trigger_strikesYou"]) then
        local _,_, stQty, _ = string.find(msg, L["trigger_strikesYou"])
        if UnitName("target") ~= nil and UnitName("targettarget") ~= nil then
            if UnitName("target") == "Anomalus" and UnitName("targettarget") == UnitName("Player") then
                local stPlayerAndQty = UnitName("Player") .. " " .. stQty
                self:Sync(syncName.strikes .. " " .. stPlayerAndQty)
            end
        end
    elseif string.find(msg, L["trigger_strikesOther"]) then
        local _,_, stPlayer, stQty,_ = string.find(msg, L["trigger_strikesOther"])
        local stPlayerAndQty = stPlayer .. " " .. stQty
        self:Sync(syncName.strikes .. " " .. stPlayerAndQty)
    elseif msg == L["trigger_strikesFade"] then
        self:Sync(syncName.strikesFade)
    
    elseif string.find(msg, L["trigger_bombYou"]) then
        self:Sync(syncName.bomb .. " " .. UnitName("Player"))
    elseif string.find(msg, L["trigger_bombOther"]) then
        local _,_, bombPlayer,_ = string.find(msg, L["trigger_bombOther"])
        self:Sync(syncName.bomb .. " " .. bombPlayer)
    elseif string.find(msg, L["trigger_bombFade"]) then
        local _,_, bombFadePlayer,_ = string.find(msg, L["trigger_bombFade"])
        if bombFadePlayer == "you" then bombFadePlayer = UnitName("Player") end
        self:Sync(syncName.bombFade .. " " .. bombFadePlayer)
        
    elseif msg == L["trigger_dampening"] and self.db.profile.dampening then
        self:Dampening()
    elseif msg == L["trigger_dampeningFade"] and self.db.profile.dampening then
        self:DampeningFade()
    
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.strikes and rest and self.db.profile.strikes then
        self:Strikes(rest)
    elseif sync == syncName.strikesFade and self.db.profile.strikes then
        self:StrikesFade()
    elseif sync == syncName.bomb and rest and self.db.profile.bomb then
        self:Bomb(rest)
    elseif sync == syncName.bombFade and rest and self.db.profile.bomb then
        self:BombFade(rest)
    end
end

function module:Strikes(rest)
    local stPlayer = strsub(rest,0,strfind(rest," ") - 1)
    local stQty = tonumber(strsub(rest,strfind(rest," "),strlen(rest)))
    local currentIncrease = stQty * 5
    if (IsRaidLeader() or IsRaidOfficer()) then
        -- it's actually useful to track other tanks stacks
        --if last_tank_strikes ~= stPlayer and last_tank_strikes ~= "" then 
        --   for i = 5, 245, 5 do
        --        self:RemoveBar(last_tank_strikes.." has "..i..L["msg_strikescount"])
        --   end
        --end 
        for i = 5, 245, 5 do
            self:RemoveBar(stPlayer.." has "..i..L["msg_strikescount"])
        end
        self:Bar(stPlayer.." has "..currentIncrease..L["msg_strikescount"], timer.strikes, icon.strikes, true, color.strikes)
        last_tank_strikes = stPlayer
        if stQty >= warn_strikes_stacks then
            self:Message(stPlayer.." has "..stQty..L["msg_manystrikes"], "Attention", false, nil, false)
        end
    end
end

function module:StrikesFade()
    self:Message(L["msg_strikesfaded"])
end

function module:Bomb(rest)
    if IsRaidLeader() then
        SendChatMessage(rest.." is the Bomb!","RAID_WARNING")
        --self:Message(rest..L["msg_bomb"], "Urgent") --, false, nil, false)
        self:Bar(rest..L["bar_bomb"], timer.bomb, icon.bomb, true, color.bomb)
    end
    if rest == UnitName("Player") then
        self:Bar(rest..L["bar_bomb"], timer.bomb, icon.bomb, true, color.bomb)
        SendChatMessage(UnitName("Player").." is the Bomb!","SAY")
        self:WarningSign(icon.bomb, timer.bomb)
        self:Sound("RunAway")
    end
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 8)
            end
        end
    end
end

function module:BombFade(rest)
    self:RemoveBar(rest..L["bar_bomb"])
    if (IsRaidLeader() or IsRaidOfficer()) then
        for i=1,GetNumRaidMembers() do
            if UnitName("raid"..i) == rest then
                SetRaidTarget("raid"..i, 0)
            end
        end
    end
end

function module:Dampening()
    self:Message(L["msg_dampening"], "Attention")
end

function module:DampeningFade()
    self:Message(L["msg_dampeningFade"], "Attention")
end

function module:UsePotIcon()
    if IsRaidLeader() then 
        SendChatMessage(L["msg_usepot"],"RAID_WARNING")
    end
    self:WarningSign(icon.usepot, timer.usepoticon)
end

function module:UsePotSound()
    if mod(usepotcounter, 3)  == 0 then
        PlaySoundFile(L["soundarcanepot0"])
    elseif mod(usepotcounter, 3)  == 1 then
        PlaySoundFile(L["soundarcanepot1"])
    elseif mod(usepotcounter, 3)  == 2 then
        PlaySoundFile(L["soundarcanepot3"])
    end
    usepotcounter = usepotcounter + 1
end