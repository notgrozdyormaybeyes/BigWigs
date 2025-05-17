
local module, L = BigWigs:ModuleDeclaration("Ley-Watcher Incantagos", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"surge", "beam", "blizzard", "sumseeker", "sumwhelps", "affinity", "curse", "autotarget", "bosskill"}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}
-- most useful to deactivate would be autotarget
module.defaultDB = {
    surge = true,
    beam = true,
    blizzard = true,
    sumseeker = true,
    sumwhelps = true,
    affinity = true,
    curse = true,
    autotarget = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Incantagos",
    
    surge_cmd = "SurgeofMana",
    surge_name = "Surge of Mana Alert",
    surge_desc = "Warn for Surge of Mana",
    
    beam_cmd = "GuidedLey-Beam",
    beam_name = "Guided-Ley Beam Alert",
    beam_desc = "Warn for Guided-Ley Beam",

    blizzard_cmd = "Blizzard",
    blizzard_name = "Blizzard Alert",
    blizzard_desc = "Warn for Blizzard",
    
    sumseeker_cmd = "SummonMana-LeySeeker",
    sumseeker_name = "Summon Mana-Ley Seeker Alert",
    sumseeker_desc = "Warn for Summon Mana-Ley Seeker",
    
    sumwhelps_cmd = "SummonManascaleWhelps",
    sumwhelps_name = "Summon Manascale Whelps Alert",
    sumwhelps_desc = "Warn for Summon Manascale Whelps",
    
    affinity_cmd = "Ley-LineDisturbance",
    affinity_name = "Ley-Line Disturbance Alert",
    affinity_desc = "Warn for Ley-Line Disturbance",

    curse_cmd = "CurseofManascale",
    curse_name = "Curse of Manascale Alert",
    curse_desc = "Warns for Curse of Manascale",
    
    autotarget_cmd = "autotarget",
    autotarget_name = "Auto-Target the affinity",
    autotarget_desc = "Targets the affinity automatically upon summon",
    
    msg_curse = "Incantagos is close to 40%! Prepare Restorative Potion for curse phase!",
    msg_curse_cast = "Curse being casted! Prepare Restorative Potion!",
    
    trigger_surge = "You are afflicted by Surge of Mana", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_surgefade = "Surge of Mana fades from you.", --CHAT_MSG_SPELL_AURA_GONE_SELF
    msg_surge = "Surge of Mana on You! Use Blink, Iceblock, Bubble, Shapeshift, Freedom, LAP!",
    
    trigger_beam = "gains Guided Ley-Beam", --CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
    trigger_inbeam = "You are afflicted by Guided Ley-Beam", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_inbeamfade = "Guided Ley-Beam fades from you.", --CHAT_MSG_SPELL_AURA_GONE_SELF
    bar_beam = "Guided-Ley Beam soon!",
    msg_beam = "Guided-Ley Beam on YOU! Move!",
    
    trigger_blizz = "You are afflicted by Blizzard", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_blizzfade = "Blizzard fades from you.", --CHAT_MSG_SPELL_AURA_GONE_SELF
    msg_blizz = "Blizzard on YOU! Move!",
    
    trigger_seeker = "Ley-Watcher Incantagos begins to cast Summon Manascale Ley-Seeker.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
    bar_seeker = "Next Seeker",
    msg_seeker = "Manascale Ley-Seeker! Boss takes 25% reduced damage!",
    
    trigger_whelps = "Ley-Watcher Incantagos begins to cast Summon Manascale Whelps.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
    bar_whelps = "Next Whelps",
    msg_whelps = "Many whelps! Handle it!",
    
    trigger_aff = "Ley-Watcher Incantagos begins to cast Ley-Line Disturbance.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
    bar_aff = "Next Affinity",
    trigger_affgainone = "You gain ", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_affgaintwo = " Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    trigger_red = "You gain Red Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    msg_redaff = "Red Affinity! Use Fire damage",
    trigger_blue = "You gain Blue Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    msg_blueaff = "Blue Affinity! Use Frost damage",
    trigger_mana = "You gain Mana Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    msg_manaaff = "Mana Affinity! Use Arcane damage",
    trigger_green = "You gain Green Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    msg_greenaff = "Green Affinity! Use Nature damage",
    trigger_black = "You gain Black Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    msg_blackaff = "Black Affinity! Use Shadow damage",
    trigger_crystal = "You gain Crystal Affinity", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
    msg_crystalaff = "Crystal Affinity! Use Physical damage",
    
    trigger_engage = "Do you think you can disturb our purpose here?",--CHAT_MSG_MONSTER_YELL
    trigger_bossDead = "Malygos... I have failed you.", --CHAT_MSG_MONSTER_YELL
} end )

