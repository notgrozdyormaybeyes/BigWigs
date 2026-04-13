local module, L = BigWigs:ModuleDeclaration("Peroth'arn", "Timbermaw Hold")

module.revision = 30020
module.enabletrigger = "Peroth'arn"
module.toggleoptions = {"flamefear", "minisatyr", "mcline", "thunderclap", "bosskill"}
module.zonename = "Timbermaw Hold"

module.defaultDB = {
    flamefear = true,
    minisatyr = true,
    mcline = true,
    thunderclap = true,
}

L:RegisterTranslations("enUS", function() return {
    cmd = "Perotharn",
    
    flamefear_cmd = "Flamefear",
    flamefear_name = "Flame Fear Alert",
    flamefear_desc = "Warn for Flame Fear",
    
    minisatyr_cmd = "MiniSatyr",
    minisatyr_name = "MiniSatyr Alert",
    minisatyr_desc = "Warn for phase 1 Satyr adds",
    
    mcline_cmd = "MCLine",
    mcline_name = "MCLine Alert",
    mcline_desc = "Warn for MCLine",
    
    thunderclap_cmd = "Thunderclap",
    thunderclap_name = "Thunderclap Alert",
    thunderclap_desc = "Warn for Thunderclap",
    
    flamefear = "Flames of Purgation",
    flamefear_say = "I MUST MOVE AWAY!",
    flamefear_warn = " has Purgation debuff! Stay AWAY!",
    flamefear_bar = " will fear",
    flamefear_trig = "(.+) is afflicted by Flames of Purgation", 
    flamefear_trigyou = "You are afflicted by Flames of Purgation", 
    flamefear_fade = "Flames of Purgation fades from ",
    
    pOne_add_name = "Foulheart Manipulator",
    pOne_mc_trig = "(.+) %(Foulheart Manipulator%) is afflicted by Alluring Power",
    pOne_mc_trigyou = "You are afflicted by Alluring Power",
    pOne_mc_say = " will soon be MC'd! ",
    pOne_mc_bar = " Mind Control",
    pOne_soon_bar = "Satyr adds",
    
    pTwo_trig = "Peroth'arn gains Nightmarish Absorption",
    pTwo_soon_rw = "Phase 2 soon, move to positions and wait for RL",
    pTwo_shield_break = "Nightmarish Absorption fades from Peroth'arn",
    pTwo_shield_break_rw = "Peroth'arn Shield BROKE! GO DISARM",
    
    mcline_cast_warn = "Foulheart Manipulator",
    mcline_hit_warn = "(Foulheart Manipulator) is afflicted by Alluring Power ",
    
    mcline_debuff_name = "Dirk of the Beast",
    mcline_inside_msg = "YOU ARE IN MC LINE, MOVE",
    mc_use_trinket = "USE YOUR PVP TRINKET",
    mc_freepowah = "DPS BOOST, GO HARD",
    
    thunderclap_bar = "Melee move out",
    
    shield_part_one = " Peroth'arn for 0 ",
    shield_part_two = " absorbed)",
    
    
    trigger_engage = "rip trigger engage :(",
    trigger_yell_pTwo = "Wretched pests! You shall join the ranks of the enlightened!",
    trigger_bossDead = "The dieing is dead",
} end)

local marksNames = {
    [8] = "Skull",
    [7] = "Cross",
    [6] = "Square",
    [5] = "Moon",
    [4] = "Triangle",
    [3] = "Diamond",
    [2] = "Circle",
    [1] = "Star",
    [0] = "One",
}
-- according to my logs
local perotharn_guid = "0xF13000ED0E27A356"

local raidMarks = {8, 7, 6, 5, 4, 3, 2, 1}
local usedMarks = {}   

local pOneFirstAdds = false

local pTwoWarned = false
local phaseTwoStarted = false
local phaseTwoMaxShield = 300000

local igotmcd = false

local spell_guid = {
    thunderclap_one = 36840,
    thunderclap_two = 34775,    -- kronn spell
    dirk_one = 36837,
    dirk_two = 36836,
    dirk_three = 36835,
    dirk_four = 36834,
    three_hundo_kay_shield = 36832,
    
}

local timer = {
    minisatyrmc = 3, -- no real timer since it's distance dependent
    pOne_add_first = 30,
    pOne_add_next = 50,
    flamefear = 8,
    thunderclap = 3,
}