local boss_guid = ""
local beam_id = 51182
local whelps_id = 51179
local seeker_id = 51178
local disturbance_id = 51185
local curse_id = 51186
local curse_warned = false
local lowHp = 0
local healthPct = 100


local timer = {
    beamcast = 3,
    firstsumseeker = 75,
    seekercast = 2,
    whelpscast = 2,
    firstaffinity = 78,
    affinitycd = 55,
    affinitykill = 15,
    affinitycast = 3,
}
local icon = {
    surge = "Spell_Shadow_SiphonMana",
    beam = "Spell_Arcane_StarFire",
    blizzard = "Spell_Frost_IceStorm",
    sumseeker = "INV_Misc_Head_Dragon_Blue",
    sumwhelps = "INV_Misc_Head_Dragon_Black",
    affinity = "Spell_Nature_AstralRecalGroup",
    aff_red = "Spell_Fire_FlameBolt",
    aff_blue = "Spell_Frost_FrostBolt02",
    aff_mana = "Spell_Arcane_StarFire",
    aff_green = "Spell_Nature_ProtectionformNature",
    aff_black = "Spell_Shadow_ShadowBolt",
    aff_crystal = "INV_Axe_11",
}
local color = {
    beam = "Blue",
    blizzard = "Blue",
    sumseeker = "Black",
    sumwhelps = "White",
    affinity = "Red",
    curse = "Purple",
}
local syncName = {
    bossguid = "BossGuid"..module.revision,
    whelps = "SummonWhelps"..module.revision,
    seeker = "SummonSeeker"..module.revision,
    disturbance = "LeyLineDisturbance"..module.revision,
    curse = "CurseOfManascale"..module.revision,
    lowHp = "Ley-WatcherIncantagos"..module.revision,
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL") --trigger_engage, bossDead
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event") --trigger_seeker, whelps, aff
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_inbeam, blizz, surge, aff color
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") --trigger_beam
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") --trigger_inbeamfade, blizzfade, surgefade
    self:RegisterEvent("UNIT_HEALTH") --lowHp
    
    if SUPERWOW_VERSION then -- check if SuperWoW is used. if not, pray that someone has it to sync with you :)
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(3, syncName.whelps)
    self:ThrottleSync(3, syncName.seeker)
    self:ThrottleSync(3, syncName.disturbance)
    self:ThrottleSync(3, syncName.curse)
    self:ThrottleSync(60, syncName.lowHp)
end

function module:OnSetup()
    self.started = nil
end