local icon = {
    flamefear = "Spell_Fire_Immolation",
    in_mcline_cast = "Spell_Holy_InnerFire",
    in_mcline_hit = "Spell_Fire_SelfDestruct",
    iammc = "Spell_Shadow_ShadowWordDominate",
    iampower = "INV_Wand_06",
    lucidity = "inv_potion_141",
    thunderclap = "Spell_Nature_ThunderClap",
    disarm = "Ability_Warrior_Disarm",
    minisatyr = "Ability_WarStomp",
    shield = "Spell_Holy_PowerWordShield",
}

local color = {
    dirk = "Purple",
    minisatyr = "Black",
    flamefear = "Red",
    thunderclap = "Yellow",
    shield = "Red",
}

local syncName = {
    minisatyrmc = "PhaseOneMC"..module.revision,
    minisatyrmcfade = "PhaseOneMCFade"..module.revision,
    flamefear = "Flamefear"..module.revision,
    flamefearFade = "FlamefearFade"..module.revision,
}

module.proximityCheck = function(unit)
    return CheckInteractDistance(unit, 2)
end

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", "Event")
    
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "ShieldCount")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", "ShieldCount")
    
    self:RegisterEvent("UNIT_HEALTH")
    self.phaseTwoShield = phaseTwoMaxShield

    if SUPERWOW_VERSION then
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
	self.frameIcon = CreateFrame("Frame",nil,UIParent)
	self.frameIcon:SetFrameStrata("MEDIUM")
	self.frameIcon:SetWidth(150)
	self.frameIcon:SetHeight(150)
	self.frameIcon:SetAlpha(0.6)
	self.frameTexture = self.frameIcon:CreateTexture(nil,"BACKGROUND")
	self.frameTexture:SetTexture(nil)
	self.frameTexture:SetAllPoints(self.frameIcon)
	self.frameIcon:Hide()
	self.frameIcon2 = CreateFrame("Frame",nil,UIParent)
	self.frameIcon2:SetFrameStrata("MEDIUM")
	self.frameIcon2:SetWidth(150)
	self.frameIcon2:SetHeight(150)
	self.frameIcon2:SetAlpha(0.6)
	self.frameTexture2 = self.frameIcon2:CreateTexture(nil,"BACKGROUND")
	self.frameTexture2:SetTexture(nil)
	self.frameTexture2:SetAllPoints(self.frameIcon2)
	self.frameIcon2:Hide()
    
end

function module:OnSetup()
    self.started = nil
	self.frameIcon:Hide()
	self.frameIcon2:Hide()
end

function module:OnEngage()
    phaseTwoStarted = false
    pTwoWarned = false
    igotmcd = false
    self:Proximity()
    self.phaseTwoShield = phaseTwoMaxShield
    if self.db.profile.minisatyr then
        self:Minisatyr()
    end
end

function module:OnDisengage()
    self:CancelAllScheduledEvents()
	self:TriggerEvent("BigWigs_StopHPBar", self, "ShieldBar")
    if IsRaidLeader() then
        for i = 1, GetNumRaidMembers() do
            SetRaidTarget("raid"..i, 0)
        end
    end
    phaseTwoStarted = false
    pTwoWarned = false
    igotmcd = false
    self:RemoveProximity()
	self.frameIcon:Hide()
	self.frameIcon2:Hide()
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if casterGuid == perotharn_guid then
        if spellId == spell_guid.thunderclap_one then
            self:Thunderclap(castTime)
        end
    end
end

function module:Event(msg)
    if string.find(msg, L["flamefear_trigyou"]) and self.db.profile.flamefear then
        self:Sync(syncName.flamefear.." "..UnitName("player"))
    elseif string.find(msg, L["flamefear_trig"]) and self.db.profile.flamefear then
        local _, _, flamefearPlayer = string.find(msg, L["flamefear_trig"])
        self:Sync(syncName.flamefear.." "..flamefearPlayer)
    elseif string.find(msg, L["flamefear_fade"]) and self.db.profile.flamefear then
        local _, _, flamefearFadePlayer = string.find(msg, L["flamefear_fade"])
        if string.lower(flamefearFadePlayer) == "you" then
            flamefearFadePlayer = UnitName("player")
        end
        self:Sync(syncName.flamefearFade.." "..flamefearFadePlayer)
    elseif string.find(msg, L["pOne_mc_trigyou"]) and self.db.profile.minisatyr then
        self:Sync(syncName.minisatyrmc.." "..UnitName("player"))
    elseif string.find(msg, L["pOne_mc_trig"]) and self.db.profile.minisatyr then
        local _, _, mcPlayer = string.find(msg, L["pOne_mc_trig"])
        self:Sync(syncName.minisatyrmc.." "..mcPlayer)
    elseif string.find(msg, L["trigger_bossDead"]) then
        self:SendBossDeathSync()
    elseif not phaseTwoStarted and (string.find(msg, L["pTwo_trig"]) or string.find(msg, L["trigger_yell_pTwo"]) ) then
        phaseTwoStarted = true
        self:ScheduleRepeatingEvent("CheckDebuffs", self.CheckDebuffs, 0.01, self)
        self:TriggerEvent("BigWigs_StartHPBar", self, "ShieldBar", 100 , "Interface\\Icons\\" .. icon.shield, true, color.shield)
        self:TriggerEvent("BigWigs_SetHPBar", self, "ShieldBar", 1 )
    elseif phaseTwoStarted and string.find(msg, L["pTwo_shield_break"]) and self.phaseTwoShield <= 5000 then
        if IsRaidLeader() then
            SendChatMessage(L["pTwo_shield_break_rw"], "RAID_WARNING")
        end
    end
end

function module:UNIT_HEALTH(unit)
    if unit ~= "target" then return end
    if UnitName(unit) == "Peroth'arn" then
        local hp = UnitHealth(unit) / UnitHealthMax(unit) * 100
        if hp <= 55 and not pTwoWarned then
            SendChatMessage(L["pTwo_soon_rw"], "RAID_WARNING")
            pTwoWarned = true
        end
    end
end

function module:ShieldCount(msg)
    if not phaseTwoStarted then return end
    if string.find(msg, L["shield_part_one"]) and string.find(msg, L["shield_part_two"]) then
        local absorbed = string.match(msg, "%((%d+)%s+absorbed%)")
        self.phaseTwoShield = self.phaseTwoShield - tonumber(absorbed)
        local hpPct = math.ceil(self.phaseTwoShield / phaseTwoMaxShield * 100)
        self:TriggerEvent("BigWigs_SetHPBar", self, "ShieldBar", 100 - hpPct)
        if IsRaidLeader() and self.phaseTwoShield <= 1000 then
            SendChatMessage(L["pTwo_shield_break_rw"], "RAID_WARNING")
        end
    end
    
end

function module:BigWigs_RecvSync(sync, rest)
    if sync == syncName.flamefear and rest and self.db.profile.flamefear then
        self:Flamefear(rest)
    elseif sync == syncName.flamefearFade and rest and self.db.profile.flamefear then
        self:FlamefearFade(rest)
    elseif sync == syncName.minisatyrmc and rest and self.db.profile.minisatyr then
        self:MinisatyrMC(rest)
    end
end

function module:CheckDebuffs()
    for i = 1, 16 do
        local debufficon, applications, debuffType = UnitDebuff("player", i)
        if not debufficon then break end

        if debufficon == "Interface\\Icons\\"..icon.in_mcline_cast then
            self:Message(L["mcline_inside_msg"], "Urgent")
        elseif debufficon == "Interface\\Icons\\"..icon.in_mcline_hit then
            self:Message(L["mcline_inside_msg"], "Important")
        elseif debufficon == "Interface\\Icons\\"..icon.iammc then
            igotmcd = true
            self:Message(L["mc_use_trinket"], "Urgent")
            self.frameTexture:SetTexture("Interface\\Icons\\"..icon.lucidity) 
            self.frameTexture2:SetTexture(nil)
			self.frameIcon.texture = self.frameTexture
			self.frameTexture:SetTexCoord(0.0,1.0,0.0,1.0)
			self.frameIcon:SetPoint("CENTER",200,100)
			self.frameIcon:Show()

			self.frameIcon2.texture = self.frameTexture2
			self.frameTexture2:SetTexCoord(0.0,1.0,0.0,1.0)
			self.frameIcon2:SetPoint("CENTER",200,0)
			self.frameIcon2:Show()

			self:ScheduleEvent(function()
				self.frameIcon:Hide()
				self.frameIcon2:Hide()
			end, 3)
            
        elseif igotmcd and debufficon == "Interface\\Icons\\"..icon.iampower then
            self:Message(L["mc_freepowah"], "Important")
            igotmcd = false
        elseif debufficon == "Interface\\Icons\\".."Spell_Shadow_MindRot" and UnitName("player") == "Grozdy" then
            print("test successfull")
        end
    end