function module:OnEngage()
    if SUPERWOW_VERSION and UnitClass("Player") == "Hunter" then --sorry hunters :(
        TargetByName("Ley-Watcher Incantagos") --enUS hardcoded... should use L["bossname"]
        local _, boss_guid = UnitExists("target")
        self:Sync(syncName.bossguid.." "..boss_guid)
        TargetLastTarget()
    end
    if self.db.profile.sumseeker then
        self:Bar(L["bar_seeker"], timer.firstsumseeker, icon.sumseeker, true, color.sumseeker)
    end
    if self.db.profile.affinity then
        self:Bar(L["bar_aff"], timer.firstaffinity, icon.affinity, true, color.affinity)
    end
end

function module:OnDisengage()
end

function module:CHAT_MSG_MONSTER_YELL(msg)
    if msg == L["trigger_engage"] then
        module:SendEngageSync()
    end
end

function module:UNIT_HEALTH(msg)
    if UnitName(msg) == "Ley-Watcher Incantagos" then
        healthPct = UnitHealth(msg) * 100 / UnitHealthMax(msg)
        if healthPct <= 42
        and lowHp == 0 then
            self:Sync(syncName.lowHp)
        end
    end
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == boss_guid then
        if spellId == whelps_id and eventType == "START" then 
            self:Sync(syncName.whelps.." "..castTime)
        elseif spellId == seeker_id and eventType == "START" then 
            self:Sync(syncName.seeker.." "..castTime)
        elseif spellId == disturbance_id and eventType == "START" then 
            self:Sync(syncName.disturbance.." "..castTime)
        elseif spellId == curse_id and curse_warned == false and eventType == "START" then 
            self:Sync(syncName.curse)
        end
    end
end

function module:Event(msg)
    if string.find(msg, L["trigger_surge"]) and self.db.profile.surge then
        self:Surge()
    elseif string.find(msg, L["trigger_surgefade"]) and self.db.profile.surge then
        self:SurgeFade()
    elseif string.find(msg, L["trigger_inbeam"]) and self.db.profile.beam then
        self:Beam()
    elseif string.find(msg, L["trigger_inbeamfade"]) and self.db.profile.beam then
        self:BeamFade()
    elseif string.find(msg, L["trigger_blizz"]) and self.db.profile.blizzard then
        self:Blizzard()
    elseif string.find(msg, L["trigger_blizzfade"]) and self.db.profile.blizzard then
        self:BlizzardFade()
    elseif string.find(msg, L["trigger_affgainone"]) and string.find(msg, L["trigger_affgaintwo"]) and self.db.profile.affinity then
        self:FindAffinity(msg)
    end

end


function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.lowHp and self.db.profile.curse then
        self:LowHp()
    elseif sync == syncName.curse and self.db.profile.curse then
        self:Curse()
    elseif sync == syncName.seeker and self.db.profile.sumseeker then 
        self:Seeker(rest)
    elseif sync == syncName.whelps and self.db.profile.sumwhelps then 
        self:Whelps(rest)
    elseif sync == syncName.disturbance and self.db.profile.affinity then 
        self:Disturbance(rest)
    end
end

function module:LowHp()
    lowHp = 1
    self:Message(L["msg_curse"], "Important", true, "Alert")
end

function module:Curse()
    self:Message(L["msg_curse_cast"], "Important", true, "Alert")
    curse_warned = true
end

function module:Surge()
    self:Message(L["msg_surge"], "Urgent", true, "Alarm")
    self:WarningSign(icon.surge, 3)
    self:Sound("Beware")
end
    
function module:SurgeFade()
    self:RemoveWarningSign(icon.surge)
end

function module:Beam()
    self:Message(L["msg_beam"], "Urgent", true, "Alarm")
    self:WarningSign(icon.beam, 3)
    self:Sound("Beware")
end
    
function module:BeamFade()
    self:RemoveWarningSign(icon.beam)
end
    
function module:Blizzard()
    self:Message(L["msg_blizz"], "Urgent", true, "Alarm")
    self:WarningSign(icon.blizzard, 3)
    self:Sound("Beware")
end
    
function module:BlizzardFade()
    self:RemoveWarningSign(icon.blizzard)
end

function module:Seeker(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.seekercast then casttime = timer.seekercast end
    self:Bar(L["bar_seeker"], timer.casttime, icon.sumseeker, true, color.sumseeker)
    self:DelayedMessage(timer.casttime, L["msg_seeker"], "Urgent", true, "Alert")
end

function module:Whelps(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.whelpscast then casttime = timer.whelpscast end
    self:Bar(L["bar_whelps"], timer.casttime, icon.whelps, true, color.whelps)
    self:DelayedMessage(timer.casttime, L["msg_whelps"], "Attention", true, "Alert")
end

function module:Disturbance(rest)
    local casttime = tonumber(rest)/1000
    if casttime == nil or casttime <= timer.affinitycast then casttime = timer.affinitycast end
    self:Bar(L["bar_aff"], timer.casttime, icon.affinity, true, color.affinity)
end
        
function module:FindAffinity(msg)
    if string.find(msg, L["trigger_red"]) then
        self:Message(L["msg_redaff"], "Urgent", true, "Alert")
        newaff = "Red"
        newicon = icon.aff_red
        self:Affinity(newaff, newicon)
    elseif string.find(msg, L["trigger_blue"]) then
        self:Message(L["msg_blueaff"], "Urgent", true, "Alert")
        newaff = "Blue"
        newicon = icon.aff_blue
        self:Affinity(newaff, newicon)
    elseif string.find(msg, L["trigger_mana"]) then
        self:Message(L["msg_manaaff"], "Urgent", true, "Alert")
        newaff = "Mana"
        newicon = icon.aff_mana
        self:Affinity(newaff, newicon)
    elseif string.find(msg, L["trigger_green"]) then
        self:Message(L["msg_greenaff"], "Urgent", true, "Alert")
        newaff = "Green"
        newicon = icon.aff_green
        self:Affinity(newaff, newicon)
    elseif string.find(msg, L["trigger_black"]) then
        self:Message(L["msg_blackaff"], "Urgent", true, "Alert")
        newaff = "Black"
        newicon = icon.aff_black
        self:Affinity(newaff, newicon)
    elseif string.find(msg, L["trigger_crystal"]) then
        self:Message(L["msg_crystalaff"], "Urgent", true, "Alert")
        newaff = "Crystal"
        newicon = icon.aff_crystal
        self:Affinity(newaff, newicon)
    end
end

function module:Affinity(affinity, afficon)
    self:Bar(affinity.." Affinity".. " >Click Me<", timer.affinitykill, afficon, true, color.affinity)
    self:SetCandyBarOnClick("BigWigsBar "..affinity.." Affinity".. " >Click Me<", function(name, button, extra) TargetByName(extra, true) end, affinity.." Affinity")
    self:Sound("Info")
    self:TargetAffinity(affinity)
    if (IsRaidLeader() or IsRaidOfficer()) then
        SendChatMessage(affinity.." Affinity!","RAID_WARNING")
        SetRaidTarget(affinity.." Affinity", 8)
    end
end

function module:TargetAffinity(affinity)
    if self.db.profile.autotarget then
        if affinity == "Red" and (UnitClass("Player") == "Mage" or UnitClass("Player") == "Warlock" or UnitClass("Player") == "Shaman") then
            TargetByName("Red Affinity",true)
        elseif affinity == "Blue" and (UnitClass("Player") == "Mage" or UnitClass("Player") == "Shaman") then
            TargetByName("Blue Affinity",true)
        elseif affinity == "Mana" and (UnitClass("Player") == "Mage" or UnitClass("Player") == "Druid" or UnitClass("Player") == "Hunter") then
            TargetByName("Mana Affinity",true)
        elseif affinity == "Green" and (UnitClass("Player") == "Shaman" or UnitClass("Player") == "Druid" or UnitClass("Player") == "Hunter") then
            TargetByName("Green Affinity",true)
        elseif affinity == "Black" and (UnitClass("Player") == "Warlock" or UnitClass("Player") == "Priest") then
            TargetByName("Black Affinity",true)
        elseif affinity == "Crystal" and (UnitClass("Player") == "Rogue" or UnitClass("Player") == "Paladin" or UnitClass("Player") == "Hunter" or UnitClass("Player") == "Warrior") then
            TargetByName("Crystal Affinity",true)
        end
    end
end