end

function module:MinisatyrMC(rest)
    self:Bar(rest..L["pOne_mc_bar"], timer.minisatyrmc, icon.iammc, true, color.minisatyr)
    if rest == UnitName("player") then
        SendChatMessage(rest..L["pOne_mc_say"], "SAY")
    end
end

function module:Flamefear(rest)
    self:Bar(rest..L["flamefear_bar"], timer.flamefear, icon.flamefear, true, color.flamefear)
    if IsRaidLeader() then
        SendChatMessage(rest..L["flamefear_warn"], "RAID_WARNING")
        self:MarkPlayer(rest)
    end
    if rest == UnitName("player") then
        SendChatMessage(L["flamefear_say"], "SAY")
        self:Message(L["flamefear_say"], "Urgent")
        self:WarningSign(icon.flamefear, timer.flamefear)
        self:Sound("RunAway")
    end
end

function module:FlamefearFade(rest)
    self:RemoveBar(rest..L["flamefear_bar"])
    if IsRaidLeader() or IsRaidOfficer() then
        self:ResetMarks()
    end
end

function module:Thunderclap(castTime)
    local casttime = tonumber(castTime) / 1000
    if not casttime or casttime <= timer.thunderclap then
        casttime = timer.thunderclap
    end
    self:Bar(L["thunderclap_bar"], casttime, icon.thunderclap, true, color.thunderclap)
    self:Sound("Beware")
end

function module:Minisatyr()
    local duration
    if pOneFirstAdds then 
        duration = timer.pOne_add_next
    else 
        duration = timer.pOne_add_first 
        pOneFirstAdds = true
    end
    self:Bar(L["pOne_soon_bar"], duration, icon.minisatyr, true, color.minisatyr)
end

function module:GetFreeRaidMark()
    for _, mark in ipairs(raidMarks) do
        if not usedMarks[mark] then
            local taken = false
            if not taken then
                usedMarks[mark] = true
                return mark
            end
        end
    end

    return nil
end

function module:MarkPlayer(playerName)
    local mark = self:GetFreeRaidMark()
    if not mark then return end
    for i = 1, 40 do
        local unit = "raid"..i
        if UnitExists(unit) and UnitName(unit) == playerName then
            SetRaidTarget(unit, mark)
            return
        end
    end
end

function module:ResetMarks()
    usedMarks = {}
    for i = 1, 40 do
        local unit = "raid"..i
        if UnitExists(unit) then
            SetRaidTarget(unit, 0)
        end
    end
end


-- tests
SLASH_PEROTEST1 = "/perotest"
SlashCmdList["PEROTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    if msg == "mcone" then
        self:Message(L["mcline_inside_msg"], "Urgent")
    elseif msg == "mctwo" then
        self:Message(L["mc_use_trinket"], "Urgent")
        self.frameTexture:SetTexture("Interface\\Icons\\"..icon.lucidity) 
        self.frameTexture2:SetTexture(nil)
        self.frameIcon.texture = self.frameTexture
        self.frameTexture:SetTexCoord(0.0,1.0,0.0,1.0)
        self.frameIcon:SetPoint("CENTER",200,100)
        self.frameIcon:Show()

        self.frameIcon2.texture = self.frameTexture2
        self.frameTexture2:SetTexCoord(0.0,1.0,0.0,1.0)
        self.frameIcon2:SetPoint("CENTER",200,0)
        self.frameIcon2:Show()

        self:ScheduleEvent(function()
            self.frameIcon:Hide()
            self.frameIcon2:Hide()
        end, 2)
    elseif msg == "flame" then
        self:Flamefear(UnitName("player"))
    elseif msg == "TC" then
        self:Thunderclap(3001)
    elseif msg == "mini" then
        self:Minisatyr()
    elseif msg == "testdebuff" then
        self:CheckDebuffs()
    else
        print("Commands: mcone, mctwo, flame, TC, mini, testdebuff ")
    end
end
